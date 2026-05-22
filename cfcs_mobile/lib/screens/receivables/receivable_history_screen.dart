import 'package:flutter/material.dart';
import '../../services/receivables_service.dart';
import '../../widgets/app_ui.dart';
import 'receivable_detail_screen.dart';

class ReceivableHistoryScreen extends StatefulWidget {
  const ReceivableHistoryScreen({super.key});

  @override
  State<ReceivableHistoryScreen> createState() =>
      _ReceivableHistoryScreenState();
}

class _ReceivableHistoryScreenState extends State<ReceivableHistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await ReceivablesService().getReceivableHistory();

    if (!mounted) return;

    setState(() {
      history = data;
      isLoading = false;
    });
  }

  Future<void> restoreReceivable(String id) async {
    final success = await ReceivablesService().restoreReceivable(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Receivable restored' : 'Restore failed'),
      ),
    );

    if (success) {
      loadHistory();
    }
  }

  Widget buildHistoryCard(dynamic item) {
    final customer = item['customer']?['name'] ?? 'Customer';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor(item['status']).withValues(alpha: 0.1),
          child: Icon(Icons.history, color: statusColor(item['status'])),
        ),
        title: Text(
          customer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${money(item['balanceAmount'])} due on ${item['dueDate']}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'restore') {
              restoreReceivable(item['id']);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'restore', child: Text('Restore')),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceivableDetailScreen(receivableId: item['id']),
            ),
          );

          loadHistory();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppShell(
        title: 'Receivable History',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      title: 'Receivable History',
      body: history.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No archived receivables',
              message: 'Paid or deleted receivables will appear here.',
            )
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: history.length,
                itemBuilder: (_, index) => buildHistoryCard(history[index]),
              ),
            ),
    );
  }
}
