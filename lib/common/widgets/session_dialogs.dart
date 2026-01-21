import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/work_session.dart';
import '../../features/home/providers/time_tracking_provider.dart';

/// Shows a dialog to add a custom session
Future<void> showAddCustomSessionDialog(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSuccess,
}) async {
  DateTime selectedClockInDate = DateTime.now();
  DateTime selectedClockOutDate = DateTime.now();
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
              // Clock In Date & Time
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Clock In',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat('MMM d, y').format(selectedClockInDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedClockInDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => selectedClockInDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Time'),
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

              const Divider(),

              // Clock Out Date & Time
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Clock Out',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('Time'),
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
              if (selectedClockOut != null)
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('MMM d, y').format(selectedClockOutDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedClockOutDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => selectedClockOutDate = date);
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
                selectedClockInDate.year,
                selectedClockInDate.month,
                selectedClockInDate.day,
                selectedClockIn.hour,
                selectedClockIn.minute,
              );

              DateTime? clockOut;
              if (selectedClockOut != null) {
                clockOut = DateTime(
                  selectedClockOutDate.year,
                  selectedClockOutDate.month,
                  selectedClockOutDate.day,
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

              // Check if trying to create an active session (no clock out)
              if (clockOut == null) {
                final currentState = ref.read(timeTrackingProvider).value;
                if (currentState?.activeSession != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cannot create active session! An active session already exists. Please clock out first.',
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                  return;
                }
              }

              Navigator.pop(context);

              try {
                await ref
                    .read(timeTrackingProvider.notifier)
                    .createCustomSession(
                      date: selectedClockInDate,
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
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceAll('Exception: ', '')}',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
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
  DateTime clockInDate = session.date;
  DateTime clockOutDate = session.clockOut != null
      ? session.clockOut!
      : session.date; // Default to clock in date if active

  TimeOfDay clockIn = TimeOfDay.fromDateTime(session.clockIn);
  TimeOfDay? clockOut = session.clockOut != null
      ? TimeOfDay.fromDateTime(session.clockOut!)
      : null;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clock In
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Clock In',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM d, y').format(clockInDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: clockInDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => clockInDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Time'),
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

              const Divider(),

              // Clock Out
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Clock Out',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(clockOut?.format(context) ?? 'Active'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clockOut != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => clockOut = null),
                        tooltip: 'Clear (Active)',
                      ),
                    const Icon(Icons.access_time),
                  ],
                ),
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
              if (clockOut != null)
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('MMM d, y').format(clockOutDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: clockOutDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => clockOutDate = date);
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
              final updatedClockIn = DateTime(
                clockInDate.year,
                clockInDate.month,
                clockInDate.day,
                clockIn.hour,
                clockIn.minute,
              );

              DateTime? updatedClockOut;
              if (clockOut != null) {
                updatedClockOut = DateTime(
                  clockOutDate.year,
                  clockOutDate.month,
                  clockOutDate.day,
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
                date:
                    clockInDate, // Update the session date to match clock in date
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
