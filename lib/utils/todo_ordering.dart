import '../models/todo.dart';

List<Todo> normalizeTodoOrder(Iterable<Todo> todos) {
  final list = todos.toList(growable: false);
  return [
    for (var index = 0; index < list.length; index++)
      list[index].copyWith(order: index),
  ];
}

/// Reorders only the visible subset while keeping hidden todos in their slots.
///
/// This is important when the user is searching or viewing a status filter:
/// indices from the visible list must never be applied directly to the complete
/// list, otherwise an unrelated hidden todo can be moved.
List<Todo> reorderVisibleTodos({
  required List<Todo> allTodos,
  required List<Todo> visibleTodos,
  required int oldIndex,
  required int newIndex,
}) {
  if (oldIndex < 0 || oldIndex >= visibleTodos.length) {
    throw RangeError.index(oldIndex, visibleTodos, 'oldIndex');
  }
  if (newIndex < 0 || newIndex >= visibleTodos.length) {
    throw RangeError.index(newIndex, visibleTodos, 'newIndex');
  }

  final reorderedVisible = List<Todo>.of(visibleTodos);
  final moved = reorderedVisible.removeAt(oldIndex);
  reorderedVisible.insert(newIndex, moved);

  final visibleIds = visibleTodos.map((todo) => todo.id).toSet();
  var nextVisibleIndex = 0;
  final reorderedAll = <Todo>[];
  for (final todo in allTodos) {
    if (visibleIds.contains(todo.id)) {
      reorderedAll.add(reorderedVisible[nextVisibleIndex++]);
    } else {
      reorderedAll.add(todo);
    }
  }

  return normalizeTodoOrder(reorderedAll);
}
