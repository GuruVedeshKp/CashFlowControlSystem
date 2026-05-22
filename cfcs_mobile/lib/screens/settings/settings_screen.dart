import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final formKey = GlobalKey<FormState>();
  final businessController = TextEditingController();
  final ownerController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final gstController = TextEditingController();
  final upiController = TextEditingController();

  String reminderTone = 'polite';
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    businessController.dispose();
    ownerController.dispose();
    phoneController.dispose();
    addressController.dispose();
    gstController.dispose();
    upiController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final profile = await SettingsService().getBusinessProfile();

    if (profile != null) {
      businessController.text = profile['businessName'] ?? '';
      ownerController.text = profile['ownerName'] ?? '';
      phoneController.text = profile['phone'] ?? '';
      addressController.text = profile['address'] ?? '';
      gstController.text = profile['gstNumber'] ?? '';
      upiController.text = profile['upiId'] ?? '';
      reminderTone = profile['defaultReminderTone'] ?? 'polite';
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveProfile() async {
    if (formKey.currentState?.validate() != true) return;

    setState(() {
      isSaving = true;
    });

    final success = await SettingsService().saveBusinessProfile(
      businessName: businessController.text.trim(),
      ownerName: ownerController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      gstNumber: gstController.text.trim(),
      upiId: upiController.text.trim(),
      defaultReminderTone: reminderTone,
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Business settings saved' : 'Could not save settings',
        ),
      ),
    );
  }

  Future<void> logout() async {
    await AuthService().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17211B),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeaderCard(
                businessName: businessController.text,
                ownerName: ownerController.text,
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                icon: Icons.storefront,
                title: 'Business Profile',
                subtitle: 'Used on invoices, customer records, and reminders.',
                children: [
                  _AppTextField(
                    controller: businessController,
                    label: 'Business name',
                    icon: Icons.business,
                    validator: requiredField,
                    onChanged: (_) => setState(() {}),
                  ),
                  _AppTextField(
                    controller: ownerController,
                    label: 'Owner name',
                    icon: Icons.person,
                    validator: requiredField,
                    onChanged: (_) => setState(() {}),
                  ),
                  _AppTextField(
                    controller: phoneController,
                    label: 'Contact phone',
                    icon: Icons.call,
                    keyboardType: TextInputType.phone,
                    validator: requiredField,
                  ),
                  _AppTextField(
                    controller: addressController,
                    label: 'Business address',
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                icon: Icons.receipt_long,
                title: 'Billing Details',
                subtitle: 'Shown with receivables and payment follow-ups.',
                children: [
                  _AppTextField(
                    controller: gstController,
                    label: 'GST number',
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  _AppTextField(
                    controller: upiController,
                    label: 'UPI ID',
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                icon: Icons.notifications_active_outlined,
                title: 'Reminder Defaults',
                subtitle:
                    'Controls the first tone used for WhatsApp reminders.',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: reminderTone,
                    decoration: _fieldDecoration(
                      label: 'Default reminder tone',
                      icon: Icons.record_voice_over_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'polite', child: Text('Polite')),
                      DropdownMenuItem(value: 'firm', child: Text('Firm')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        reminderTone = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _TonePreview(tone: reminderTone),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isSaving ? null : saveProfile,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Saving' : 'Save Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: logout,
                icon: Icon(Icons.logout, color: colorScheme.error),
                label: Text(
                  'Logout',
                  style: TextStyle(color: colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String businessName;
  final String ownerName;

  const _HeaderCard({required this.businessName, required this.ownerName});

  @override
  Widget build(BuildContext context) {
    final displayName = businessName.trim().isEmpty
        ? 'Cash Flow Control System'
        : businessName.trim();
    final displayOwner = ownerName.trim().isEmpty
        ? 'Business account'
        : ownerName.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF163B25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayOwner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children.expand(
              (child) => [
                child,
                if (child != children.last) const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      decoration: _fieldDecoration(label: label, icon: icon),
    );
  }
}

class _TonePreview extends StatelessWidget {
  final String tone;

  const _TonePreview({required this.tone});

  @override
  Widget build(BuildContext context) {
    final isFirm = tone == 'firm';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFirm ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFirm ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFirm ? Icons.priority_high : Icons.check_circle_outline,
            color: isFirm ? Colors.orange.shade800 : Colors.green.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFirm
                  ? 'Firm reminders keep the message direct for overdue payments.'
                  : 'Polite reminders keep follow-ups friendly for regular customers.',
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.green.shade700, width: 1.4),
    ),
  );
}
