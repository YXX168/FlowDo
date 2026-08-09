import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/todo_ordering.dart';
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
  final TextEditingController _searchController = TextEditingController();

  List<Todo> _todos = [];
  String _currentFilter = 'all';
  String _selectedPriority = TodoPriority.medium;
  String _selectedCategory = TodoCategory.other;
  String? _editingId;
  String _searchQuery = '';
  bool _isSearchVisible = false;
  bool _isLoading = true;
  int _pendingSaves = 0;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _editController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _storage.loadTodos();
      if (!mounted) return;
      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    } on StorageException catch (error) {
      if (!mounted) return;
      setState(() {
        _storageError = error.message;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMessage(error.message);
      });
    } catch (_) {
      if (!mounted) return;
      const message = '无法初始化本地存储，请重新打开应用。';
      setState(() {
        _storageError = message;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMessage(message);
      });
    }
  }

  Future<void> _saveTodos() async {
    final snapshot = List<Todo>.unmodifiable(_todos);
    setState(() => _pendingSaves++);
    try {
      await _storage.saveTodos(snapshot);
      if (mounted && _storageError != null) {
        setState(() => _storageError = null);
      }
    } on StorageException catch (error) {
      if (!mounted) return;
      setState(() => _storageError = error.message);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      const message = '保存失败，请稍后重试。';
      setState(() => _storageError = message);
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _pendingSaves--);
    }
  }

  void _addTodo() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    setState(() {
      _todos = normalizeTodoOrder([
        Todo(
          id: now.microsecondsSinceEpoch.toString(),
          text: text,
          priority: _selectedPriority,
          category: _selectedCategory,
          createdAt: now.millisecondsSinceEpoch,
        ),
        ..._todos,
      ]);
      _inputController.clear();
      _selectedPriority = TodoPriority.medium;
      _selectedCategory = TodoCategory.other;
    });
    unawaited(_saveTodos());
  }

  void _toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;
    setState(() {
      final todo = _todos[index];
      _todos[index] = todo.copyWith(completed: !todo.completed);
    });
    unawaited(_saveTodos());
  }

  void _deleteTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;
    final removed = _todos[index];
    HapticFeedback.heavyImpact();
    setState(() {
      _todos = normalizeTodoOrder(
        _todos.where((todo) => todo.id != id),
      );
    });
    unawaited(_saveTodos());
    _showMessage(
      '已删除“${removed.text}”',
      action: SnackBarAction(
        label: '撤销',
        onPressed: () {
          final restored = List<Todo>.of(_todos);
          final insertAt = index > restored.length ? restored.length : index;
          restored.insert(insertAt, removed);
          setState(() => _todos = normalizeTodoOrder(restored));
          unawaited(_saveTodos());
        },
      ),
    );
  }

  void _startEdit(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;
    final todo = _todos[index];
    _editController.text = todo.text;
    setState(() => _editingId = id);
  }

  void _saveEdit() {
    if (_editingId == null) return;
    final text = _editController.text.trim();
    if (text.isEmpty) return;
    final index = _todos.indexWhere((todo) => todo.id == _editingId);
    if (index < 0) {
      _cancelEdit();
      return;
    }
    setState(() {
      _todos[index] = _todos[index].copyWith(text: text);
      _editingId = null;
    });
    _editController.clear();
    unawaited(_saveTodos());
  }

  void _cancelEdit() {
    setState(() => _editingId = null);
    _editController.clear();
  }

  void _clearCompleted() {
    final previousTodos = List<Todo>.of(_todos);
    final count = _doneCount;
    if (count == 0) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _todos = normalizeTodoOrder(
        _todos.where((todo) => !todo.completed),
      );
    });
    unawaited(_saveTodos());
    _showMessage(
      '已清除 $count 个已完成事项',
      action: SnackBarAction(
        label: '撤销',
        onPressed: () {
          setState(() => _todos = previousTodos);
          unawaited(_saveTodos());
        },
      ),
    );
  }

  void _reorderTodos(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      _todos = reorderVisibleTodos(
        allTodos: _todos,
        visibleTodos: _filteredTodos,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
    });
    unawaited(_saveTodos());
  }

  List<Todo> get _filteredTodos {
    List<Todo> result = List.from(_todos);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = _searchQuery.trim().toLowerCase();
      result = result
          .where((todo) => todo.text.toLowerCase().contains(normalizedQuery))
          .toList();
    }

    // Status filter
    if (_currentFilter == 'active') {
      result = result.where((t) => !t.completed).toList();
    } else if (_currentFilter == 'completed') {
      result = result.where((t) => t.completed).toList();
    }

    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildPageContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
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
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildProgressOverview(),
          const SizedBox(height: 12),
          _buildAddSection(),
          const SizedBox(height: 10),
          _buildFilterSection(),
          const SizedBox(height: 6),
          Expanded(child: _buildTodoList()),
        ],
      ),
    );
  }

  // ==================== Header ====================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showDate = constraints.maxWidth >= 330;
          return Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FlowDo',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '把今天理顺',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStorageStatus(),
              if (showDate) ...[
                _buildDateBadge(),
                const SizedBox(width: 8),
              ],
              _buildSearchToggle(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressOverview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xB31A1724),
        border: Border.all(color: const Color(0x12FFFFFF)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoRows = constraints.maxWidth < 320;
          final progressCount = Text(
            '$_doneCount / $_total',
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          );
          final stats = <Widget>[
            _buildCompactStat('待完成', _activeCount, AppTheme.statActive),
            const SizedBox(width: 14),
            _buildCompactStat('已完成', _doneCount, AppTheme.statDone),
          ];

          return Column(
            children: [
              Row(
                children: [
                  const Text(
                    '今日进度',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!useTwoRows) ...stats,
                  if (!useTwoRows) const SizedBox(width: 14),
                  progressCount,
                ],
              ),
              if (useTwoRows) ...[
                const SizedBox(height: 8),
                Row(children: stats),
              ],
              const SizedBox(height: 10),
              AnimatedProgressBar(progress: _progress),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactStat(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $value',
          style: const TextStyle(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageStatus() {
    if (_storageError != null) {
      return IconButton(
        onPressed: () => _showMessage(_storageError!),
        tooltip: '保存异常',
        visualDensity: VisualDensity.compact,
        icon: const Icon(
          Icons.cloud_off_rounded,
          size: 16,
          color: AppTheme.priorityHigh,
        ),
      );
    }
    if (_pendingSaves > 0) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Padding(
          padding: EdgeInsets.all(9),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.textQuaternary,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF221D2E),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x24FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentPurple.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/icon/flowdo-icon-foreground-v2.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchToggle() {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isSearchVisible = !_isSearchVisible;
          if (!_isSearchVisible) {
            _searchController.clear();
            _searchQuery = '';
          }
        });
      },
      tooltip: _isSearchVisible ? '关闭搜索' : '搜索待办事项',
      style: IconButton.styleFrom(
        backgroundColor: _isSearchVisible
            ? AppTheme.accent.withValues(alpha: 0.15)
            : const Color(0x0DFFFFFF),
        side: BorderSide(
          color: _isSearchVisible
              ? AppTheme.accent.withValues(alpha: 0.4)
              : const Color(0x14FFFFFF),
        ),
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(
        _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
        size: 19,
        color: _isSearchVisible ? AppTheme.accent : AppTheme.textSecondary,
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

  // ==================== Search Bar ====================
  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _isSearchVisible
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                border: Border.all(color: const Color(0x14FFFFFF)),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '搜索待办事项...',
                  hintStyle: TextStyle(
                    color: AppTheme.textQuaternary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(right: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppTheme.textQuaternary,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 42,
                    minHeight: 44,
                  ),
                  isDense: true,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ==================== Add Section ====================
  Widget _buildAddSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xCC181520),
        border: Border.all(color: const Color(0x18FFFFFF)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          if (_isSearchVisible) const SizedBox(height: 10),
          const Text(
            '添加待办',
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
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
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '写下一件要完成的事',
                      hintStyle: TextStyle(color: AppTheme.textQuaternary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
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
          const SizedBox(height: 8),
          // Category chips + submit button
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TodoCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AnimatedCategoryChip(
                          category: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GlassSubmitButton(onPressed: _addTodo),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== Filter Section ====================
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
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
            ),
          ),
          if (_doneCount > 0)
            IconButton(
              onPressed: _clearCompleted,
              tooltip: '清除已完成',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                size: 20,
                color: AppTheme.textQuaternary,
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

    return ReorderableListView.builder(
      key: ValueKey('${_currentFilter}_$_searchQuery'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      itemCount: filtered.length,
      buildDefaultDragHandles: false,
      onReorderItem: _reorderTodos,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final scale = 1.0 + animation.value * 0.025;
            return Transform.scale(
              scale: scale,
              child: Material(
                color: Colors.transparent,
                elevation: 6 * animation.value,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: child,
              ),
            );
          },
        );
      },
      itemBuilder: (context, index) {
        final todo = filtered[index];
        return Dismissible(
          key: ValueKey(todo.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.priorityHigh.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppTheme.priorityHigh,
              size: 24,
            ),
          ),
          onDismissed: (_) => _deleteTodo(todo.id),
          child: _buildTodoItem(todo, index, filtered.length),
        );
      },
    );
  }

  Widget _buildTodoItem(Todo todo, int index, int total) {
    final isEditing = _editingId == todo.id;
    final priorityColor = AppTheme.priorityColor(todo.priority);
    final catColor = AppTheme.categoryColor(todo.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: todo.completed
            ? const Color(0xB814121B)
            : const Color(0xE61A1724),
        border: Border.all(
          color: todo.completed
              ? const Color(0x0FFFFFFF)
              : const Color(0x1AFFFFFF),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: priorityColor.withValues(
                alpha: todo.completed ? 0.28 : 0.9,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 2, 12),
              child: _buildTodoContent(
                todo,
                isEditing,
                priorityColor,
                catColor,
              ),
            ),
          ),
          if (!isEditing) ...[
            AnimatedTodoCheckbox(
              checked: todo.completed,
              onChanged: (_) => _toggleTodo(todo.id),
              activeColor: priorityColor,
            ),
            if (total > 1)
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  button: true,
                  label: '拖动排序',
                  child: const SizedBox(
                    width: 36,
                    height: 48,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 18,
                      color: AppTheme.textQuaternary,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: IconButton(
                onPressed: () => _startEdit(todo.id),
                tooltip: '编辑',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodoContent(
    Todo todo,
    bool isEditing,
    Color priorityColor,
    Color catColor,
  ) {
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
          IconButton(
            onPressed: _saveEdit,
            tooltip: '保存',
            style: IconButton.styleFrom(
              backgroundColor:
                  AppTheme.priorityLow.withValues(alpha: 0.15),
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(
              Icons.check_rounded,
              size: 19,
              color: AppTheme.priorityLow,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _cancelEdit,
            tooltip: '取消',
            style: IconButton.styleFrom(
              backgroundColor:
                  AppTheme.priorityHigh.withValues(alpha: 0.15),
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: AppTheme.priorityHigh,
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
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: todo.completed
                ? AppTheme.textQuaternary
                : AppTheme.textPrimary,
            decoration: todo.completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: AppTheme.textQuaternary,
            decorationThickness: 2.0,
          ),
          child: Text(todo.text),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Time
            Text(
              _formatTime(todo.createdAt),
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                color: todo.completed
                    ? AppTheme.textQuaternary
                    : AppTheme.textSecondary,
              ),
            ),
            // Priority tag
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withValues(
                  alpha: todo.completed ? 0.08 : 0.18,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                AppTheme.priorityLabel(todo.priority),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: priorityColor.withValues(
                    alpha: todo.completed ? 0.4 : 1.0,
                  ),
                ),
              ),
            ),
            // Category tag
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: catColor.withValues(
                  alpha: todo.completed ? 0.08 : 0.15,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppTheme.categoryIcon(todo.category),
                    size: 10,
                    color: catColor.withValues(
                      alpha: todo.completed ? 0.4 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    AppTheme.categoryLabel(todo.category),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: catColor.withValues(
                        alpha: todo.completed ? 0.4 : 1.0,
                      ),
                    ),
                  ),
                ],
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
    if (_searchQuery.isNotEmpty) {
      title = '没有找到匹配的待办';
      desc = '试试其他关键词吧';
    } else if (_todos.isEmpty) {
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
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withValues(alpha: 0.08),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.task_alt_rounded,
              size: 32,
              color: AppTheme.accent.withValues(alpha: 0.4),
            ),
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
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${now.month}月${now.day}日  周${weekdays[now.weekday - 1]}';
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
