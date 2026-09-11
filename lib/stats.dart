import 'package:flutter/material.dart';

import 'package:meditation/db.dart';
import 'package:meditation/utils.dart';

class StatsWidget extends StatefulWidget {
  const StatsWidget({Key? key}) : super(key: key);

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

class _StatsWidgetState extends State<StatsWidget> {
  late Future<(int, Duration)> statsFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = _loadStats();
  }

  Future<(int, Duration)> _loadStats() async {
    final streakDays = await DatabaseHelper.instance.getStreakDays();
    final totalDuration = await DatabaseHelper.instance.getTotalDuration();
    return (streakDays, totalDuration);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(int, Duration)>(
      future: statsFuture,
      builder: (context, snapshot) {
        final streakDays = snapshot.data?.$1 ?? 0;
        final totalDuration = snapshot.data?.$2 ?? Duration.zero;

        return Card(
          color: surfaceColor,
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  icon: Icons.local_fire_department_outlined,
                  value: '$streakDays',
                  label: 'day streak',
                ),
                _StatColumn(
                  icon: Icons.self_improvement_outlined,
                  value: formatHoursMinutes(totalDuration),
                  label: 'total meditated',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }
}
