import 'syntax_highlighter.dart';

/// 代码补全候选
class CompletionItem {
  final String label;
  final String detail;
  final String insertText;

  CompletionItem(this.label, this.detail, this.insertText);
}

/// 基于词法的智能代码补全引擎
class CodeCompletionEngine {
  /// 获取当前光标位置的补全候选列表
  static List<CompletionItem> getCompletions(
    String text,
    int cursorOffset,
    String language,
  ) {
    final prefix = extractPrefix(text, cursorOffset);
    if (prefix.isEmpty) return [];

    final results = <CompletionItem>[];
    final prefixLower = prefix.toLowerCase();

    // 映射语言
    final actualLang = SyntaxHighlighterEngine.mapLanguage(language);

    // 1. 关键字匹配
    final kws = SyntaxHighlighterEngine.keywords[actualLang] ?? [];
    for (final kw in kws) {
      if (kw.isNotEmpty && kw.toLowerCase().startsWith(prefixLower)) {
        results.add(CompletionItem(kw, 'keyword', '$kw '));
      }
    }

    // 2. 内置函数/类匹配
    final builtins = SyntaxHighlighterEngine.builtins[actualLang] ?? [];
    for (final b in builtins) {
      if (b.toLowerCase().startsWith(prefixLower)) {
        results.add(CompletionItem(b, 'built-in', b));
      }
    }

    // 3. 常见代码片段补全
    _addSnippetCompletions(results, prefix, actualLang);

    // 4. 上下文补全
    _addContextCompletions(results, text, cursorOffset, actualLang);

    // 去重并排序
    final seen = <String>{};
    final unique = <CompletionItem>[];
    for (final item in results) {
      if (seen.add(item.label)) {
        unique.add(item);
      }
    }
    unique.sort((a, b) {
      if (a.label == prefix) return -1;
      if (b.label == prefix) return 1;
      final aIsKw = a.detail == 'keyword';
      final bIsKw = b.detail == 'keyword';
      if (aIsKw && !bIsKw) return -1;
      if (!aIsKw && bIsKw) return 1;
      return a.label.compareTo(b.label);
    });

    return unique.take(20).toList();
  }

  /// 从文本中提取光标前的单词前缀
  static String extractPrefix(String text, int offset) {
    if (offset <= 0) return '';
    final adjustedOffset = offset > text.length ? text.length : offset;
    final before = text.substring(0, adjustedOffset);
    final regex = RegExp(r'[a-zA-Z_]\w*$');
    final match = regex.firstMatch(before);
    return match?.group(0) ?? '';
  }

  /// 添加代码片段补全
  static void _addSnippetCompletions(
    List<CompletionItem> results,
    String prefix,
    String language,
  ) {
    final prefixLower = prefix.toLowerCase();

    if (language == 'python') {
      if ('def'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'def', 'snippet', 'def function_name(params):\n    pass'));
      }
      if ('class'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'class', 'snippet',
            'class ClassName:\n    def __init__(self):\n        pass'));
      }
      if ('if'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'if __name__', 'snippet',
            'if __name__ == "__main__":\n    main()'));
      }
      if ('for'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'for loop', 'snippet', 'for item in iterable:\n    pass'));
      }
      if ('try'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'try except', 'snippet',
            'try:\n    pass\nexcept Exception as e:\n    print(e)'));
      }
      if ('while'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'while loop', 'snippet', 'while condition:\n    pass'));
      }
      if ('with'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'with statement', 'snippet', 'with open(filename) as f:\n    pass'));
      }
      if ('lambda'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'lambda', 'snippet', 'lambda x: x'));
      }
      if ('im'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'import module', 'snippet', 'import '));
      }
    } else if (language == 'javascript') {
      if ('fun'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'function', 'snippet', 'function name(params) {\n    \n}'));
      }
      if ('arrow'.startsWith(prefixLower) || 'arr'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'arrow function', 'snippet', 'const name = (params) => {\n    \n}'));
      }
      if ('for'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'for loop', 'snippet',
            'for (let i = 0; i < length; i++) {\n    \n}'));
      }
      if ('if'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'if else', 'snippet',
            'if (condition) {\n    \n} else {\n    \n}'));
      }
      if ('try'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'try catch', 'snippet',
            'try {\n    \n} catch (error) {\n    console.error(error);\n}'));
      }
      if ('cl'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'class', 'snippet',
            'class ClassName {\n    constructor() {\n        \n    }\n}'));
      }
      if ('console'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'console.log', 'snippet', 'console.log('));
      }
      if ('fetch'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'fetch', 'snippet',
            'fetch(url)\n    .then(response => response.json())\n    .then(data => console.log(data));'));
      }
    } else if (language == 'java') {
      if ('pub'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'public static void', 'snippet',
            'public static void main(String[] args) {\n    \n}'));
      }
      if ('for'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'for loop', 'snippet',
            'for (int i = 0; i < length; i++) {\n    \n}'));
      }
      if ('sop'.startsWith(prefixLower) || 'System.out'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'System.out.println', 'snippet', 'System.out.println("");'));
      }
      if ('try'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'try catch', 'snippet',
            'try {\n    \n} catch (Exception e) {\n    e.printStackTrace();\n}'));
      }
      if ('swi'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'switch case', 'snippet',
            'switch (variable) {\n    case value:\n        break;\n    default:\n        break;\n}'));
      }
    } else if (language == 'dart') {
      if ('wid'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'Widget build', 'snippet',
            'Widget build(BuildContext context) {\n    return \n}'));
      }
      if ('stat'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'StatefulWidget', 'snippet',
            'class ClassName extends StatefulWidget {\n    @override\n    _ClassNameState createState() => _ClassNameState();\n}\n\nclass _ClassNameState extends State<ClassName> {\n    @override\n    Widget build(BuildContext context) {\n        return \n    }\n}'));
      }
    } else if (language == 'rust') {
      if ('fn'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'fn', 'snippet', 'fn name() {\n    \n}'));
      }
      if ('imp'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'impl', 'snippet', 'impl StructName {\n    fn new() -> Self {\n        \n    }\n}'));
      }
      if ('match'.startsWith(prefixLower)) {
        results.add(CompletionItem(
            'match', 'snippet', 'match value {\n    Some(x) => x,\n    None => return,\n}'));
      }
    }
  }

  /// 根据上下文添加补全
  static void _addContextCompletions(
    List<CompletionItem> results,
    String text,
    int cursorOffset,
    String language,
  ) {
    final adjustedOffset = cursorOffset > text.length ? text.length : cursorOffset;
    final before = text.substring(0, adjustedOffset);
    final dotMatch = RegExp(r'(\w+)\.$').firstMatch(before);
    if (dotMatch != null) {
      final objName = dotMatch.group(1)!;
      _addMemberCompletions(results, objName, language);
    }
  }

  /// 根据对象名补全成员
  static void _addMemberCompletions(
    List<CompletionItem> results,
    String objName,
    String language,
  ) {
    final lower = objName.toLowerCase();

    if (language == 'python') {
      if (lower.contains('list') || lower == 'lst' || lower == 'arr') {
        results.addAll([
          CompletionItem('append', 'method', 'append(item)'),
          CompletionItem('extend', 'method', 'extend(iterable)'),
          CompletionItem('pop', 'method', 'pop()'),
          CompletionItem('remove', 'method', 'remove(item)'),
          CompletionItem('sort', 'method', 'sort()'),
          CompletionItem('reverse', 'method', 'reverse()'),
          CompletionItem('index', 'method', 'index(item)'),
          CompletionItem('count', 'method', 'count(item)'),
        ]);
      } else if (lower.contains('dict') || lower == 'd') {
        results.addAll([
          CompletionItem('keys', 'method', 'keys()'),
          CompletionItem('values', 'method', 'values()'),
          CompletionItem('items', 'method', 'items()'),
          CompletionItem('get', 'method', 'get(key)'),
          CompletionItem('pop', 'method', 'pop(key)'),
          CompletionItem('update', 'method', 'update(other)'),
        ]);
      } else if (lower.contains('str') || lower == 's') {
        results.addAll([
          CompletionItem('split', 'method', 'split(sep)'),
          CompletionItem('join', 'method', 'join(iterable)'),
          CompletionItem('replace', 'method', 'replace(old, new)'),
          CompletionItem('strip', 'method', 'strip()'),
          CompletionItem('lower', 'method', 'lower()'),
          CompletionItem('upper', 'method', 'upper()'),
          CompletionItem('startswith', 'method', 'startswith(prefix)'),
          CompletionItem('endswith', 'method', 'endswith(suffix)'),
          CompletionItem('format', 'method', 'format(*args)'),
        ]);
      }
    } else if (language == 'javascript') {
      if (lower.contains('console')) {
        results.addAll([
          CompletionItem('log', 'method', 'log()'),
          CompletionItem('error', 'method', 'error()'),
          CompletionItem('warn', 'method', 'warn()'),
          CompletionItem('table', 'method', 'table()'),
        ]);
      } else if (lower.contains('array') || lower == 'arr') {
        results.addAll([
          CompletionItem('push', 'method', 'push(item)'),
          CompletionItem('pop', 'method', 'pop()'),
          CompletionItem('map', 'method', 'map(callback)'),
          CompletionItem('filter', 'method', 'filter(callback)'),
          CompletionItem('reduce', 'method', 'reduce(callback)'),
          CompletionItem('forEach', 'method', 'forEach(callback)'),
          CompletionItem('find', 'method', 'find(callback)'),
        ]);
      } else if (lower == 'math') {
        results.addAll([
          CompletionItem('abs', 'method', 'abs(x)'),
          CompletionItem('ceil', 'method', 'ceil(x)'),
          CompletionItem('floor', 'method', 'floor(x)'),
          CompletionItem('round', 'method', 'round(x)'),
          CompletionItem('random', 'method', 'random()'),
          CompletionItem('max', 'method', 'max(...)'),
          CompletionItem('min', 'method', 'min(...)'),
          CompletionItem('sqrt', 'method', 'sqrt(x)'),
        ]);
      }
    } else if (language == 'java') {
      if (lower.contains('string') || lower == 'str') {
        results.addAll([
          CompletionItem('length', 'method', 'length()'),
          CompletionItem('charAt', 'method', 'charAt(index)'),
          CompletionItem('substring', 'method', 'substring(begin, end)'),
          CompletionItem('equals', 'method', 'equals(obj)'),
          CompletionItem('toLowerCase', 'method', 'toLowerCase()'),
          CompletionItem('toUpperCase', 'method', 'toUpperCase()'),
          CompletionItem('trim', 'method', 'trim()'),
          CompletionItem('split', 'method', 'split(regex)'),
          CompletionItem('replace', 'method', 'replace(old, new)'),
          CompletionItem('contains', 'method', 'contains(s)'),
        ]);
      } else if (lower.contains('list') || lower.contains('arraylist')) {
        results.addAll([
          CompletionItem('add', 'method', 'add(item)'),
          CompletionItem('get', 'method', 'get(index)'),
          CompletionItem('remove', 'method', 'remove(item)'),
          CompletionItem('size', 'method', 'size()'),
          CompletionItem('clear', 'method', 'clear()'),
          CompletionItem('contains', 'method', 'contains(item)'),
        ]);
      }
    }
  }
}
