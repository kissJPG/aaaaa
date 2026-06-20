import 'dart:io';
import 'package:flutter/foundation.dart';
import 'editor_state.dart';

/// 文件读写操作封装
class FileIO {
  /// 从本地路径加载文件内容到编辑器状态
  static Future<void> loadFile(String? filePath, EditorState state) async {
    if (filePath == null || filePath.isEmpty) return;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File not found: $filePath');
        return;
      }
      final content = await file.readAsString();
      state.openedFilePath = filePath;
      state.setText(content);
      state.clearUndoHistory();
      debugPrint('Loaded file: $filePath (${content.length} chars)');
    } catch (e) {
      debugPrint('Error loading file: $e');
    }
  }

  /// 将当前编辑器内容保存到指定路径
  static Future<bool> saveFile(String? filePath, String content) async {
    if (filePath == null || filePath.isEmpty) return false;

    try {
      final file = File(filePath);
      await file.writeAsString(content);
      debugPrint('Saved file: $filePath (${content.length} chars)');
      return true;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return false;
    }
  }

  /// 从文件路径推导语言标识
  static String detectLanguageFromPath(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.py')) return 'python';
    if (ext.endsWith('.js') || ext.endsWith('.jsx')) return 'javascript';
    if (ext.endsWith('.ts') || ext.endsWith('.tsx')) return 'typescript';
    if (ext.endsWith('.java')) return 'java';
    if (ext.endsWith('.kt') || ext.endsWith('.kts')) return 'kotlin';
    if (ext.endsWith('.swift')) return 'swift';
    if (ext.endsWith('.dart')) return 'dart';
    if (ext.endsWith('.go')) return 'go';
    if (ext.endsWith('.rs')) return 'rust';
    if (ext.endsWith('.rb')) return 'ruby';
    if (ext.endsWith('.c') || ext.endsWith('.h')) return 'c';
    if (ext.endsWith('.cpp') || ext.endsWith('.hpp') || ext.endsWith('.cc')) return 'cpp';
    if (ext.endsWith('.html') || ext.endsWith('.htm')) return 'html';
    if (ext.endsWith('.css')) return 'css';
    if (ext.endsWith('.json')) return 'json';
    if (ext.endsWith('.xml') || ext.endsWith('.svg')) return 'xml';
    if (ext.endsWith('.yaml') || ext.endsWith('.yml')) return 'yaml';
    if (ext.endsWith('.md') || ext.endsWith('.markdown')) return 'markdown';
    return 'plaintext';
  }
}
