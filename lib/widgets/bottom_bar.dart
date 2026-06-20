import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';

class BottomBar extends StatelessWidget {
  final VoidCallback? onOpenFile;
  final VoidCallback? onSaveFile;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const BottomBar({
    super.key,
    this.onOpenFile,
    this.onSaveFile,
    this.onUndo,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF0F0F0),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具栏第一行
          Row(
            children: [
              // 打开文件
              _BarButton(
                icon: Icons.folder_open,
                label: '打开',
                onTap: onOpenFile,
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              // 保存文件
              _BarButton(
                icon: Icons.save,
                label: '保存',
                onTap: onSaveFile,
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              // 撤销
              _BarButton(
                icon: Icons.undo,
                label: '撤销',
                onTap: state.canUndo ? onUndo : null,
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              // 重做
              _BarButton(
                icon: Icons.redo,
                label: '重做',
                onTap: state.canRedo ? onRedo : null,
                isDark: isDark,
              ),
              const Spacer(),
              // 语言选择
              _LanguageChip(
                language: state.currentLanguage,
                isDark: isDark,
                onChanged: (lang) => state.setLanguage(lang),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 工具栏第二行：字体、主题、状态
          Row(
            children: [
              // 字体缩小
              _SmallButton(
                icon: Icons.text_decrease,
                onTap: () => state.decreaseFontSize(),
                isDark: isDark,
              ),
              const SizedBox(width: 2),
              // 字体显示
              Text(
                '${state.fontSize.toInt()}px',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(width: 2),
              // 字体放大
              _SmallButton(
                icon: Icons.text_increase,
                onTap: () => state.increaseFontSize(),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // 主题切换
              _SmallButton(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                onTap: () => state.toggleTheme(),
                isDark: isDark,
              ),
              const Spacer(),
              // 文件状态信息
              Text(
                state.openedFilePath != null
                    ? state.openedFilePath!.split('/').last
                    : '未命名文件',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.lineCount}行',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 底部工具栏按钮
class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  const _BarButton({
    required this.icon,
    required this.label,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: enabled
                  ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.06))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled
                      ? (isDark ? Colors.white70 : Colors.black87)
                      : (isDark ? Colors.white24 : Colors.black26),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 语言选择标签
class _LanguageChip extends StatelessWidget {
  final String language;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _LanguageChip({
    required this.language,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final langs = <String, String>{
      'python': 'Python',
      'javascript': 'JavaScript',
      'java': 'Java',
      'dart': 'Dart',
      'rust': 'Rust',
      'kotlin': 'Kotlin',
      'swift': 'Swift',
      'go': 'Go',
      'ruby': 'Ruby',
      'html': 'HTML',
      'css': 'CSS',
      'json': 'JSON',
      'plaintext': '纯文本',
    };

    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, -300),
      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => langs.entries
          .map(
            (e) => PopupMenuItem<String>(
              value: e.key,
              child: Row(
                children: [
                  if (e.key == language)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(e.value),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 16,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              langs[language] ?? language,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_up,
              size: 16,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}

/// 小型图标按钮
class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _SmallButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }
}
