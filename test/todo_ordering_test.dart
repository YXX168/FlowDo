import 'package:flowdo/models/todo.dart';
import 'package:flowdo/utils/todo_ordering.dart';
import 'package:flutter_test/flutter_test.dart';

Todo todo(String id, int order) => Todo(
      id: id,
      text: id,
      createdAt: order,
      order: order,
    );

void main() {
  test('normalizeTodoOrder assigns contiguous positions', () {
    final result = normalizeTodoOrder([todo('a', 10), todo('b', -4)]);

    expect(result.map((item) => item.order), [0, 1]);
  });

  test('filtered reorder keeps hidden items in their slots', () {
    final all = [todo('a', 0), todo('b', 1), todo('c', 2), todo('d', 3)];
    final visible = [all[1], all[3]];

    final result = reorderVisibleTodos(
      allTodos: all,
      visibleTodos: visible,
      oldIndex: 1,
      newIndex: 0,
    );

    expect(result.map((item) => item.id), ['a', 'd', 'c', 'b']);
    expect(result.map((item) => item.order), [0, 1, 2, 3]);
  });

  test('uses the adjusted forward index from ReorderableListView', () {
    final all = [todo('a', 0), todo('b', 1), todo('c', 2), todo('d', 3)];

    final result = reorderVisibleTodos(
      allTodos: all,
      visibleTodos: all,
      oldIndex: 0,
      newIndex: 3,
    );

    expect(result.map((item) => item.id), ['b', 'c', 'd', 'a']);
  });
}
