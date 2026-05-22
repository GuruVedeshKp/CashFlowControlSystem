import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../services/receivables_service.dart';
import '../../widgets/app_ui.dart';
import '../customers/add_customer_screen.dart';
import '../notifications/reminder_history_screen.dart';
import '../receivables/add_receivable_screen.dart';
import '../receivables/receivable_detail_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardData;
  List<dynamic> followUps = [];
  List<dynamic> upcomingReceivables = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      setState(() {
        isLoading = true;
      });

      final results = await Future.wait([
        DashboardService().getDashboardData(),
        ReceivablesService().getFollowUps(),
        ReceivablesService().getAllReceivables(),
      ]);

      final dashboard = results[0] as Map<String, dynamic>?;
      final followupList = results[1] as List<dynamic>;
      final allReceivables = results[2] as List<dynamic>;
      final today = DateTime.now();

      final upcoming = allReceivables.where((item) {
        final dueDate = DateTime.tryParse(item['dueDate']) ?? today;
        return item['status'] != 'PAID' && dueDate.isAfter(today);
      }).toList();

      upcoming.sort((a, b) {
        final aDate = DateTime.tryParse(a['dueDate']) ?? today;
        final bDate = DateTime.tryParse(b['dueDate']) ?? today;
        return aDate.compareTo(bDate);
      });

      if (!mounted) return;

      setState(() {
        dashboardData = dashboard;
        followUps = followupList;
        upcomingReceivables = upcoming.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        dashboardData = _emptyDashboard;
        followUps = [];
        upcomingReceivables = [];
        isLoading = false;
      });
    }
  }

  Map<String, dynamic> get _emptyDashboard => {
    'totalReceivable': 0,
    'overdueAmount': 0,
    'dueTodayAmount': 0,
    'expectedThisWeekAmount': 0,
  };

  Widget buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget buildReceivableCard(dynamic item) {
    final customerName =
        item['customerName'] ?? item['customer']?['name'] ?? 'Customer';
    final amount = item['balanceAmount'] ?? item['amount'] ?? 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person_outline, color: AppColors.primary),
        ),
        title: Text(
          customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${money(amount)} due on ${item['dueDate']}'),
        trailing: item['overdueDays'] != null
            ? StatusPill(
                label: '${item['overdueDays']}d',
                color: AppColors.danger,
              )
            : const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceivableDetailScreen(receivableId: item['id']),
            ),
          );

          loadDashboard();
        },
      ),
    );
  }

  Widget buildEmptyState() {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No receivables yet',
      message: 'Add customers and receivables to start tracking expected cash.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPrimaryButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
              );

              if (!mounted) return;
              loadDashboard();
            },
            icon: Icons.person_add_alt_1,
            label: 'Add Customer',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddReceivableScreen()),
              );

              if (!mounted) return;
              loadDashboard();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Receivable'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeDashboard = dashboardData ?? _emptyDashboard;

    if (isLoading) {
      return const AppShell(
        title: 'Dashboard',
        showBackButton: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasNoData =
        safeDashboard['totalReceivable'] == 0 &&
        followUps.isEmpty &&
        upcomingReceivables.isEmpty;

    return AppShell(
      title: 'Dashboard',
      showBackButton: false,
      actions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );

            if (!mounted) return;
            loadDashboard();
          },
        ),
        IconButton(
          tooltip: 'Reminder history',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderHistoryScreen()),
            );
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Due'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReceivableScreen()),
          );

          if (!mounted) return;

          if (result == true) {
            loadDashboard();
          }
        },
      ),
      body: hasNoData
          ? buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash Flow Control System',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Monitor receivables, overdue dues, and today\'s follow-ups.',
                          style: TextStyle(color: Colors.white70, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      buildMetricCard(
                        'Total Receivable',
                        money(safeDashboard['totalReceivable']),
                        Icons.account_balance_wallet_outlined,
                        AppColors.info,
                      ),
                      buildMetricCard(
                        'Overdue',
                        money(safeDashboard['overdueAmount']),
                        Icons.warning_amber_outlined,
                        AppColors.danger,
                      ),
                      buildMetricCard(
                        'Due Today',
                        money(safeDashboard['dueTodayAmount']),
                        Icons.today_outlined,
                        AppColors.warning,
                      ),
                      buildMetricCard(
                        'This Week',
                        money(safeDashboard['expectedThisWeekAmount']),
                        Icons.calendar_month_outlined,
                        AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle(
                    title: 'Follow-up Today',
                    subtitle: 'Receivables that need attention now.',
                  ),
                  const SizedBox(height: 10),
                  if (followUps.isEmpty)
                    const AppCard(child: Text('No follow-ups today'))
                  else
                    ...followUps.map(buildReceivableCard),
                  const SizedBox(height: 22),
                  const SectionTitle(
                    title: 'Upcoming',
                    subtitle: 'Nearest unpaid receivables by due date.',
                  ),
                  const SizedBox(height: 10),
                  if (upcomingReceivables.isEmpty)
                    const AppCard(child: Text('No upcoming receivables'))
                  else
                    ...upcomingReceivables.map(buildReceivableCard),
                ],
              ),
            ),
    );
  }
}
