import 'package:flutter/material.dart';
import '../../services/customers_service.dart';
import '../../widgets/app_ui.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<dynamic> customers = [];
  List<dynamic> filteredCustomers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    final data = await CustomersService().getCustomers();

    if (!mounted) return;

    setState(() {
      customers = data;
      filteredCustomers = data;
      isLoading = false;
    });
  }

  void searchCustomer(String query) {
    setState(() {
      filteredCustomers = customers.where((customer) {
        return customer['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> openAddCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );

    loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppShell(
        title: 'Customers',
        showBackButton: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      title: 'Customers',
      showBackButton: false,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
        onPressed: openAddCustomer,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              onChanged: searchCustomer,
              decoration: appInputDecoration(
                label: 'Search customers',
                icon: Icons.search,
              ),
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: customers.isEmpty
                        ? 'No customers yet'
                        : 'No matching customers',
                    message: customers.isEmpty
                        ? 'Create customers before adding receivables.'
                        : 'Try a different name or phone number.',
                    action: customers.isEmpty
                        ? AppPrimaryButton(
                            onPressed: openAddCustomer,
                            icon: Icons.person_add_alt_1,
                            label: 'Create Customer',
                          )
                        : null,
                  )
                : RefreshIndicator(
                    onRefresh: loadCustomers,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (_, index) {
                        final customer = filteredCustomers[index];
                        final business = customer['businessName'];

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              customer['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              business == null || business.toString().isEmpty
                                  ? customer['phone']
                                  : '${customer['phone']} - $business',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerDetailScreen(customer: customer),
                                ),
                              );

                              loadCustomers();
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
