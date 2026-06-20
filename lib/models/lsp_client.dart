import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// LSP 诊断信息
class LspDiagnostic {
  final int line;       // 0-based
  final int column;     // 0-based
  final String message;
  final int severity;   // 1=Error, 2=Warning, 3=Info, 4=Hint
  LspDiagnostic(this.line, this.column, this.message, this.severity);
}

/// LSP 补全项（含详细信息和文档）
class LspCompletionItem {
  final String label;
  final String detail;
  final String insertText;
  final String documentation;
  LspCompletionItem(this.label, this.detail, this.insertText, this.documentation);
}

/// LSP JSON‑RPC 客户端 — 与外部语言服务器通过 stdin/stdout 通信
class LspClient {
  Process? _process;
  int _idCounter = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  StreamSubscription<String>? _stdoutSub;
  bool _initialized = false;
  String _language = '';
  final List<LspDiagnostic> _diagnostics = [];

  bool get isRunning => _process != null && _initialized;
  String get language => _language;
  List<LspDiagnostic> get diagnostics => _diagnostics;

  /// 启动 LSP 服务器进程
  Future<bool> start(String command, List<String> args, String language, {String? workingDir}) async {
    try {
      _process = await Process.start(command, args,
          workingDirectory: workingDir ?? '/sdcard');
      _language = language;
      _initialized = false;
      _idCounter = 0;
      _pending.clear();
      _diagnostics.clear();

      // 监听 stdout
      _stdoutSub?.cancel();
      final buffer = StringBuffer();
      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _handleLine(line, buffer);
      });

      _process!.stderr.transform(utf8.decoder).listen((err) {
        // 静默吞下 stderr，避免卡死
      });

      // 发送 initialize 请求
      final initResult = await _sendRequest('initialize', {
        'processId': pid,
        'rootUri': workingDir != null ? 'file://$workingDir' : null,
        'capabilities': {
          'textDocument': {
            'completion': {'completionItem': {'snippetSupport': false}},
            'diagnostic': {'dynamicRegistration': true},
          }
        },
      });
      if (initResult == null) return false;

      // 发送 initialized 通知
      _sendNotification('initialized', {});
      _initialized = true;
      return true;
    } catch (e) {
      _cleanup();
      return false;
    }
  }

  /// 打开文档通知
  void openDocument(String uri, String text, String language) {
    _sendNotification('textDocument/didOpen', {
      'textDocument': {
        'uri': uri,
        'languageId': language,
        'version': 1,
        'text': text,
      },
    });
  }

  /// 文档变更通知
  void changeDocument(String uri, String text, int version) {
    _sendNotification('textDocument/didChange', {
      'textDocument': {
        'uri': uri,
        'version': version,
      },
      'contentChanges': [
        {'text': text},
      ],
    });
  }

  /// 请求补全
  Future<List<LspCompletionItem>?> requestCompletion(
      String uri, int line, int character) async {
    final result = await _sendRequest('textDocument/completion', {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': character},
      'context': {'triggerKind': 1}, // Invoked
    });
    if (result == null || result['items'] == null) return null;

    final List items = result['items'] is List ? result['items'] : [];
    return items.map((item) {
      final m = item as Map<String, dynamic>;
      return LspCompletionItem(
        m['label']?.toString() ?? '',
        m['detail']?.toString() ?? '',
        m['insertText']?.toString() ?? m['textEdit']?['newText']?.toString() ?? m['label']?.toString() ?? '',
        m['documentation']?.toString() ?? '',
      );
    }).toList();
  }

  /// 停止服务器
  void stop() {
    if (_process != null) {
      _sendNotification('shutdown', {});
      _process!.kill();
    }
    _cleanup();
  }

  void _cleanup() {
    _stdoutSub?.cancel();
    _process = null;
    _initialized = false;
    _pending.clear();
  }

  void _handleLine(String line, StringBuffer buffer) {
    // LSP 使用 Content-Length 头部
    if (line.startsWith('Content-Length:')) {
      final length = int.tryParse(line.substring(15).trim()) ?? 0;
      // 跳过下一个空行后开始读 body
      buffer.clear();
    } else if (line.isEmpty && buffer.isEmpty) {
      // 空行，准备接收 body
    } else {
      if (buffer.isEmpty) {
        // 这是 body 行
        try {
          final msg = jsonDecode(line) as Map<String, dynamic>;
          _handleMessage(msg);
        } catch (_) {}
      }
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    // 响应
    if (msg.containsKey('id') && msg['id'] != null) {
      final id = msg['id'] as int;
      final completer = _pending.remove(id);
      if (completer != null) {
        if (msg['error'] != null) {
          completer.complete(null);
        } else {
          completer.complete(msg['result'] as Map<String, dynamic>? ?? {});
        }
      }
      return;
    }

    // 诊断通知
    if (msg['method'] == 'textDocument/publishDiagnostics') {
      final params = msg['params'] as Map<String, dynamic>?;
      if (params != null) {
        _diagnostics.clear();
        final diags = params['diagnostics'] as List?;
        if (diags != null) {
          for (final d in diags) {
            final dm = d as Map<String, dynamic>;
            final range = dm['range'] as Map<String, dynamic>?;
            _diagnostics.add(LspDiagnostic(
              range?['start']?['line'] ?? 0,
              range?['start']?['character'] ?? 0,
              dm['message']?.toString() ?? '',
              dm['severity'] ?? 1,
            ));
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _sendRequest(
      String method, Map<String, dynamic> params) async {
    if (_process == null) return const <String, dynamic>{};
    final id = ++_idCounter;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    final header = 'Content-Length: ${utf8.encode(body).length}\r\n\r\n';
    _process!.stdin.write(header + body);
    await _process!.stdin.flush();

    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pending.remove(id);
        return const <String, dynamic>{};
      },
    );
  }

  void _sendNotification(String method, Map<String, dynamic> params) {
    if (_process == null) return;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
    final header = 'Content-Length: ${utf8.encode(body).length}\r\n\r\n';
    _process!.stdin.write(header + body);
    _process!.stdin.flush();
  }
}
