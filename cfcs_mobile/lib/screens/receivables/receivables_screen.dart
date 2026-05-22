import 'package:flutter/material.dart';
import '../../services/receivables_service.dart';
import '../../widgets/app_ui.dart';
import 'receivable_history_screen.dart';
import 'receivable_detail_screen.dart';

class ReceivablesScreen extends StatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  State<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends State<ReceivablesScreen> {
  List<dynamic> allReceivables = [];
  List<dynamic> filteredReceivables = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  final filters = const ['All', 'PENDING', 'OVERDUE', 'PARTIALLY_PAID', 'PAID'];

  @override
  void initState() {
    super.initState();
    loadReceivables();
  }

  Future<void> loadReceivables() async {
    final data = await ReceivablesService().getAllReceivables();

    if (!mounted) return;

    setState(() {
      allReceivables = data;
      isLoading = false;
    });

    applyFilter(selectedFilter);
  }

  void applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;

      if (filter == 'All') {
        filteredReceivables = allReceivables;
      } else {
        filteredReceivables = allReceivables.where((item) {
          return item['status'] == filter;
        }).toList();
      }
    });
  }

  String filterLabel(String filter) {
    return filter == 'All' ? filter : filter.replaceAll('_', ' ');
  }

  Widget buildReceivableCard(dynamic item) {
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
          child: Icon(
            Icons.receipt_long_outlined,
            color: statusColor(item['status']),
          ),
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
        trailing: StatusPill(
          label: item['status'],
          color: statusColor(item['status']),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceivableDetailScreen(receivableId: item['id']),
            ),
          );

          loadReceivables();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppShell(
        title: 'Receivables',
        showBackButton: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      title: 'Receivables',
      showBackButton: false,
      actions: [
        IconButton(
          tooltip: 'History',
          icon: const Icon(Icons.history),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReceivableHistoryScreen(),
              ),
            );

            loadReceivables();
          },
        ),
      ],
      body: Column(
        children: [
          SizedBox(
            height: 62,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              children: filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filterLabel(filter)),
                    selected: selectedFilter == filter,
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    checkmarkColor: AppColors.primary,
                    onSelected: (_) => applyFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filteredReceivables.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: allReceivables.isEmpty
                        ? 'No receivables yet'
                        : 'No receivables in this status',
                    message: allReceivables.isEmpty
                        ? 'Create a receivable from the dashboard to start tracking dues.'
                        : 'Change the filter to view other receivables.',
                  )
                : RefreshIndicator(
                    onRefresh: loadReceivables,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filteredReceivables.length,
                      itemBuilder: (_, index) {
                        return buildReceivableCard(filteredReceivables[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
