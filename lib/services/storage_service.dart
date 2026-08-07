import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';
import '../utils/todo_ordering.dart';

class StorageException implements Exception {
  const StorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class StorageService {
  static const String _fileName = 'todos.json';

  Future<void> _saveQueue = Future<void>.value();

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}$_fileName';
  }

  Future<List<Todo>> loadTodos() async {
    try {
      final path = await _filePath;
      final file = File(path);
      final backup = File('$path.bak');
      // Recover the last known-good file if the app stopped between the two
      // rename operations of an atomic save.
      if (!await file.exists() && await backup.exists()) {
        await backup.rename(path);
      }
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final decoded = jsonDecode(content);
      if (decoded is! List<dynamic>) {
        throw const FormatException('Todo data must be a JSON list.');
      }

      final seenIds = <String>{};
      final todos = <Todo>[];
      for (var index = 0; index < decoded.length; index++) {
        final item = decoded[index];
        if (item is! Map<String, dynamic>) continue;

        var todo = Todo.fromJson(item);
        var id = todo.id.trim();
        if (id.isEmpty || seenIds.contains(id)) {
          id = '${todo.createdAt}-$index';
          todo = Todo(
            id: id,
            text: todo.text,
            completed: todo.completed,
            priority: todo.priority,
            createdAt: todo.createdAt,
            dueDate: todo.dueDate,
            category: todo.category,
            order: todo.order,
          );
        }
        seenIds.add(id);
        todos.add(todo);
      }

      todos.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.createdAt.compareTo(b.createdAt);
      });
      return normalizeTodoOrder(todos);
    } on FormatException catch (error) {
      final path = await _filePath;
      try {
        await _preserveCorruptFile(File(path));
      } on FileSystemException {
        // The original file remains untouched if creating the backup fails.
      }
      throw StorageException('待办数据已损坏，原文件已备份。', error);
    } on FileSystemException catch (error) {
      throw StorageException('无法读取本地待办数据。', error);
    }
  }

  Future<void> saveTodos(List<Todo> todos) {
    // Serialize now so later in-memory changes cannot alter an in-flight save.
    final snapshot = const JsonEncoder.withIndent('  ')
        .convert(todos.map((todo) => todo.toJson()).toList());
    final operation = _saveQueue.then((_) => _writeSnapshot(snapshot));

    // Keep the queue usable after a failed write while still returning the
    // original error to the caller that requested this save.
    _saveQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  Future<void> _writeSnapshot(String snapshot) async {
    final path = await _filePath;
    final file = File(path);
    final temp = File('$path.tmp');
    final backup = File('$path.bak');

    try {
      await temp.writeAsString(snapshot, flush: true);
      if (await backup.exists()) await backup.delete();
      if (await file.exists()) await file.rename(backup.path);
      await temp.rename(path);
      if (await backup.exists()) await backup.delete();
    } on FileSystemException catch (error) {
      if (!await file.exists() && await backup.exists()) {
        try {
          await backup.rename(path);
        } on FileSystemException {
          // Keep the backup in place so it can be recovered on next launch.
        }
      }
      throw StorageException('无法保存待办数据，请检查设备存储空间。', error);
    } finally {
      try {
        if (await temp.exists()) await temp.delete();
      } on FileSystemException {
        // A stale temp file is harmless and will be replaced on the next save.
      }
    }
  }

  Future<void> _preserveCorruptFile(File file) async {
    if (!await file.exists()) return;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await file.copy('${file.path}.corrupt-$timestamp');
  }
}
