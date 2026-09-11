// A completed or interrupted meditation session, as recorded in the log.
class Session {
  final int? id;

  // stored and read back as UTC; convert to local only for display
  final DateTime started;
  final Duration plannedDuration;
  final Duration actualDuration;
  final bool completed;

  Session({
    this.id,
    required this.started,
    required this.plannedDuration,
    required this.actualDuration,
    required this.completed,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'started': started.toUtc().millisecondsSinceEpoch,
      'planned_duration': plannedDuration.inMilliseconds,
      'actual_duration': actualDuration.inMilliseconds,
      'completed': completed ? 1 : 0,
    };
  }

  factory Session.fromMap(Map<String, Object?> map) {
    return Session(
      id: map['id'] as int?,
      started: DateTime.fromMillisecondsSinceEpoch(map['started'] as int, isUtc: true),
      plannedDuration: Duration(milliseconds: map['planned_duration'] as int),
      actualDuration: Duration(milliseconds: map['actual_duration'] as int),
      completed: (map['completed'] as int) == 1,
    );
  }
}
