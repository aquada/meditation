import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meditation/db.dart';
import 'package:meditation/session.dart';
import 'package:meditation/stats.dart';
import 'package:meditation/utils.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({Key? key}) : super(key: key);

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  late Future<List<Session>> sessionsFuture;

  @override
  void initState() {
    super.initState();
    sessionsFuture = DatabaseHelper.instance.getSessionsDesc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Column(
        children: [
          const StatsWidget(),
          Expanded(
            child: FutureBuilder<List<Session>>(
              future: sessionsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data!;
                if (sessions.isEmpty) {
                  return Center(
                    child: Text(
                      'No sessions yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) => _SessionTile(session: sessions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final started = session.started.toLocal();

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          session.completed ? Icons.check_circle_outline : Icons.pause_circle_outline,
          color: session.completed ? primaryColor : Colors.grey[500],
        ),
        title: Text(
          formatDuration(session.actualDuration),
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          DateFormat.yMMMd().add_jm().format(started),
          style: TextStyle(color: Colors.grey[500]),
        ),
        trailing: Text(
          session.completed ? 'completed' : 'stopped early',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        onTap: () => showDialog(
          context: context,
          builder: (context) => _SessionDetailsDialog(session: session),
        ),
      ),
    );
  }
}

class _SessionDetailsDialog extends StatelessWidget {
  final Session session;

  const _SessionDetailsDialog({required this.session});

  @override
  Widget build(BuildContext context) {
    final started = session.started.toLocal();

    return AlertDialog(
      title: const Text('Session details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Started: ${DateFormat.yMMMd().add_jms().format(started)}'),
          const SizedBox(height: 8),
          Text('Planned duration: ${formatDuration(session.plannedDuration)}'),
          Text('Actual duration: ${formatDuration(session.actualDuration)}'),
          const SizedBox(height: 8),
          Text(session.completed ? 'Completed' : 'Stopped early'),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
