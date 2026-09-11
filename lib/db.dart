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

  // consecutive days (walking back from today, allowing today to still be
  // empty without breaking a streak started yesterday) with >=1 completed
  // session. dates are compared as local calendar days, normalized into a
  // UTC-wrapped date-only DateTime so subtracting a day is never perturbed
  // by DST shifts in the local zone.
  Future<int> getStreakDays() async {
    final db = await _db;
    final rows = await db.query('sessions', columns: ['started'], where: 'completed = 1');
    if (rows.isEmpty) {
      return 0;
    }

    final days = rows.map((row) {
      final startedUtc = DateTime.fromMillisecondsSinceEpoch(row['started'] as int, isUtc: true);
      final local = startedUtc.toLocal();
      return DateTime.utc(local.year, local.month, local.day);
    }).toSet();

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
}
