class Todo {
  final String id;
  String text;
  bool completed;
  String priority; // 'high', 'medium', 'low'
  final int createdAt;
  int? dueDate; // timestamp, nullable
  String category; // 'work', 'personal', 'shopping', 'other'
  int order; // for drag-to-reorder

  Todo({
    required this.id,
    required this.text,
    this.completed = false,
    this.priority = 'medium',
    required this.createdAt,
    this.dueDate,
    this.category = 'other',
    this.order = 0,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      dueDate: json['dueDate'] as int?,
      category: json['category'] as String? ?? 'other',
      order: json['order'] as int? ?? 0,
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
    int? dueDate,
    String? category,
    int? order,
  }) {
    return Todo(
      id: id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      order: order ?? this.order,
    );
  }
}
