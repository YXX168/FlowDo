import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fluid_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  List<Todo> _todos = [];
  String _currentFilter = 'all'; // all, active, completed
  String _selectedPriority = 'medium';
  String? _editingId;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _editController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final todos = await _storage.loadTodos();
    setState(() => _todos = todos);
  }

  void _saveTodos() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      _storage.saveTodos(_todos);
    });
  }

  void _addTodo() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _todos.insert(0, Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        priority: _selectedPriority,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _inputController.clear();
      _selectedPriority = 'medium';
    });
    _saveTodos();
  }

  void _toggleTodo(String id) {
    setState(() {
      final todo = _todos.firstWhere((t) => t.id == id);
      todo.completed = !todo.completed;
    });
    _saveTodos();
  }

  void _deleteTodo(String id) {
    setState(() => _todos.removeWhere((t) => t.id == id));
    _saveTodos();
  }

  void _startEdit(String id) {
    final todo = _todos.firstWhere((t) => t.id == id);
    _editController.text = todo.text;
    setState(() => _editingId = id);
  }

  void _saveEdit() {
    if (_editingId == null) return;
    final text = _editController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final todo = _todos.firstWhere((t) => t.id == _editingId);
      todo.text = text;
      _editingId = null;
    });
    _editController.clear();
    _saveTodos();
  }

  void _cancelEdit() {
    setState(() => _editingId = null);
    _editController.clear();
  }

  void _clearCompleted() {
    setState(() => _todos.removeWhere((t) => t.completed));
    _saveTodos();
  }

  List<Todo> get _filteredTodos {
    if (_currentFilter == 'active') return _todos.where((t) => !t.completed).toList();
    if (_currentFilter == 'completed') return _todos.where((t) => t.completed).toList();
    return List.from(_todos);
  }

  int get _total => _todos.length;
  int get _doneCount => _todos.where((t) => t.completed).length;
  int get _activeCount => _total - _doneCount;
  double get _progress => _total > 0 ? _doneCount / _total : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fluid background
          const FluidBackground(),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: _buildGlassPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          decoration: BoxDecoration(
            color: AppTheme.glassBg,
            border: Border.all(color: AppTheme.glassBorder),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildAddSection(),
              _buildFilterSection(),
              _buildTodoList(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x0FFFFFFF), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.accent, Color(0xFFC934E1)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4DF62C55),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'FlowDo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Text(
                  _formatDate(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('进行中', _activeCount, AppTheme.statActive),
              _buildStatItem('已完成', _doneCount, AppTheme.statDone),
              _buildStatItem('总计', _total, AppTheme.statTotal),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 4,
              backgroundColor: const Color(0x0FFFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.statDone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                border: Border.all(color: AppTheme.inputBorder),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '添加待办事项...',
                        hintStyle: TextStyle(color: AppTheme.textQuaternary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                  // Priority selector
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(
                      children: ['high', 'medium', 'low'].map((p) {
                        final color = AppTheme.priorityColor(p);
                        final isActive = _selectedPriority == p;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPriority = p),
                          child: Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: color,
                                width: 2,
                              ),
                              boxShadow: isActive
                                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _addTodo,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = [
      ('all', '全部', _total),
      ('active', '进行中', _activeCount),
      ('completed', '已完成', _doneCount),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              children: filters.map((f) {
                final isActive = _currentFilter == f.$1;
                return GestureDetector(
                  onTap: () => setState(() => _currentFilter = f.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0x1FFFFFFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          f.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${f.$3}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? AppTheme.textSecondary
                                : AppTheme.textQuaternary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_doneCount > 0)
            GestureDetector(
              onTap: _clearCompleted,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '清除已完成',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textQuaternary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    final filtered = _filteredTodos;
    // Sort: incomplete first, then by priority, then by createdAt desc
    filtered.sort((a, b) {
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      final order = {'high': 0, 'medium': 1, 'low': 2};
      final cmp = (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildTodoItem(filtered[index]),
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    final isEditing = _editingId == todo.id;
    final priorityColor = AppTheme.priorityColor(todo.priority);

    return Container(
      decoration: BoxDecoration(
        color: todo.completed
            ? const Color(0x06FFFFFF)
            : AppTheme.itemBg,
        border: Border.all(color: AppTheme.itemBorder),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: priorityColor.withValues(
                  alpha: todo.completed ? 0.4 : 1.0,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMd),
                  bottomLeft: Radius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editController,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _saveEdit(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _saveEdit,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.check, size: 18, color: AppTheme.priorityLow),
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelEdit,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 18, color: AppTheme.priorityHigh),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Todo text
                      Text(
                        todo.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: todo.completed
                              ? AppTheme.textQuaternary
                              : AppTheme.textPrimary,
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Meta info
                      Row(
                        children: [
                          Text(
                            _formatTime(todo.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: todo.completed
                                  ? AppTheme.textQuaternary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppTheme.priorityLabel(todo.priority),
                              style: TextStyle(
                                fontSize: 10,
                                color: priorityColor.withValues(
                                  alpha: todo.completed ? 0.4 : 1.0,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Checkbox
            if (!isEditing)
              GestureDetector(
                onTap: () => _toggleTodo(todo.id),
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 14, right: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: todo.completed
                          ? AppTheme.priorityLow
                          : const Color(0x33FFFFFF),
                      width: 2,
                    ),
                    color: todo.completed
                        ? AppTheme.priorityLow
                        : Colors.transparent,
                  ),
                  child: todo.completed
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            // Action buttons
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _startEdit(todo.id),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteTodo(todo.id),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline, size: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title, desc;
    if (_todos.isEmpty) {
      title = '还没有待办事项';
      desc = '在上方输入框中添加你的第一个待办事项吧';
    } else if (_currentFilter == 'active') {
      title = '没有进行中的事项';
      desc = '所有待办都已完成，干得漂亮！';
    } else {
      title = '没有已完成的事项';
      desc = '完成一些待办后将会显示在这里';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textQuaternary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}
