import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'models/editor_state.dart';
import 'models/file_io.dart';
import 'widgets/code_editor.dart';
import 'widgets/bottom_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CodeEditorApp());
}

class CodeEditorApp extends StatefulWidget {
  const CodeEditorApp({super.key});

  @override
  State<CodeEditorApp> createState() => _CodeEditorAppState();
}

class _CodeEditorAppState extends State<CodeEditorApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '代码编辑器',
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
        ),
        home: EditorScreen(
          isDarkMode: _isDarkMode,
          onToggleTheme: _toggleTheme,
        ),
      ),
    );
  }
}

class EditorScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const EditorScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  Future<void> _openFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null && context.mounted) {
          final state = context.read<EditorState>();
          await FileIO.loadFile(filePath, state);

          // 根据文件后缀自动检测语言
          final lang = FileIO.detectLanguageFromPath(filePath);
          state.setLanguage(lang);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已打开: ${filePath.split('/').last}'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveFile(BuildContext context) async {
    final state = context.read<EditorState>();

    // 如果已有打开文件路径，直接保存
    if (state.openedFilePath != null) {
      final success = await FileIO.saveFile(
        state.openedFilePath,
        state.text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '已保存' : '保存失败'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
      return;
    }

    // 否则弹出保存文件选择器
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存文件',
        fileName: 'untitled.txt',
      );

      if (result != null && context.mounted) {
        final success = await FileIO.saveFile(result, state.text);
        if (success) {
          state.openedFilePath = result;
          final lang = FileIO.detectLanguageFromPath(result);
          state.setLanguage(lang);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '已保存: ${result.split('/').last}' : '保存失败'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              backgroundColor: success ? null : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _undo(BuildContext context) {
    final state = context.read<EditorState>();
    if (state.canUndo) {
      state.undo();
    }
  }

  void _redo(BuildContext context) {
    final state = context.read<EditorState>();
    if (state.canRedo) {
      state.redo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<EditorState>(
          builder: (_, state, __) {
            final fileName = state.openedFilePath != null
                ? state.openedFilePath!.split('/').last
                : '未命名';
            final modified = state.isModified ? ' •' : '';
            return Text('$fileName$modified');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: '切换主题',
            onPressed: () {
              context.read<EditorState>().toggleTheme();
              onToggleTheme();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('清空编辑器'),
              ),
              const PopupMenuItem(
                value: 'dev',
                child: Text('开发者信息'),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                context.read<EditorState>().setText('');
              } else if (value == 'dev') {
                showAboutDialog(
                  context: context,
                  applicationName: '代码编辑器',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Flutter 文本编辑器',
                );
              }
            },
          ),
        ],
      ),
      body: CodeEditor(
        onUndo: () => _undo(context),
        onRedo: () => _redo(context),
        onOpenFile: () => _openFile(context),
        onSaveFile: () => _saveFile(context),
      ),
      bottomNavigationBar: BottomBar(
        onOpenFile: () => _openFile(context),
        onSaveFile: () => _saveFile(context),
        onUndo: () => _undo(context),
        onRedo: () => _redo(context),
      ),
    );
  }
}
