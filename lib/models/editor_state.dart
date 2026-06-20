import 'package:flutter/material.dart';

/// 编辑器全局状态管理器（使用 Provider）
class EditorState extends ChangeNotifier {
  String _filePath = '';
  String _text = '';
  String _savedText = ''; // 最后保存的版本，用于判断是否需要保存
  bool _isDark = true;
  bool _showLineNumbers = true;
  double _fontSize = 14.0;
  bool _isModified = false;

  // 撤销/重做栈
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  static const int _maxHistory = 100;

  String get filePath => _filePath;
  String get text => _text;
  bool get isDark => _isDark;
  bool get showLineNumbers => _showLineNumbers;
  double get fontSize => _fontSize;
  bool get isModified => _isModified;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// 获取文件名（用于标题栏）
  String get fileName {
    if (_filePath.isEmpty) return '未命名';
    return _filePath.split('/').last;
  }

  /// 根据文件扩展名检测语言类型
  String get language {
    final name = fileName.toLowerCase();
    if (name.endsWith('.py')) return 'python';
    if (name.endsWith('.js') || name.endsWith('.jsx') ||
        name.endsWith('.ts') || name.endsWith('.tsx') ||
        name.endsWith('.mjs')) return 'javascript';
    if (name.endsWith('.java')) return 'java';
    if (name.endsWith('.c') || name.endsWith('.cpp') ||
        name.endsWith('.h') || name.endsWith('.hpp') ||
        name.endsWith('.cc') || name.endsWith('.cxx') ||
        name.endsWith('.cs')) return 'java';
    if (name.endsWith('.dart')) return 'dart';
    if (name.endsWith('.go')) return 'java';
    if (name.endsWith('.rs')) return 'rust';
    if (name.endsWith('.rb')) return 'ruby';
    if (name.endsWith('.kt') || name.endsWith('.kts')) return 'kotlin';
    if (name.endsWith('.swift')) return 'swift';
    if (name.endsWith('.html') || name.endsWith('.xml') ||
        name.endsWith('.css') || name.endsWith('.json') ||
        name.endsWith('.yaml') || name.endsWith('.yml') ||
        name.endsWith('.md')) return 'javascript';
    // 内容检测作为后备
    return _detectLanguageFromContent(_text);
  }

  /// 从文件内容检测语言
  String _detectLanguageFromContent(String code) {
    if (code.isEmpty) return 'python';
    if (RegExp(r'^\s*(def\s|class\s+\w+\s*[:\(]|import\s+\w+|from\s+\w+\s+import)',
            multiLine: true)
        .hasMatch(code)) {
      return 'python';
    }
    if (RegExp(r'(function\s+\w+\s*\(|=>|console\.|let\s+|const\s+|var\s+)',
            multiLine: true)
        .hasMatch(code)) {
      return 'javascript';
    }
    if (RegExp(r'public\s+class\s+|void\s+main\s*\(|System\.out\.',
            multiLine: true)
        .hasMatch(code)) {
      return 'java';
    }
    return 'python';
  }

  /// 设置文件路径
  void setFilePath(String path) {
    _filePath = path;
    notifyListeners();
  }

  /// 设置文本（外部输入，如从文件加载）
  void setText(String newText) {
    _text = newText;
    _savedText = newText;
    _undoStack.clear();
    _redoStack.clear();
    _isModified = false;
    notifyListeners();
  }

  /// 插入文本（撤销快照版）
  void insertText(String oldText, String newText) {
    if (newText == oldText) return;
    _pushUndo();
    _text = newText;
    _redoStack.clear();
    _checkModified();
    notifyListeners();
  }

  /// 撤销
  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_text);
    _text = _undoStack.removeLast();
    _checkModified();
    notifyListeners();
  }

  /// 重做
  void redo() {
    if (_redoStack.isEmpty) return;
    _pushUndo();
    _text = _redoStack.removeLast();
    _checkModified();
    notifyListeners();
  }

  /// 切换主题
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  /// 切换行号显示
  void toggleLineNumbers() {
    _showLineNumbers = !_showLineNumbers;
    notifyListeners();
  }

  /// 设置字体大小
  void setFontSize(double size) {
    _fontSize = size.clamp(10.0, 24.0);
    notifyListeners();
  }

  /// 增大字体
  void increaseFontSize() {
    setFontSize(_fontSize + 1.0);
  }

  /// 减小字体
  void decreaseFontSize() {
    setFontSize(_fontSize - 1.0);
  }

  /// 标记为已保存
  void markSaved() {
    _savedText = _text;
    _isModified = false;
    notifyListeners();
  }

  void _pushUndo() {
    _undoStack.add(_text);
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
  }

  void _checkModified() {
    _isModified = _text != _savedText;
  }

  // ===== 兼容调用方命名 =====
  String? get openedFilePath => _filePath.isEmpty ? null : _filePath;
  set openedFilePath(String? path) {
    _filePath = path ?? '';
    notifyListeners();
  }
  String get currentLanguage => language;
  int get lineCount {
    if (_text.isEmpty) return 1;
    return '\n'.allMatches(_text).length + 1;
  }
  void setLanguage(String lang) {
    // 语言由文件扩展名自动检测，此方法用于手动覆盖
    notifyListeners();
  }
  void markModified() {
    _isModified = true;
    notifyListeners();
  }
  void clearUndoHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }


}
