// Generic undo/redo stack for reversible UI operations.
//
// Stores a bounded history of state snapshots. Each call to
// [push] records the current state before a mutation so the
// mutation can be undone. [undo] moves the cursor backwards;
// [redo] moves it forwards.
//
// T should be an immutable value type (record, const class, etc.)
// so snapshots are naturally independent of each other.

/// Generic undo/redo stack of up to [maxDepth] snapshots.
///
/// Usage pattern:
///   1. Before mutating state: call [push(currentState)].
///   2. Apply the mutation.
///   3. On undo: call [undo(currentState)] → returns prior state.
///   4. On redo: call [redo(currentState)] → returns next state.
class UndoRedoStack<T> {
  UndoRedoStack({this.maxDepth = 50});

  /// Maximum number of undo levels kept in memory.
  final int maxDepth;

  final List<T> _undoStack = [];
  final List<T> _redoStack = [];

  /// Whether there is at least one action to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there is at least one action to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Saves [currentState] as an undo checkpoint before mutating.
  ///
  /// Clears the redo stack because a new branch invalidates the
  /// previously undone future.
  void push(T currentState) {
    _undoStack.add(currentState);
    if (_undoStack.length > maxDepth) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Undoes the last mutation.
  ///
  /// Saves [currentState] onto the redo stack and returns the
  /// prior state. Returns null when there is nothing to undo.
  T? undo(T currentState) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(currentState);
    return _undoStack.removeLast();
  }

  /// Redoes the last undone mutation.
  ///
  /// Saves [currentState] onto the undo stack and returns the
  /// next state. Returns null when there is nothing to redo.
  T? redo(T currentState) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(currentState);
    return _redoStack.removeLast();
  }

  /// Clears all undo and redo history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
