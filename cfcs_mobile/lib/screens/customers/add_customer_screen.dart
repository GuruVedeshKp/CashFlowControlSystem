import 'package:flutter/material.dart';
import '../../services/customers_service.dart';
import '../../widgets/app_ui.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final businessController = TextEditingController();
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    businessController.dispose();
    super.dispose();
  }

  Future<void> saveCustomer() async {
    if (formKey.currentState?.validate() != true) return;

    setState(() {
      isSaving = true;
    });

    final success = await CustomersService().createCustomer(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      businessName: businessController.text.trim().isEmpty
          ? null
          : businessController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create customer')),
      );
    }
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Add Customer',
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionTitle(
              title: 'Customer Profile',
              subtitle: 'Create a contact used for receivables and reminders.',
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    validator: requiredField,
                    decoration: appInputDecoration(
                      label: 'Customer name',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: requiredField,
                    decoration: appInputDecoration(
                      label: 'Phone number',
                      icon: Icons.call_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: businessController,
                    decoration: appInputDecoration(
                      label: 'Business name',
                      icon: Icons.business_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              onPressed: isSaving ? null : saveCustomer,
              icon: Icons.save_outlined,
              label: isSaving ? 'Saving' : 'Save Customer',
            ),
          ],
        ),
      ),
    );
  }
}
