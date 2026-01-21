import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/work_session.dart';
import '../providers/time_tracking_provider.dart';

/// Shows a dialog to add a custom session
Future<void> showAddCustomSessionDialog(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSuccess,
}) async {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedClockIn = TimeOfDay.now();
  TimeOfDay? selectedClockOut; // Null by default

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add Custom Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM d, y').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Clock In'),
                subtitle: Text(selectedClockIn.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedClockIn,
                  );
                  if (time != null) {
                    setState(() => selectedClockIn = time);
                  }
                },
              ),
              ListTile(
                title: const Text('Clock Out'),
                subtitle: Text(
                  selectedClockOut?.format(context) ?? 'In Progress',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedClockOut != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            setState(() => selectedClockOut = null),
                        tooltip: 'Clear (In Progress)',
                      ),
                    const Icon(Icons.access_time),
                  ],
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedClockOut ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => selectedClockOut = time);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final clockIn = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedClockIn.hour,
                selectedClockIn.minute,
              );

              DateTime? clockOut;
              if (selectedClockOut != null) {
                clockOut = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedClockOut!.hour,
                  selectedClockOut!.minute,
                );

                if (clockOut.isBefore(clockIn)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clock out must be after clock in!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }

              Navigator.pop(context);

              await ref
                  .read(timeTrackingProvider.notifier)
                  .createCustomSession(
                    date: selectedDate,
                    clockIn: clockIn,
                    clockOut: clockOut,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      clockOut == null
                          ? 'Active session started!'
                          : 'Custom session added!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              onSuccess?.call();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}

/// Shows a dialog to edit an existing session
Future<void> showEditSessionDialog(
  BuildContext context,
  WidgetRef ref,
  WorkSession session, {
  VoidCallback? onSuccess,
}) async {
  TimeOfDay clockIn = TimeOfDay.fromDateTime(session.clockIn);
  TimeOfDay? clockOut = session.clockOut != null
      ? TimeOfDay.fromDateTime(session.clockOut!)
      : null;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Clock In'),
              subtitle: Text(clockIn.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: clockIn,
                );
                if (time != null) {
                  setState(() => clockIn = time);
                }
              },
            ),
            ListTile(
              title: const Text('Clock Out'),
              subtitle: Text(clockOut?.format(context) ?? 'Active'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: clockOut ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => clockOut = time);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedClockIn = DateTime(
                session.date.year,
                session.date.month,
                session.date.day,
                clockIn.hour,
                clockIn.minute,
              );

              DateTime? updatedClockOut;
              if (clockOut != null) {
                updatedClockOut = DateTime(
                  session.date.year,
                  session.date.month,
                  session.date.day,
                  clockOut!.hour,
                  clockOut!.minute,
                );

                if (updatedClockOut.isBefore(updatedClockIn)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clock out must be after clock in!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }

              final updatedSession = WorkSession(
                id: session.id,
                date: session.date,
                clockIn: updatedClockIn,
                clockOut: updatedClockOut,
              );

              Navigator.pop(context);

              await ref
                  .read(timeTrackingProvider.notifier)
                  .updateSession(updatedSession);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              onSuccess?.call();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

/// Shows a confirmation dialog to delete a session
Future<bool> showDeleteSessionDialog(
  BuildContext context,
  WidgetRef ref,
  WorkSession session, {
  VoidCallback? onSuccess,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Session'),
      content: const Text('Are you sure you want to delete this session?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref.read(timeTrackingProvider.notifier).deleteSession(session.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session deleted!'),
          backgroundColor: Colors.red,
        ),
      );
    }

    onSuccess?.call();
    return true;
  }

  return false;
}
