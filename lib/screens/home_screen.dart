import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fluid_background.dart';
import '../widgets/animated_widgets.dart';

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
  String _currentFilter = 'all';
  String _selectedPriority = 'medium';
  String? _editingId;
  Timer? _saveTimer;
  bool _isLoading = true;

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
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
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
    HapticFeedback.mediumImpact();
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
    HapticFeedback.heavyImpact();
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
    HapticFeedback.mediumImpact();
    setState(() => _todos.removeWhere((t) => t.completed));
    _saveTodos();
  }

  List<Todo> get _filteredTodos {
    List<Todo> result;
    if (_currentFilter == 'active') {
      result = _todos.where((t) => !t.completed).toList();
    } else if (_currentFilter == 'completed') {
      result = _todos.where((t) => t.completed).toList();
    } else {
      result = List.from(_todos);
    }
    result.sort((a, b) {
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      final order = {'high': 0, 'medium': 1, 'low': 2};
      final cmp = (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
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
          const FluidBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildGlassPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPanel() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x8C14121B),
              border: Border.all(color: const Color(0x14FFFFFF)),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 40,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildAddSection(),
                _buildFilterSection(),
                Expanded(child: _buildTodoList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Header ====================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x0FFFFFFF), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Brand row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'FlowDo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              _buildDateBadge(),
            ],
          ),
          const SizedBox(height: 18),
          // Stats
          Row(
            children: [
              _buildStatItem('进行中', _activeCount, AppTheme.statActive),
              _buildDivider(),
              _buildStatItem('已完成', _doneCount, AppTheme.statDone),
              _buildDivider(),
              _buildStatItem('总计', _total, AppTheme.statTotal),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accent, Color(0xFFC934E1)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.water_drop_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Text(
        _formatDate(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0x0FFFFFFF),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, val, _) {
              return Text(
                '$val',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: const Color(0x0FFFFFFF),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.statDone),
          ),
        );
      },
    );
  }

  // ==================== Add Section ====================
  Widget _buildAddSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                border: Border.all(color: const Color(0x14FFFFFF)),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '输入待办事项...',
                        hintStyle: TextStyle(color: AppTheme.textQuaternary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                  AnimatedPrioritySelector(
                    selected: _selectedPriority,
                    onChanged: (p) => setState(() => _selectedPriority = p),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GlassSubmitButton(onPressed: _addTodo),
        ],
      ),
    );
  }

  // ==================== Filter Section ====================
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              children: [
                AnimatedFilterTab(
                  label: '全部',
                  count: _total,
                  isActive: _currentFilter == 'all',
                  onTap: () => setState(() => _currentFilter = 'all'),
                ),
                AnimatedFilterTab(
                  label: '进行中',
                  count: _activeCount,
                  isActive: _currentFilter == 'active',
                  onTap: () => setState(() => _currentFilter = 'active'),
                ),
                AnimatedFilterTab(
                  label: '已完成',
                  count: _doneCount,
                  isActive: _currentFilter == 'completed',
                  onTap: () => setState(() => _currentFilter = 'completed'),
                ),
              ],
            ),
          ),
          if (_doneCount > 0)
            GestureDetector(
              onTap: _clearCompleted,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '清除已完成',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textQuaternary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== Todo List ====================
  Widget _buildTodoList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 2,
        ),
      );
    }

    final filtered = _filteredTodos;

    if (filtered.isEmpty) {
      return Center(child: _buildEmptyState());
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: ListView.builder(
        key: ValueKey(_currentFilter),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildAnimatedTodoItem(filtered[index], index);
        },
      ),
    );
  }

  Widget _buildAnimatedTodoItem(Todo todo, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.priorityHigh.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: const Icon(Icons.delete_outline, color: AppTheme.priorityHigh, size: 24),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.heavyImpact();
          return true;
        },
        onDismissed: (direction) => _deleteTodo(todo.id),
        child: _buildTodoItem(todo),
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    final isEditing = _editingId == todo.id;
    final priorityColor = AppTheme.priorityColor(todo.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: todo.completed ? const Color(0x06FFFFFF) : const Color(0x0DFFFFFF),
        border: Border.all(
          color: todo.completed ? const Color(0x08FFFFFF) : const Color(0x12FFFFFF),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: todo.completed ? 0.3 : 1.0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMd),
                  bottomLeft: Radius.circular(AppTheme.radiusMd),
                ),
                boxShadow: todo.completed ? [] : [
                  BoxShadow(
                    color: priorityColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: _buildTodoContent(todo, isEditing, priorityColor),
              ),
            ),
            // Right actions
            if (!isEditing) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: AnimatedTodoCheckbox(
                  checked: todo.completed,
                  onChanged: (_) => _toggleTodo(todo.id),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _startEdit(todo.id),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteTodo(todo.id),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline, size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodoContent(Todo todo, bool isEditing, Color priorityColor) {
    if (isEditing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _editController,
              autofocus: true,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
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
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.priorityLow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check, size: 18, color: AppTheme.priorityLow),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _cancelEdit,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.priorityHigh.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, size: 18, color: AppTheme.priorityHigh),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: todo.completed ? AppTheme.textQuaternary : AppTheme.textPrimary,
            decoration: todo.completed ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: AppTheme.textQuaternary,
            decorationThickness: 2.0,
          ),
          child: Text(todo.text),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _formatTime(todo.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: todo.completed ? AppTheme.textQuaternary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: todo.completed ? 0.08 : 0.18),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                AppTheme.priorityLabel(todo.priority),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: priorityColor.withValues(alpha: todo.completed ? 0.4 : 1.0),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== Empty State ====================
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Icon(
            Icons.task_alt_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: const TextStyle(fontSize: 13, color: AppTheme.textQuaternary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================== Utils ====================
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
