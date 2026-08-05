class Todo {
  final String id;
  String text;
  bool completed;
  String priority; // 'high', 'medium', 'low'
  final int createdAt;

  Todo({
    required this.id,
    required this.text,
    this.completed = false,
    this.priority = 'medium',
    required this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
        'priority': priority,
        'createdAt': createdAt,
      };

  Todo copyWith({
    String? text,
    bool? completed,
    String? priority,
  }) {
    return Todo(
      id: id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt,
    );
  }
}
