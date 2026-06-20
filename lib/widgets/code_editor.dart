import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/editor_state.dart';
import '../models/syntax_highlighter.dart';
import '../models/code_completion.dart';

class CodeEditor extends StatefulWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onOpenFile;
  final VoidCallback? onSaveFile;

  const CodeEditor({
    super.key,
    this.onUndo,
    this.onRedo,
    this.onOpenFile,
    this.onSaveFile,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _textController;

  // 补全弹窗状态
  bool _showCompletion = false;
  List<CompletionItem> _completions = [];
  int _selectedCompletionIndex = 0;
  int _completionTriggerOffset = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<EditorState>();
    _textController = TextEditingController(text: state.text);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateCompletions(String source, int cursorPos) {
    final state = context.read<EditorState>();
    final language = state.currentLanguage;
    final completions = CodeCompletionEngine.getCompletions(
      source,
      cursorPos,
      language,
    );

    setState(() {
      _completions = completions;
      _selectedCompletionIndex = 0;
      _showCompletion = completions.isNotEmpty;
    });
  }

  void _applyCompletion(CompletionItem item) {
    if (!_showCompletion) return;

    final cursorPos = _textController.selection.baseOffset;
    final text = _textController.text;

    // 找出插入起点（光标前最近的单词边界或点操作符后）
    int start = cursorPos;
    while (start > 0) {
      final ch = text[start - 1];
      if (ch == '.' || ch == '(' || ch == ' ' || ch == '\n' || ch == '\t') {
        break;
      }
      start--;
    }

    // 替换文本并移动光标
    _textController.value = TextEditingValue(
      text: text.substring(0, start) + item.insertText + text.substring(cursorPos),
      selection: TextSelection.collapsed(
        offset: start + item.insertText.length,
      ),
    );

    setState(() {
      _showCompletion = false;
    });
    context.read<EditorState>().markModified();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 如果编辑器内容与状态不同步，更新 textController
    if (_textController.text != state.text) {
      final currentOffset = _textController.selection.baseOffset;
      _textController.text = state.text;
      // 尽量保留光标位置
      if (currentOffset <= state.text.length) {
        _textController.selection = TextSelection.collapsed(offset: currentOffset);
      }
    }

    return Stack(
      children: [
        // 主编辑区域
        Column(
          children: [
            Expanded(
              child: Container(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFFFFFFF),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 行号列
                    _LineNumbers(
                      lineCount: state.lineCount,
                      fontSize: state.fontSize,
                      scrollController: _scrollController,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    // 编辑区
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: state.fontSize,
                                height: 1.5,
                              ),
                              children: _buildHighlightedText(
                                state.text,
                                state.currentLanguage,
                                isDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // 透明 TextField 用于接收输入
        Positioned.fill(
          child: Opacity(
            opacity: 0.0,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                fontSize: state.fontSize,
                fontFamily: 'monospace',
              ),
              onChanged: (text) {
                context.read<EditorState>().setText(text);
                final cursorPos = _textController.selection.baseOffset;
                _updateCompletions(text, cursorPos);
              },
            ),
          ),
        ),
        // 补全弹窗（位于底部）
        if (_showCompletion)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CompletionWidget(
              completions: _completions,
              selectedIndex: _selectedCompletionIndex,
              isDark: isDark,
              onSelect: (item) => _applyCompletion(item),
              onDismiss: () => setState(() => _showCompletion = false),
            ),
          ),
      ],
    );
  }

  List<TextSpan> _buildHighlightedText(
    String code,
    String language,
    bool isDark,
  ) {
    final spans = <TextSpan>[];
    final lines = code.split('\n');

    final engine = SyntaxHighlighterEngine();
    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      final tokens = engine.tokenize(lines[i], language);
      for (final token in tokens) {
        spans.add(TextSpan(
          text: token.text,
          style: TextStyle(
            color: engine.tokenColor(token, isDark),
          ),
        ));
      }
    }
    return spans;
  }
}

/// 行号组件
class _LineNumbers extends StatelessWidget {
  final int lineCount;
  final double fontSize;
  final ScrollController scrollController;
  final bool isDark;

  const _LineNumbers({
    required this.lineCount,
    required this.fontSize,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lines = List.generate(lineCount, (i) => '${i + 1}');

    return Container(
      width: 40 + fontSize,
      padding: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: SelectableText(
          lines.join('\n'),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            height: 1.5,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

/// 补全弹窗组件
class _CompletionWidget extends StatelessWidget {
  final List<CompletionItem> completions;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<CompletionItem> onSelect;
  final VoidCallback onDismiss;

  const _CompletionWidget({
    required this.completions,
    required this.selectedIndex,
    required this.isDark,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (_) => onDismiss(),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252526) : const Color(0xFFF5F5F5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: completions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = completions[index];
            final isSelected = index == selectedIndex;
            return InkWell(
              onTap: () => onSelect(item),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: isSelected
                    ? (isDark ? Colors.white12 : Colors.black12)
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (item.detail.isNotEmpty)
                      Text(
                        item.detail,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
