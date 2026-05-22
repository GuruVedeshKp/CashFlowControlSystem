import 'package:flutter/material.dart';
import '../../services/customers_service.dart';
import '../../services/receivables_service.dart';
import '../../widgets/app_ui.dart';
import '../receivables/receivable_detail_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final dynamic customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<dynamic> receivables = [];
  bool isLoading = true;
  late Map<String, dynamic> customer;

  @override
  void initState() {
    super.initState();
    customer = Map<String, dynamic>.from(widget.customer);
    loadReceivables();
  }

  Future<void> loadReceivables() async {
    try {
      final data = await ReceivablesService().getReceivablesByCustomer(
        customer['id'],
      );

      if (!mounted) return;

      setState(() {
        receivables = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        receivables = [];
        isLoading = false;
      });
    }
  }

  double totalOf(String key) {
    return receivables.fold(
      0.0,
      (sum, item) => sum + double.parse(item[key].toString()),
    );
  }

  Widget buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReceivableCard(dynamic item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        title: Text(
          item['description'] ?? 'Receivable',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${money(item['totalAmount'])}'),
              Text('Paid: ${money(item['amountPaid'])}'),
              Text('Pending: ${money(item['balanceAmount'])}'),
              Text('Due: ${item['dueDate']}'),
            ],
          ),
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

  Future<void> editCustomerDialog() async {
    final nameController = TextEditingController(text: customer['name'] ?? '');
    final phoneController = TextEditingController(
      text: customer['phone'] ?? '',
    );
    final businessController = TextEditingController(
      text: customer['businessName'] ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: appInputDecoration(
                  label: 'Customer name',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: appInputDecoration(
                  label: 'Phone number',
                  icon: Icons.call_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: businessController,
                decoration: appInputDecoration(
                  label: 'Business name',
                  icon: Icons.business_outlined,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await CustomersService().updateCustomer(
      customerId: customer['id'],
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      businessName: businessController.text.trim().isEmpty
          ? null
          : businessController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        customer = {
          ...customer,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'businessName': businessController.text.trim(),
        };
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Customer updated')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update customer')),
      );
    }
  }

  Future<void> deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'This removes the customer from active records. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await CustomersService().deleteCustomer(customer['id']);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete customer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppShell(
        title: 'Customer Ledger',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      title: 'Customer Ledger',
      actions: [
        IconButton(
          tooltip: 'Edit customer',
          icon: const Icon(Icons.edit_outlined),
          onPressed: editCustomerDialog,
        ),
        IconButton(
          tooltip: 'Delete customer',
          icon: const Icon(Icons.delete_outline),
          color: AppColors.danger,
          onPressed: deleteCustomer,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: loadReceivables,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer['phone'],
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        if (customer['businessName'] != null)
                          Text(
                            customer['businessName'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                buildSummaryCard(
                  'Total',
                  money(totalOf('totalAmount')),
                  AppColors.info,
                ),
                const SizedBox(width: 8),
                buildSummaryCard(
                  'Paid',
                  money(totalOf('amountPaid')),
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                buildSummaryCard(
                  'Pending',
                  money(totalOf('balanceAmount')),
                  AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionTitle(
              title: 'Receivable History',
              subtitle: 'Complete ledger for this customer.',
            ),
            const SizedBox(height: 10),
            if (receivables.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No receivable history',
                message:
                    'Receivables added for this customer will appear here.',
              )
            else
              ...receivables.map(buildReceivableCard),
          ],
        ),
      ),
    );
  }
}
