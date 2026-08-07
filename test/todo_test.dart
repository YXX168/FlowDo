import 'package:flowdo/models/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Todo', () {
    test('normalizes unsupported persisted values', () {
      final todo = Todo.fromJson({
        'id': '1',
        'text': 'Review FlowDo',
        'priority': 'urgent',
        'category': 'unknown',
        'createdAt': 'invalid',
        'dueDate': 'invalid',
        'order': 'invalid',
      });

      expect(todo.priority, TodoPriority.medium);
      expect(todo.category, TodoCategory.other);
      expect(todo.dueDate, isNull);
      expect(todo.order, 0);
      expect(todo.createdAt, isA<int>());
    });

    test('round trips through JSON', () {
      final original = Todo(
        id: 'todo-1',
        text: 'Ship the app',
        completed: true,
        priority: TodoPriority.high,
        createdAt: 123,
        dueDate: 456,
        category: TodoCategory.work,
        order: 2,
      );

      final restored = Todo.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
    });

    test('copyWith can explicitly clear a due date', () {
      final todo = Todo(
        id: 'todo-1',
        text: 'Plan release',
        createdAt: 123,
        dueDate: 456,
      );

      expect(todo.copyWith(dueDate: null).dueDate, isNull);
    });
  });
}
