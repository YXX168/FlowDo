import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/todo.dart';

class StorageService {
  static const String _fileName = 'todos.json';

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  Future<List<Todo>> loadTodos() async {
    try {
      final path = await _filePath;
      final file = File(path);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    try {
      final path = await _filePath;
      final file = File(path);
      final jsonList = todos.map((t) => t.toJson()).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(jsonStr);
    } catch (e) {
      // Silently fail - will retry on next save
    }
  }
}
