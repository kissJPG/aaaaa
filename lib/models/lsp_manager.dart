import 'dart:io';
import 'lsp_client.dart';

/// LSP 服务器安装状态
enum LspServerStatus { notInstalled, downloading, installed, running, error }

/// 单个 LSP 服务器的描述
class LspServerInfo {
  final String language;
  final String displayName;
  final String command;       // 可执行命令
  final List<String> args;    // 启动参数
  final String downloadUrl;   // 下载地址（如有）
  final String description;
  LspServerStatus status;
  String? errorMessage;

  LspServerInfo({
    required this.language,
    required this.displayName,
    required this.command,
    required this.args,
    this.downloadUrl = '',
    this.description = '',
    this.status = LspServerStatus.notInstalled,
    this.errorMessage,
  });
}

/// LSP 服务器管理器 —— 发现/安装/启动/停止
class LspManager {
  static final LspManager _instance = LspManager._();
  factory LspManager() => _instance;
  LspManager._();

  final LspClient _client = LspClient();
  LspClient get client => _client;

  /// 已支持的 LSP 服务器列表
  static final List<LspServerInfo> supportedServers = [
    LspServerInfo(
      language: 'python',
      displayName: 'Pyright (Python)',
      command: 'pyright-langserver',
      args: ['--stdio'],
      downloadUrl: 'https://pypi.org/project/pyright/',
      description: '微软 Pyright 语言服务器，快速、精准的 Python 类型检查与补全',
    ),
    LspServerInfo(
      language: 'python',
      displayName: 'PyLSP (Python)',
      command: 'pylsp',
      args: [],
      downloadUrl: 'https://pypi.org/project/python-lsp-server/',
      description: 'Python Language Server Protocol 实现',
    ),
    LspServerInfo(
      language: 'javascript',
      displayName: 'TypeScript-LS',
      command: 'typescript-language-server',
      args: ['--stdio'],
      downloadUrl: 'https://www.npmjs.com/package/typescript-language-server',
      description: 'TypeScript/JavaScript 语言服务器',
    ),
    LspServerInfo(
      language: 'dart',
      displayName: 'Dart Analyzer',
      command: 'dart',
      args: ['language-server'],
      downloadUrl: 'https://dart.dev/tools/dart-analyze',
      description: 'Dart/Flutter 官方分析服务器（需 Dart SDK）',
    ),
    LspServerInfo(
      language: 'java',
      displayName: 'Eclipse JDT.LS',
      command: 'jdtls',
      args: [],
      downloadUrl: 'https://download.eclipse.org/jdtls/',
      description: 'Eclipse JDT 语言服务器（需 Java 运行时）',
    ),
    LspServerInfo(
      language: 'rust',
      displayName: 'Rust Analyzer',
      command: 'rust-analyzer',
      args: [],
      downloadUrl: 'https://rust-analyzer.github.io/',
      description: 'Rust 官方语言分析服务器',
    ),
    LspServerInfo(
      language: 'go',
      displayName: 'Gopls (Go)',
      command: 'gopls',
      args: ['serve', '-listen=stdio'],
      downloadUrl: 'https://pkg.go.dev/golang.org/x/tools/gopls',
      description: 'Go 官方语言服务器',
    ),
  ];

  /// 扫描已安装的服务器
  Future<void> scanInstalled() async {
    for (final server in supportedServers) {
      try {
        final result = await Process.run('which', [server.command]);
        if (result.exitCode == 0) {
          server.status = LspServerStatus.installed;
        }
      } catch (_) {
        server.status = LspServerStatus.notInstalled;
      }
    }
  }

  /// 获取指定语言可用的服务器
  List<LspServerInfo> getServersForLanguage(String language) {
    return supportedServers
        .where((s) => s.language == language)
        .toList();
  }

  /// 启动 LSP 服务器
  Future<bool> startServer(LspServerInfo info, {String? workingDir}) async {
    try {
      final success = await _client.start(
        info.command,
        info.args,
        info.language,
        workingDir: workingDir,
      );
      if (success) {
        info.status = LspServerStatus.running;
        info.errorMessage = null;
      } else {
        info.status = LspServerStatus.error;
        info.errorMessage = '启动失败：服务器无响应';
      }
      return success;
    } catch (e) {
      info.status = LspServerStatus.error;
      info.errorMessage = '启动异常: $e';
      return false;
    }
  }

  /// 停止当前服务器
  void stopServer() {
    _client.stop();
    for (final s in supportedServers) {
      if (s.status == LspServerStatus.running) {
        s.status = LspServerStatus.installed;
      }
    }
  }

  void dispose() {
    stopServer();
  }
}
