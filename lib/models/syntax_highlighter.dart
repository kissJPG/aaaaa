import 'package:flutter/material.dart';

/// 分词后的 Token 类型
enum TokenType {
  keyword,
  string,
  comment,
  number,
  punctuation,
  operator,
  builtin,
  decorator,
  type,
  tag,
  attribute,
  normal,
}

class Token {
  final TokenType type;
  final String text;
  Token(this.type, this.text);
}

/// 语法高亮引擎 —— 支持 Python / JavaScript / Java / Dart / Kotlin / Rust 等
class SyntaxHighlighterEngine {
  /// 各语言关键字表
  static final Map<String, List<String>> keywords = {
    'c': const [
      'auto', 'break', 'case', 'char', 'const', 'continue', 'default',
      'do', 'double', 'else', 'enum', 'extern', 'float', 'for', 'goto',
      'if', 'int', 'long', 'register', 'return', 'short', 'signed',
      'sizeof', 'static', 'struct', 'switch', 'typedef', 'union',
      'unsigned', 'void', 'volatile', 'while', 'include', 'define',
      'ifdef', 'ifndef', 'endif', 'pragma', 'error', 'line',
    ],
    'cpp': const [
      'alignas', 'alignof', 'and', 'and_eq', 'asm', 'auto', 'bitand',
      'bitor', 'bool', 'break', 'case', 'catch', 'char', 'class',
      'compl', 'concept', 'const', 'constexpr', 'const_cast', 'continue',
      'co_await', 'co_return', 'co_yield', 'decltype', 'default',
      'delete', 'do', 'double', 'dynamic_cast', 'else', 'enum',
      'explicit', 'export', 'extern', 'false', 'float', 'for', 'friend',
      'goto', 'if', 'inline', 'int', 'long', 'mutable', 'namespace',
      'new', 'noexcept', 'not', 'not_eq', 'ptr', 'operator', 'or',
      'or_eq', 'override', 'private', 'protected', 'public',
      'register', 'reinterpret_cast', 'requires', 'return', 'short',
      'signed', 'sizeof', 'static', 'static_assert', 'static_cast',
      'struct', 'switch', 'template', 'this', 'thread_local', 'throw',
      'true', 'try', 'typedef', 'typeid', 'typename', 'union',
      'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t',
      'while', 'xor', 'xor_eq',
    ],
    'csharp': const [
      'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch',
      'char', 'checked', 'class', 'const', 'continue', 'decimal',
      'default', 'delegate', 'do', 'double', 'else', 'enum', 'event',
      'explicit', 'extern', 'false', 'finally', 'fixed', 'float', 'for',
      'foreach', 'goto', 'if', 'implicit', 'in', 'int', 'interface',
      'internal', 'is', 'lock', 'long', 'namespace', 'new', '',
      'object', 'operator', 'out', 'override', 'params', 'private',
      'protected', 'public', 'readonly', 'ref', 'return', 'sbyte',
      'sealed', 'short', 'sizeof', 'stackalloc', 'static', 'string',
      'struct', 'switch', 'this', 'throw', 'true', 'try', 'typeof',
      'uint', 'ulong', 'unchecked', 'unsafe', 'ushort', 'using',
      'var', 'virtual', 'void', 'volatile', 'while',
    ],
    'go': const [
      'break', 'case', 'chan', 'const', 'continue', 'default', 'defer',
      'else', 'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import',
      'interface', 'map', 'package', 'range', 'return', 'select',
      'struct', 'switch', 'type', 'var',
    ],
    'python': const [
      'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await',
      'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except',
      'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is',
      'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return',
      'try', 'while', 'with', 'yield',
    ],
    'javascript': const [
      'async', 'await', 'break', 'case', 'catch', 'class', 'const',
      'continue', 'debugger', 'default', 'delete', 'do', 'else', 'export',
      'extends', 'false', 'finally', 'for', 'function', 'if', 'import',
      'in', 'instanceof', 'let', 'new', '', 'of', 'return', 'super',
      'switch', 'this', 'throw', 'true', 'try', 'typeof', 'var', 'void',
      'while', 'with', 'yield', 'undefined', 'static', 'get', 'set',
    ],
    'java': const [
      'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch',
      'char', 'class', 'const', 'continue', 'default', 'do', 'double',
      'else', 'enum', 'extends', 'false', 'final', 'finally', 'float',
      'for', 'goto', 'if', 'implements', 'import', 'instanceof', 'int',
      'interface', 'long', 'native', 'new', '', 'package', 'private',
      'protected', 'public', 'return', 'short', 'static', 'strictfp',
      'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
      'transient', 'true', 'try', 'void', 'volatile', 'while',
    ],
    'dart': const [
      'abstract', 'as', 'assert', 'async', 'await', 'break', 'case',
      'catch', 'class', 'const', 'continue', 'covariant', 'default',
      'deferred', 'do', 'dynamic', 'else', 'enum', 'export', 'extends',
      'extension', 'external', 'factory', 'false', 'final', 'finally',
      'for', 'Function', 'get', 'hide', 'if', 'implements', 'import',
      'in', 'interface', 'is', 'late', 'library', 'mixin', 'new', '',
      'on', 'operator', 'part', 'required', 'rethrow', 'return', 'set',
      'show', 'static', 'super', 'switch', 'sync', 'this', 'throw',
      'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
    ],
    'rust': const [
      'as', 'break', 'const', 'continue', 'crate', 'else', 'enum',
      'extern', 'false', 'fn', 'for', 'if', 'impl', 'in', 'let',
      'loop', 'match', 'mod', 'move', 'mut', 'pub', 'ref', 'return',
      'self', 'Self', 'static', 'struct', 'super', 'trait', 'true',
      'type', 'unsafe', 'use', 'where', 'while', 'async', 'await',
      'dyn',
    ],
    'ruby': const [
      'BEGIN', 'END', 'alias', 'and', 'begin', 'break', 'case', 'class',
      'def', 'defined', 'do', 'else', 'elsif', 'end', 'ensure', 'false',
      'for', 'if', 'in', 'module', 'next', 'nil', 'not', 'or', 'redo',
      'rescue', 'retry', 'return', 'self', 'super', 'then', 'true',
      'undef', 'unless', 'until', 'when', 'while', 'yield',
    ],
    'kotlin': const [
      'abstract', 'actual', 'annotation', 'as', 'break', 'by', 'catch',
      'class', 'companion', 'const', 'constructor', 'continue', 'crossinline',
      'data', 'delegate', 'do', 'dynamic', 'else', 'enum', 'expect',
      'external', 'false', 'field', 'file', 'final', 'finally', 'for',
      'fun', 'get', 'if', 'import', 'in', 'infix', 'init', 'inline',
      'inner', 'interface', 'internal', 'is', 'it', 'lateinit', 'noinline',
      '', 'object', 'open', 'operator', 'out', 'override', 'package',
      'param', 'private', 'property', 'protected', 'public', 'receiver',
      'reified', 'return', 'sealed', 'set', 'setparam', 'super', 'suspend',
      'tailrec', 'this', 'throw', 'true', 'try', 'typealias', 'typeof',
      'val', 'var', 'vararg', 'when', 'while',
    ],
    'swift': const [
      'as', 'associatedtype', 'break', 'case', 'catch', 'class', 'continue',
      'default', 'defer', 'deinit', 'do', 'else', 'enum', 'extension',
      'fallthrough', 'false', 'fileprivate', 'for', 'func', 'guard', 'if',
      'import', 'in', 'init', 'inout', 'internal', 'is', 'let', 'nil',
      'open', 'operator', 'private', 'protocol', 'public', 'repeat',
      'return', 'Self', 'self', 'static', 'struct', 'subscript', 'super',
      'switch', 'throw', 'throws', 'true', 'try', 'typealias', 'var',
      'where', 'while',
    ],
    'html': const [
      'html', 'head', 'body', 'title', 'meta', 'link', 'script', 'style',
      'div', 'span', 'p', 'a', 'img', 'ul', 'ol', 'li', 'table', 'tr',
      'td', 'th', 'thead', 'tbody', 'tfoot', 'form', 'input', 'button',
      'select', 'option', 'textarea', 'label', 'fieldset', 'legend',
      'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'footer', 'nav',
      'section', 'article', 'aside', 'main', 'figure', 'figcaption',
      'blockquote', 'pre', 'code', 'em', 'strong', 'br', 'hr',
      'iframe', 'canvas', 'svg', 'video', 'audio', 'source',
    ],
    'xml': const [
      'xml', 'version', 'encoding', 'standalone',
    ],
    'css': const [
      'color', 'background', 'font', 'margin', 'padding', 'border',
      'display', 'position', 'width', 'height', 'top', 'left', 'right',
      'bottom', 'float', 'clear', 'overflow', 'z-index', 'opacity',
      'text-align', 'text-decoration', 'font-size', 'font-weight',
      'font-family', 'line-height', 'letter-spacing', 'white-space',
      'flex', 'flex-direction', 'justify-content', 'align-items',
      'align-self', 'flex-wrap', 'grid', 'grid-template', 'gap',
      'transform', 'transition', 'animation', 'cursor', 'box-sizing',
      'border-radius', 'box-shadow', 'content', 'visibility',
      'pointer-events', 'user-select', 'resize', 'outline',
      'min-width', 'max-width', 'min-height', 'max-height',
      'background-color', 'background-image', 'background-size',
      '@media', '@import', '@keyframes', '@font-face',
    ],
    'json': const [
      'true', 'false', '',
    ],
    'yaml': const [
      'true', 'false', '', 'yes', 'no', 'on', 'off',
    ],
    'markdown': const [],
  };

  /// 各语言内置函数/类
  static final Map<String, List<String>> builtins = {
    'c': const [
      'auto', 'break', 'case', 'char', 'const', 'continue', 'default',
      'do', 'double', 'else', 'enum', 'extern', 'float', 'for', 'goto',
      'if', 'int', 'long', 'register', 'return', 'short', 'signed',
      'sizeof', 'static', 'struct', 'switch', 'typedef', 'union',
      'unsigned', 'void', 'volatile', 'while', 'include', 'define',
      'ifdef', 'ifndef', 'endif', 'pragma', 'error', 'line',
    ],
    'cpp': const [
      'alignas', 'alignof', 'and', 'and_eq', 'asm', 'auto', 'bitand',
      'bitor', 'bool', 'break', 'case', 'catch', 'char', 'class',
      'compl', 'concept', 'const', 'constexpr', 'const_cast', 'continue',
      'co_await', 'co_return', 'co_yield', 'decltype', 'default',
      'delete', 'do', 'double', 'dynamic_cast', 'else', 'enum',
      'explicit', 'export', 'extern', 'false', 'float', 'for', 'friend',
      'goto', 'if', 'inline', 'int', 'long', 'mutable', 'namespace',
      'new', 'noexcept', 'not', 'not_eq', 'ptr', 'operator', 'or',
      'or_eq', 'override', 'private', 'protected', 'public',
      'register', 'reinterpret_cast', 'requires', 'return', 'short',
      'signed', 'sizeof', 'static', 'static_assert', 'static_cast',
      'struct', 'switch', 'template', 'this', 'thread_local', 'throw',
      'true', 'try', 'typedef', 'typeid', 'typename', 'union',
      'unsigned', 'using', 'virtual', 'void', 'volatile', 'wchar_t',
      'while', 'xor', 'xor_eq',
    ],
    'csharp': const [
      'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch',
      'char', 'checked', 'class', 'const', 'continue', 'decimal',
      'default', 'delegate', 'do', 'double', 'else', 'enum', 'event',
      'explicit', 'extern', 'false', 'finally', 'fixed', 'float', 'for',
      'foreach', 'goto', 'if', 'implicit', 'in', 'int', 'interface',
      'internal', 'is', 'lock', 'long', 'namespace', 'new', '',
      'object', 'operator', 'out', 'override', 'params', 'private',
      'protected', 'public', 'readonly', 'ref', 'return', 'sbyte',
      'sealed', 'short', 'sizeof', 'stackalloc', 'static', 'string',
      'struct', 'switch', 'this', 'throw', 'true', 'try', 'typeof',
      'uint', 'ulong', 'unchecked', 'unsafe', 'ushort', 'using',
      'var', 'virtual', 'void', 'volatile', 'while',
    ],
    'go': const [
      'break', 'case', 'chan', 'const', 'continue', 'default', 'defer',
      'else', 'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import',
      'interface', 'map', 'package', 'range', 'return', 'select',
      'struct', 'switch', 'type', 'var',
    ],
    'c': const [
      'printf', 'scanf', 'malloc', 'free', 'sizeof', 'fopen', 'fclose',
      'fread', 'fwrite', 'fprintf', 'sprintf', 'strlen', 'strcpy',
      'strcmp', 'strcat', 'memcpy', 'memset', 'memmove', 'memcmp',
      'atoi', 'atof', 'exit', 'qsort', 'bsearch', 'assert',
      'stdin', 'stdout', 'stderr', 'EOF', 'NULL', 'FILE', 'size_t',
    ],
    'cpp': const [
      'cout', 'cin', 'cerr', 'endl', 'vector', 'string', 'map',
      'set', 'list', 'deque', 'queue', 'stack', 'array', 'pair',
      'make_pair', 'shared_ptr', 'unique_ptr', 'weak_ptr', 'make_shared',
      'make_unique', 'move', 'forward', 'swap', 'begin', 'end',
      'push_back', 'emplace_back', 'size', 'empty', 'clear', 'find',
      'sort', 'stable_sort', 'lower_bound', 'upper_bound',
      'istringstream', 'ostringstream', 'getline',
      'std', 'exception', 'runtime_error', 'logic_error',
    ],
    'csharp': const [
      'Console', 'WriteLine', 'Write', 'ReadLine', 'ReadKey',
      'String', 'Int32', 'Int64', 'Double', 'Boolean', 'DateTime',
      'List', 'Dictionary', 'HashSet', 'LinkedList', 'Queue', 'Stack',
      'IEnumerable', 'IEnumerator', 'IDisposable', 'EventArgs',
      'Convert', 'Math', 'Random', 'Guid', 'Path', 'File', 'Directory',
      'Stream', 'Task', 'async', 'await',
    ],
    'go': const [
      'fmt', 'Println', 'Printf', 'Sprintf', 'Errorf', 'Scan', 'Scanf',
      'make', 'len', 'cap', 'append', 'copy', 'delete', 'close',
      'new', 'panic', 'recover', 'defer', 'go',
      'string', 'int', 'int8', 'int16', 'int32', 'int64',
      'uint', 'uint8', 'uint16', 'uint32', 'uint64',
      'float32', 'float64', 'complex64', 'complex128',
      'bool', 'byte', 'rune', 'error',
      'nil', 'true', 'false', 'iota',
      'os', 'io', 'http', 'json', 'time', 'strings', 'strconv',
      'context', 'sync', 'sort', 'math', 'reflect',
    ],
    'python': const [
      'print', 'len', 'range', 'int', 'str', 'float', 'list', 'dict',
      'set', 'tuple', 'type', 'open', 'input', 'map', 'filter', 'zip',
      'enumerate', 'sorted', 'reversed', 'abs', 'max', 'min', 'sum',
      'any', 'all', 'isinstance', 'hasattr', 'getattr', 'setattr',
      '__init__', '__str__', '__repr__', '__name__', '__main__',
      'Exception', 'ValueError', 'TypeError', 'KeyError',
      'super', 'bytes', 'bool', 'chr', 'ord', 'hex', 'oct', 'bin',
      'round', 'pow', 'divmod', 'id', 'dir', 'help', 'vars',
    ],
    'javascript': const [
      'console', 'Math', 'JSON', 'Array', 'Object', 'String', 'Number',
      'Boolean', 'Date', 'RegExp', 'Set', 'Map', 'Promise', 'setTimeout',
      'setInterval', 'parseInt', 'parseFloat', 'isNaN', 'isFinite',
      'decodeURI', 'encodeURI', 'document', 'window', 'Error',
      'Symbol', 'Proxy', 'Reflect', 'Intl', 'BigInt', 'undefined',
      'fetch', 'require', 'module', 'exports',
    ],
    'java': const [
      'System', 'String', 'Integer', 'Double', 'Boolean', 'Character',
      'Byte', 'Short', 'Long', 'Float', 'Object', 'Class', 'Thread',
      'Runnable', 'ArrayList', 'HashMap', 'HashSet', 'LinkedList',
      'List', 'Map', 'Set', 'Collection', 'Iterator', 'Arrays',
      'Collections', 'Math', 'Scanner', 'StringBuilder', 'StringBuffer',
      'Exception', 'RuntimeException', 'IOException',
    ],
    'dart': const [
      'print', 'String', 'int', 'double', 'bool', 'List', 'Map', 'Set',
      'Object', 'Iterable', 'Future', 'Stream', 'void', 'Null', 'num',
      'DateTime', 'Duration', 'RegExp', 'Stopwatch', 'Timer',
      'Element', 'Widget', 'BuildContext', 'StatelessWidget',
      'StatefulWidget', 'State', 'Scaffold', 'Text', 'Container',
    ],
    'rust': const [
      'println', 'print', 'format', 'String', 'Vec', 'Option', 'Result',
      'Some', 'None', 'Ok', 'Err', 'Box', 'Rc', 'Arc', 'Cell',
      'RefCell', 'HashMap', 'BTreeMap', 'HashSet', 'BTreeSet',
      'i8', 'i16', 'i32', 'i64', 'u8', 'u16', 'u32', 'u64',
      'f32', 'f64', 'usize', 'isize', 'bool', 'char', 'str',
      'assert', 'assert_eq', 'panic', 'unreachable', 'todo',
      'dbg', 'clone', 'copy', 'drop', 'default',
    ],
    'ruby': const [
      'puts', 'print', 'gets', 'p', 'pp', 'lambda', 'proc',
      'Array', 'Hash', 'String', 'Integer', 'Float', 'Symbol',
      'Enumerable', 'Enumerator', 'File', 'Dir', 'IO',
      'raise', 'rescue', 'require', 'include', 'extend',
      'attr_accessor', 'attr_reader', 'attr_writer',
    ],
    'kotlin': const [
      'println', 'print', 'readLine', 'listOf', 'mutableListOf',
      'setOf', 'mutableSetOf', 'mapOf', 'mutableMapOf',
      'arrayOf', 'String', 'Int', 'Long', 'Double', 'Boolean',
      'List', 'MutableList', 'Set', 'MutableSet', 'Map', 'MutableMap',
      'run', 'let', 'also', 'apply', 'with', 'takeIf', 'takeUnless',
    ],
    'swift': const [
      'print', 'String', 'Int', 'Double', 'Bool', 'Array', 'Dictionary',
      'Set', 'Optional', 'URL', 'Data', 'Date', 'Timer',
      'NotificationCenter', 'UserDefaults', 'FileManager',
      'UIView', 'UIViewController', 'UILabel', 'UIButton',
    ],
    'html': const [
      'id', 'class', 'style', 'src', 'href', 'alt', 'title', 'type',
      'name', 'value', 'placeholder', 'disabled', 'readonly', 'checked',
      'selected', 'required', 'maxlength', 'min', 'max', 'step',
      'pattern', 'autocomplete', 'autofocus', 'target', 'rel',
      'onclick', 'onchange', 'onsubmit', 'data-',
    ],
    'xml': const [
      'xmlns', 'xsi', 'schemaLocation', 'noNamespaceSchemaLocation',
    ],
    'css': const [
      'none', 'auto', 'inherit', 'initial', 'unset',
      'block', 'inline', 'inline-block', 'flex', 'grid',
      'absolute', 'relative', 'fixed', 'sticky',
      'hidden', 'visible', 'scroll', 'solid', 'dashed', 'dotted',
      'px', 'em', 'rem', '%', 'vw', 'vh', 'vmin', 'vmax',
      'rgb', 'rgba', 'hsl', 'hsla', 'var', 'calc', 'min', 'max',
      'url', 'linear-gradient', 'radial-gradient',
    ],
    'json': const [],
    'yaml': const [],
    'markdown': const [],
  };

  /// 将通用语言名映射到有定义的关键词表（公开方法）
  static String mapLanguage(String language) {
    if (keywords.containsKey(language)) return language;
    // 别名映射
    if (language == 'scss' || language == 'less' || language == 'sass') return 'css';
    if (language == 'svg' || language == 'xaml' || language == 'plist') return 'xml';
    if (language == 'jsonc' || language == 'geojson') return 'json';
    if (language == 'markdown' || language == 'mdx') return 'markdown';
    if (language == 'htm') return 'html';
    if (language == 'yml') return 'yaml';
    return 'python';
  }

  /// 对一行代码进行词法分析，返回 Token 列表
  static List<Token> tokenizeLine(String line, String language) {
    // 标记语言使用专用分词器
    if (language == 'html' || language == 'xml') {
      return _tokenizeMarkup(line, language);
    }
    if (language == 'css' || language == 'scss' || language == 'less' || language == 'sass') {
      return _tokenizeCSS(line);
    }
    if (language == 'json' || language == 'jsonc' || language == 'geojson') {
      return _tokenizeJson(line);
    }
    if (language == 'yaml' || language == 'yml') {
      return _tokenizeYaml(line);
    }
    if (language == 'markdown' || language == 'mdx' || language == 'md') {
      return _tokenizeMarkdown(line);
    }

    final actualLang = mapLanguage(language);
    final kwSet = Set<String>.from(keywords[actualLang] ?? keywords['python']!);
    final builtinSet = Set<String>.from(
        builtins[actualLang] ?? builtins['python']!);

    final tokens = <Token>[];

    final regex = RegExp(
      r'''([a-zA-Z_]\w*)|('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"|`(?:[^`\\]|\\.)*`)|(#.*$|//.*$)|(/\*[\s\S]*?\*/)|(\b\d+\.?\d*(?:[eE][+-]?\d+)?\b)|([{}()\[\];:.,<>=!+\-*/%&|^~?@#])|(\s+)''',
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        tokens.add(Token(TokenType.normal, line.substring(lastEnd, match.start)));
      }
      lastEnd = match.end;

      final text = match.group(0)!;

      if (match.group(1) != null) {
        // 标识符
        if (kwSet.contains(text)) {
          tokens.add(Token(TokenType.keyword, text));
        } else if (builtinSet.contains(text)) {
          tokens.add(Token(TokenType.builtin, text));
        } else if (text.startsWith('__') && text.endsWith('__')) {
          tokens.add(Token(TokenType.builtin, text));
        } else if (text.isNotEmpty && text[0] == text[0].toUpperCase() && text.length > 1) {
          tokens.add(Token(TokenType.type, text));
        } else {
          tokens.add(Token(TokenType.normal, text));
        }
      } else if (match.group(2) != null) {
        tokens.add(Token(TokenType.string, text));
      } else if (match.group(3) != null || match.group(4) != null) {
        tokens.add(Token(TokenType.comment, text));
      } else if (match.group(5) != null) {
        tokens.add(Token(TokenType.number, text));
      } else if (match.group(6) != null) {
        if ('=<>!+-*/%&|^~?'.contains(text[0])) {
          tokens.add(Token(TokenType.operator, text));
        } else if (text == '@') {
          tokens.add(Token(TokenType.decorator, text));
        } else {
          tokens.add(Token(TokenType.punctuation, text));
        }
      } else if (match.group(7) != null) {
        tokens.add(Token(TokenType.normal, text));
      }
    }
    if (lastEnd < line.length) {
      tokens.add(Token(TokenType.normal, line.substring(lastEnd)));
    }
    return tokens;
  }

  /// 根据 Token 类型返回颜色
  static Color colorForToken(TokenType type, {required bool isDark}) {
    final light = isDark ? _darkColors : _lightColors;
    return light[type] ?? (isDark ? const Color(0xFFD4D4D4) : Colors.black);
  }

  static const Map<TokenType, Color> _lightColors = {
    TokenType.keyword: Color(0xFF0000FF),
    TokenType.string: Color(0xFF008000),
    TokenType.comment: Color(0xFF808080),
    TokenType.number: Color(0xFF098658),
    TokenType.builtin: Color(0xFF795E26),
    TokenType.type: Color(0xFF267F99),
    TokenType.tag: Color(0xFF800000),
    TokenType.attribute: Color(0xFF0000FF),
    TokenType.operator: Color(0xFF000000),
    TokenType.punctuation: Color(0xFF000000),
    TokenType.decorator: Color(0xFFAF00DB),
    TokenType.normal: Color(0xFF000000),
  };

  static const Map<TokenType, Color> _darkColors = {
    TokenType.keyword: Color(0xFF569CD6),
    TokenType.string: Color(0xFFCE9178),
    TokenType.comment: Color(0xFF6A9955),
    TokenType.number: Color(0xFFB5CEA8),
    TokenType.builtin: Color(0xFFDCDCAA),
    TokenType.type: Color(0xFF4EC9B0),
    TokenType.tag: Color(0xFF569CD6),
    TokenType.attribute: Color(0xFF9CDCFE),
    TokenType.operator: Color(0xFFD4D4D4),
    TokenType.punctuation: Color(0xFFD4D4D4),
    TokenType.decorator: Color(0xFFC586C0),
    TokenType.normal: Color(0xFFD4D4D4),
  };

  // ===== 专用分词器 =====

  /// HTML/XML 标记语言分词器
  static List<Token> _tokenizeMarkup(String line, String language) {
    final tokens = <Token>[];
    final regex = RegExp(
      r'(</?[a-zA-Z][\w-]*)|(\s+[a-zA-Z][\w-]*)\s*=|("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')|(<!--[\s\S]*?-->)',
    );
    // 注：简化版，主要区分标签、属性、属性值、注释
    final fullRegex = RegExp(
      r'(</?[a-zA-Z][\w.-]*>?)|(\b[a-zA-Z][\w-]*)\s*(?==)|("[^"]*"|'[^']*')|(<!--[\s\S]*?-->)|([^<]+)',
    );
    int lastEnd = 0;
    for (final match in fullRegex.allMatches(line)) {
      if (match.start > lastEnd) {
        tokens.add(Token(TokenType.normal, line.substring(lastEnd, match.start)));
      }
      lastEnd = match.end;
      final text = match.group(0)!;

      if (match.group(1) != null) {
        // 标签: <tagname 或 </tagname 或 />
        tokens.add(Token(TokenType.tag, text));
      } else if (match.group(2) != null) {
        // 属性名
        tokens.add(Token(TokenType.attribute, text));
      } else if (match.group(3) != null) {
        // 属性值（引号字符串）
        tokens.add(Token(TokenType.string, text));
      } else if (match.group(4) != null) {
        // 注释
        tokens.add(Token(TokenType.comment, text));
      } else if (match.group(5) != null) {
        // 普通文本内容
        tokens.add(Token(TokenType.normal, text));
      }
    }
    if (lastEnd < line.length) {
      tokens.add(Token(TokenType.normal, line.substring(lastEnd)));
    }
    return tokens;
  }

  /// CSS 分词器
  static List<Token> _tokenizeCSS(String line) {
    final tokens = <Token>[];
    // CSS 属性:值; @规则 选择器{} 注释
    final regex = RegExp(
      r'(@[a-zA-Z-]+)|([.#]?[a-zA-Z][\w-]*(?=\s*\{))|([a-zA-Z-]+(?=\s*:))|'
      r'([a-fA-F0-9]{3,8}|\b\d+\.?\d*(?:px|em|rem|%|vw|vh|s|ms|deg)?\b)|'
      r'(\/\*[\s\S]*?\*\/)|("[^"]*"|'[^']*')|([{}():;,])|(\s+)',
    );
    int lastEnd = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        tokens.add(Token(TokenType.normal, line.substring(lastEnd, match.start)));
      }
      lastEnd = match.end;
      final text = match.group(0)!;

      if (match.group(1) != null) {
        tokens.add(Token(TokenType.decorator, text)); // @规则
      } else if (match.group(2) != null) {
        tokens.add(Token(TokenType.type, text)); // 选择器
      } else if (match.group(3) != null) {
        tokens.add(Token(TokenType.attribute, text)); // CSS属性
      } else if (match.group(4) != null) {
        tokens.add(Token(TokenType.number, text)); // 数值/颜色
      } else if (match.group(5) != null) {
        tokens.add(Token(TokenType.comment, text));
      } else if (match.group(6) != null) {
        tokens.add(Token(TokenType.string, text));
      } else if (match.group(7) != null) {
        tokens.add(Token(TokenType.punctuation, text));
      } else if (match.group(8) != null) {
        tokens.add(Token(TokenType.normal, text));
      }
    }
    if (lastEnd < line.length) {
      tokens.add(Token(TokenType.normal, line.substring(lastEnd)));
    }
    return tokens;
  }

  /// JSON 分词器
  static List<Token> _tokenizeJson(String line) {
    final tokens = <Token>[];
    final regex = RegExp(
      r'("(?:[^"\\]|\\.)*")\s*:|("(?:[^"\\]|\\.)*")|'
      r'(\btrue\b|\bfalse\b|\b\b)|'
      r'(-?\b\d+\.?\d*(?:[eE][+-]?\d+)?\b)|([{}()\[\],:])|(\s+)',
    );
    int lastEnd = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        tokens.add(Token(TokenType.normal, line.substring(lastEnd, match.start)));
      }
      lastEnd = match.end;
      final text = match.group(0)!;

      if (match.group(1) != null) {
        // key: 带冒号的键
        tokens.add(Token(TokenType.attribute, text));
      } else if (match.group(2) != null) {
        tokens.add(Token(TokenType.string, text));
      } else if (match.group(3) != null) {
        tokens.add(Token(TokenType.keyword, text));
      } else if (match.group(4) != null) {
        tokens.add(Token(TokenType.number, text));
      } else if (match.group(5) != null) {
        tokens.add(Token(TokenType.punctuation, text));
      } else if (match.group(6) != null) {
        tokens.add(Token(TokenType.normal, text));
      }
    }
    if (lastEnd < line.length) {
      tokens.add(Token(TokenType.normal, line.substring(lastEnd)));
    }
    return tokens;
  }

  /// YAML 分词器
  static List<Token> _tokenizeYaml(String line) {
    final tokens = <Token>[];
    // YAML: key: value, - 列表项, # 注释, | 多行字符串
    final regex = RegExp(
      r'(^[a-zA-Z_][\w.-]*)\s*:(?=\s|$)|'
      r'(\btrue\b|\bfalse\b|\b\b|\byes\b|\bno\b|\bon\b|\boff\b)|'
      r'(-?\b\d+\.?\d*(?:[eE][+-]?\d+)?\b)|'
      r'(#.*$)|'
      r'("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')|'
      r'(:\s+|\s+-\s)|'
      r'(\d{4}-\d{2}-\d{2})|'
      r'(\S+)',
    );
    int lastEnd = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        tokens.add(Token(TokenType.normal, line.substring(lastEnd, match.start)));
      }
      lastEnd = match.end;
      final text = match.group(0)!;

      if (match.group(1) != null) {
        tokens.add(Token(TokenType.attribute, text)); // key:
      } else if (match.group(2) != null) {
        tokens.add(Token(TokenType.keyword, text));
      } else if (match.group(3) != null) {
        tokens.add(Token(TokenType.number, text));
      } else if (match.group(4) != null) {
        tokens.add(Token(TokenType.comment, text));
      } else if (match.group(5) != null) {
        tokens.add(Token(TokenType.string, text));
      } else if (match.group(6) != null) {
        tokens.add(Token(TokenType.punctuation, text));
      } else if (match.group(7) != null) {
        tokens.add(Token(TokenType.number, text)); // 日期
      } else if (match.group(8) != null) {
        tokens.add(Token(TokenType.normal, text));
      }
    }
    if (lastEnd < line.length) {
      tokens.add(Token(TokenType.normal, line.substring(lastEnd)));
    }
    return tokens;
  }

  /// Markdown 分词器
  static List<Token> _tokenizeMarkdown(String line) {
    final tokens = <Token>[];
    // Markdown: # 标题, **粗体**, *斜体*, `代码`, [链接](url), 普通文本
    final regex = RegExp(
      r'(^#{1,6}\s+[^\n]+)|'
      r'(\*\*[^*]+\*\*)|'
      r'(\*[^*]+\*|_[^_]+_)|'
      r'(`[^`]+`)|'
      r'(\[[^\]]+\]\([^)]+\))|'
      r'(^>\s.*)|'
      r'(^\s*[-*+]\s)|'
      r'(\S+)',
    );
    int lastEnd = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        tokens.add(Token(TokenType.normal, line.substring(lastEnd, match.start)));
      }
      lastEnd = match.end;
      final text = match.group(0)!;

      if (match.group(1) != null) {
        tokens.add(Token(TokenType.keyword, text)); // 标题 #
      } else if (match.group(2) != null) {
        tokens.add(Token(TokenType.builtin, text)); // 粗体 **
      } else if (match.group(3) != null) {
        tokens.add(Token(TokenType.type, text)); // 斜体 *
      } else if (match.group(4) != null) {
        tokens.add(Token(TokenType.string, text)); // 行内代码 `
      } else if (match.group(5) != null) {
        tokens.add(Token(TokenType.attribute, text)); // [链接]()
      } else if (match.group(6) != null) {
        tokens.add(Token(TokenType.comment, text)); // 引用 >
      } else if (match.group(7) != null) {
        tokens.add(Token(TokenType.punctuation, text)); // 列表项
      } else if (match.group(8) != null) {
        tokens.add(Token(TokenType.normal, text));
      }
    }
    if (lastEnd < line.length) {
      tokens.add(Token(TokenType.normal, line.substring(lastEnd)));
    }
    return tokens;
  }

  /// 实例方法版 tokenize：对多行文本的指定行进行词法分析
  List<Token> tokenize(String line, String language) {
    return SyntaxHighlighterEngine.tokenizeLine(line, language);
  }
  /// 实例方法版 tokenColor：根据 Token 类型返回颜色
  Color tokenColor(Token token, bool isDark) {
    return SyntaxHighlighterEngine.colorForToken(token.type, isDark: isDark);
  }


}
