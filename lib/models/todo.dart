class TodoPriority {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';
  static const List<String> values = [high, medium, low];

  static String normalize(Object? value) =>
      value is String && values.contains(value) ? value : medium;
}

class TodoCategory {
  static const String work = 'work';
  static const String personal = 'personal';
  static const String shopping = 'shopping';
  static const String other = 'other';
  static const List<String> values = [work, personal, shopping, other];

  static String normalize(Object? value) =>
      value is String && values.contains(value) ? value : other;
}

class Todo {
  static const Object _notProvided = Object();

  final String id;
  final String text;
  final bool completed;
  final String priority;
  final int createdAt;
  final int? dueDate;
  final String category;
  final int order;

  Todo({
    required this.id,
    required this.text,
    this.completed = false,
    this.priority = TodoPriority.medium,
    required this.createdAt,
    this.dueDate,
    this.category = TodoCategory.other,
    this.order = 0,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    final completed = json['completed'];
    final createdAt = json['createdAt'];
    final dueDate = json['dueDate'];
    final order = json['order'];

    return Todo(
      id: id is String ? id : '',
      text: text is String ? text : '',
      completed: completed is bool ? completed : false,
      priority: TodoPriority.normalize(json['priority']),
      createdAt: createdAt is int
          ? createdAt
          : int.tryParse(createdAt is String ? createdAt : '') ??
              DateTime.now().millisecondsSinceEpoch,
      dueDate: dueDate is int ? dueDate : null,
      category: TodoCategory.normalize(json['category']),
      order: order is int ? order : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
        'priority': priority,
        'createdAt': createdAt,
        'dueDate': dueDate,
        'category': category,
        'order': order,
      };

  Todo copyWith({
    String? text,
    bool? completed,
    String? priority,
    Object? dueDate = _notProvided,
    String? category,
    int? order,
  }) {
    return Todo(
      id: id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      priority: TodoPriority.normalize(priority ?? this.priority),
      createdAt: createdAt,
      dueDate: identical(dueDate, _notProvided) ? this.dueDate : dueDate as int?,
      category: TodoCategory.normalize(category ?? this.category),
      order: order ?? this.order,
    );
  }
}
