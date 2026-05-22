import 'package:flutter/material.dart';
import '../../services/notifications_service.dart';
import '../../widgets/app_ui.dart';

class ReminderHistoryScreen extends StatefulWidget {
  const ReminderHistoryScreen({super.key});

  @override
  State<ReminderHistoryScreen> createState() => _ReminderHistoryScreenState();
}

class _ReminderHistoryScreenState extends State<ReminderHistoryScreen> {
  List<dynamic> reminders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
    final data = await NotificationsService().getReminderHistory();

    if (!mounted) return;

    setState(() {
      reminders = data;
      isLoading = false;
    });
  }

  Color toneColor(String tone) {
    return tone == 'firm' ? AppColors.danger : AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppShell(
        title: 'Reminder History',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      title: 'Reminder History',
      body: reminders.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No reminders sent yet',
              message: 'WhatsApp reminder activity will appear here.',
            )
          : RefreshIndicator(
              onRefresh: loadReminders,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: reminders.length,
                itemBuilder: (_, index) {
                  final item = reminders[index];
                  final tone = item['tone'] ?? 'polite';
                  final customer =
                      item['receivable']?['customer']?['name'] ?? 'Customer';

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: toneColor(tone).withValues(alpha: 0.1),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: toneColor(tone),
                        ),
                      ),
                      title: Text(
                        customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Sent: ${item['sentAt'] ?? item['createdAt']}',
                      ),
                      trailing: StatusPill(
                        label: tone.toString().toUpperCase(),
                        color: toneColor(tone),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
