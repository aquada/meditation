import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:meditation/session.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _databaseName = 'sessions.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get _db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started INTEGER NOT NULL,
        planned_duration INTEGER NOT NULL,
        actual_duration INTEGER NOT NULL,
        completed INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertSession(Session session) async {
    final db = await _db;
    return db.insert('sessions', session.toMap());
  }

  Future<List<Session>> getSessionsDesc() async {
    final db = await _db;
    final rows = await db.query('sessions', orderBy: 'started DESC');
    return rows.map(Session.fromMap).toList();
  }

  Future<Duration> getTotalDuration() async {
    final db = await _db;
    final rows = await db.query('sessions', columns: ['actual_duration']);
    final totalMs = rows.fold<int>(0, (sum, row) => sum + (row['actual_duration'] as int));
    return Duration(milliseconds: totalMs);
  }

  // local calendar days (normalized into UTC-wrapped date-only DateTimes, so
  // subtracting/comparing days is never perturbed by DST shifts in the local
  // zone) that have >=1 completed session.
  Future<Set<DateTime>> _completedDays() async {
    final db = await _db;
    final rows = await db.query('sessions', columns: ['started'], where: 'completed = 1');
    return rows.map((row) {
      final startedUtc = DateTime.fromMillisecondsSinceEpoch(row['started'] as int, isUtc: true);
      final local = startedUtc.toLocal();
      return DateTime.utc(local.year, local.month, local.day);
    }).toSet();
  }

  // consecutive days with a completed session, walking back from today
  // (allowing today to still be empty without breaking a streak started
  // yesterday).
  Future<int> getStreakDays() async {
    final days = await _completedDays();
    if (days.isEmpty) {
      return 0;
    }

    final today = DateTime.now();
    var cursor = DateTime.utc(today.year, today.month, today.day);

    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) {
        return 0;
      }
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // longest run of consecutive days with a completed session, anywhere in
  // history (not necessarily ending today).
  Future<int> getBestStreak() async {
    final days = await _completedDays();
    if (days.isEmpty) {
      return 0;
    }

    final sortedDays = days.toList()..sort();

    var best = 1;
    var current = 1;
    for (var i = 1; i < sortedDays.length; i++) {
      if (sortedDays[i].difference(sortedDays[i - 1]).inDays == 1) {
        current++;
        if (current > best) {
          best = current;
        }
      } else {
        current = 1;
      }
    }
    return best;
  }
}
