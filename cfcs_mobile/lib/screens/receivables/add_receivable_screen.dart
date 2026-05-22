import 'package:flutter/material.dart';
import '../../services/customers_service.dart';
import '../../services/receivables_service.dart';
import '../../widgets/app_ui.dart';
import '../customers/add_customer_screen.dart';

class AddReceivableScreen extends StatefulWidget {
  const AddReceivableScreen({super.key});

  @override
  State<AddReceivableScreen> createState() => _AddReceivableScreenState();
}

class _AddReceivableScreenState extends State<AddReceivableScreen> {
  List<dynamic> customers = [];
  dynamic selectedCustomer;

  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final customerController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    customerController.dispose();
    super.dispose();
  }

  Future<void> loadCustomers() async {
    final customerList = await CustomersService().getCustomers();

    if (!mounted) return;

    setState(() {
      customers = customerList;
      isLoading = false;
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> selectCustomer() async {
    final selected = await showSearch(
      context: context,
      delegate: CustomerSearchDelegate(customers),
    );

    if (selected != null) {
      setState(() {
        selectedCustomer = selected;
        customerController.text = selected['name'];
      });
    }
  }

  Future<void> saveReceivable() async {
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a customer')));
      return;
    }

    if (formKey.currentState?.validate() != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    setState(() {
      isSaving = true;
    });

    final success = await ReceivablesService().createReceivable(
      customerId: selectedCustomer['id'],
      description: descriptionController.text.trim(),
      totalAmount: amount,
      dueDate: selectedDate.toIso8601String().split('T')[0],
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create receivable')),
      );
    }
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppShell(
        title: 'Add Receivable',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppShell(
      title: 'Add Receivable',
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionTitle(
              title: 'Receivable Details',
              subtitle: 'Record an expected payment and its due date.',
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: selectCustomer,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: customerController,
                        validator: requiredField,
                        decoration: appInputDecoration(
                          label: 'Customer',
                          icon: Icons.person_search_outlined,
                          suffixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    validator: requiredField,
                    decoration: appInputDecoration(
                      label: 'Description',
                      icon: Icons.notes_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    validator: requiredField,
                    decoration: appInputDecoration(
                      label: 'Amount',
                      icon: Icons.currency_rupee,
                      prefixText: 'Rs. ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Due date'),
                      subtitle: Text(
                        selectedDate.toIso8601String().split('T')[0],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined),
                        onPressed: pickDate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                );

                if (result == true) {
                  if (!context.mounted) return;

                  final messenger = ScaffoldMessenger.of(context);
                  await loadCustomers();

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Customer added successfully'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add New Customer'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              onPressed: isSaving ? null : saveReceivable,
              icon: Icons.save_outlined,
              label: isSaving ? 'Saving' : 'Save Receivable',
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerSearchDelegate extends SearchDelegate<dynamic> {
  final List<dynamic> customers;

  CustomerSearchDelegate(this.customers);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = customers.where((customer) {
      return customer['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'No customers found',
        message: 'Add the customer first, then select them here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (_, index) {
        final customer = results[index];

        return AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(customer['name']),
            subtitle: Text(customer['phone']),
            onTap: () {
              close(context, customer);
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
