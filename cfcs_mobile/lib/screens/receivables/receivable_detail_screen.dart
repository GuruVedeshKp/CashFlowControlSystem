import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/receivables_service.dart';
import '../../widgets/app_ui.dart';

class ReceivableDetailScreen extends StatefulWidget {
  final String receivableId;

  const ReceivableDetailScreen({super.key, required this.receivableId});

  @override
  State<ReceivableDetailScreen> createState() => _ReceivableDetailScreenState();
}

class _ReceivableDetailScreenState extends State<ReceivableDetailScreen> {
  Map<String, dynamic>? receivableData;
  List<dynamic> documents = [];
  List<dynamic> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    final results = await Future.wait([
      ReceivablesService().getReceivableDetails(widget.receivableId),
      ReceivablesService().getDocuments(widget.receivableId),
      ReceivablesService().getPaymentHistory(widget.receivableId),
    ]);

    if (!mounted) return;

    setState(() {
      receivableData = results[0] as Map<String, dynamic>?;
      documents = results[1] as List<dynamic>;
      payments = results[2] as List<dynamic>;
      isLoading = false;
    });
  }

  Future<void> sendReminderDialog() async {
    String selectedTone = 'polite';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Reminder'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'polite',
                        label: Text('Polite'),
                        icon: Icon(Icons.check_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'firm',
                        label: Text('Firm'),
                        icon: Icon(Icons.priority_high),
                      ),
                    ],
                    selected: {selectedTone},
                    onSelectionChanged: (values) {
                      setDialogState(() {
                        selectedTone = values.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedTone == 'firm'
                        ? 'Direct overdue payment message'
                        : 'Friendly follow-up message',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open WhatsApp'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final whatsAppUrl = await ReceivablesService().sendReminder(
      widget.receivableId,
      selectedTone,
    );

    if (whatsAppUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create reminder')),
      );
      return;
    }

    await launchUrl(
      Uri.parse(whatsAppUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> editDueDate() async {
    final parsedDate =
        DateTime.tryParse(receivableData!['dueDate'].toString()) ??
        DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: parsedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null) return;

    final success = await ReceivablesService().updateDueDate(
      widget.receivableId,
      pickedDate.toIso8601String().split('T')[0],
    );

    if (success) {
      await loadAllData();
    }
  }

  Future<void> uploadDocument() async {
    final result = await FilePicker.pickFiles();

    if (result == null) return;

    final success = await ReceivablesService().uploadDocument(
      widget.receivableId,
      File(result.files.single.path!),
    );

    if (success) {
      await loadAllData();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document uploaded')));
    }
  }

  Future<void> openDocument(String filePath) async {
    await launchUrl(
      Uri.parse(ApiService.uploadUrl(filePath)),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> deleteDocument(String documentId) async {
    final success = await ReceivablesService().deleteDocument(documentId);

    if (success) {
      await loadAllData();
    }
  }

  Future<void> recordPaymentDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: appInputDecoration(
                  label: 'Amount paid',
                  icon: Icons.payments_outlined,
                  prefixText: 'Rs. ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: appInputDecoration(
                  label: 'Note',
                  icon: Icons.notes_outlined,
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

    final amount = double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    final success = await ReceivablesService().markPaid(
      widget.receivableId,
      amount,
      DateTime.now().toIso8601String().split('T')[0],
      noteController.text.isEmpty ? null : noteController.text,
    );

    if (success) {
      await loadAllData();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment recorded')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment failed')));
    }
  }

  Future<void> editReceivableDialog() async {
    final data = receivableData!;
    final descriptionController = TextEditingController(
      text: data['description'] ?? '',
    );
    final amountController = TextEditingController(
      text: data['totalAmount'].toString(),
    );
    DateTime selectedDate =
        DateTime.tryParse(data['dueDate'].toString()) ?? DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Receivable'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descriptionController,
                    decoration: appInputDecoration(
                      label: 'Description',
                      icon: Icons.notes_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: appInputDecoration(
                      label: 'Total amount',
                      icon: Icons.currency_rupee,
                      prefixText: 'Rs. ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Due date'),
                    subtitle: Text(
                      selectedDate.toIso8601String().split('T')[0],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
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
      },
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    final success = await ReceivablesService().updateReceivable(
      receivableId: widget.receivableId,
      description: descriptionController.text.trim(),
      totalAmount: amount,
      dueDate: selectedDate.toIso8601String().split('T')[0],
    );

    if (!mounted) return;

    if (success) {
      await loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receivable updated')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update receivable')),
      );
    }
  }

  Future<void> deleteReceivable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receivable'),
        content: const Text(
          'This moves the receivable to history. You can restore it later.',
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

    final success = await ReceivablesService().deleteReceivable(
      widget.receivableId,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete receivable')),
      );
    }
  }

  Future<void> openInvoice() async {
    dynamic invoice;

    for (final doc in documents) {
      final name = (doc['fileName'] ?? '').toString().toLowerCase();
      final mime = (doc['mimeType'] ?? '').toString().toLowerCase();
      if (name.contains('invoice') || mime == 'application/pdf') {
        invoice = doc;
        break;
      }
    }

    if (invoice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No invoice found')));
      return;
    }

    await openDocument(invoice['filePath']);
  }

  Future<void> editPaymentDialog(dynamic payment) async {
    final amountController = TextEditingController(
      text: payment['amount'].toString(),
    );
    final noteController = TextEditingController(text: payment['note'] ?? '');
    DateTime selectedDate =
        DateTime.tryParse(payment['paymentDate'].toString()) ?? DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: appInputDecoration(
                      label: 'Amount paid',
                      icon: Icons.payments_outlined,
                      prefixText: 'Rs. ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: appInputDecoration(
                      label: 'Note',
                      icon: Icons.notes_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Payment date'),
                    subtitle: Text(
                      selectedDate.toIso8601String().split('T')[0],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
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
      },
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    final success = await ReceivablesService().updatePayment(
      paymentId: payment['id'],
      amount: amount,
      paymentDate: selectedDate.toIso8601String().split('T')[0],
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment updated')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not update payment')));
    }
  }

  Future<void> deletePayment(dynamic payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('This will recalculate the receivable balance.'),
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

    final success = await ReceivablesService().deletePayment(payment['id']);

    if (!mounted) return;

    if (success) {
      await loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment deleted')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete payment')));
    }
  }

  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppShell(
        title: 'Receivable Details',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = receivableData!;

    return AppShell(
      title: 'Receivable Details',
      actions: [
        IconButton(
          tooltip: 'Edit receivable',
          icon: const Icon(Icons.edit_outlined),
          onPressed: editReceivableDialog,
        ),
        IconButton(
          tooltip: 'Delete receivable',
          icon: const Icon(Icons.delete_outline),
          color: AppColors.danger,
          onPressed: deleteReceivable,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: loadAllData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['customer']?['name'] ?? 'Receivable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AmountBlock(
                          label: 'Total',
                          value: money(data['totalAmount']),
                        ),
                      ),
                      Expanded(
                        child: _AmountBlock(
                          label: 'Paid',
                          value: money(data['amountPaid']),
                        ),
                      ),
                      Expanded(
                        child: _AmountBlock(
                          label: 'Pending',
                          value: money(data['balanceAmount']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Due date'),
                subtitle: Text(data['dueDate']),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: editDueDate,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppPrimaryButton(
              onPressed: sendReminderDialog,
              icon: Icons.message_outlined,
              label: 'Send Reminder',
            ),
            const SizedBox(height: 10),
            buildActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Open Invoice',
              onPressed: openInvoice,
            ),
            const SizedBox(height: 10),
            buildActionButton(
              icon: Icons.payments_outlined,
              label: 'Record Payment',
              onPressed: recordPaymentDialog,
            ),
            const SizedBox(height: 10),
            buildActionButton(
              icon: Icons.upload_file_outlined,
              label: 'Upload Document',
              onPressed: uploadDocument,
            ),
            const SizedBox(height: 24),
            const SectionTitle(
              title: 'Payment History',
              subtitle: 'Recorded payments against this receivable.',
            ),
            const SizedBox(height: 10),
            if (payments.isEmpty)
              const AppCard(child: Text('No payments recorded yet'))
            else
              ...payments.map((payment) {
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      money(payment['amount']),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      payment['note'] == null
                          ? payment['paymentDate'].toString()
                          : '${payment['paymentDate']}\n${payment['note']}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          editPaymentDialog(payment);
                        } else if (value == 'delete') {
                          deletePayment(payment);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 14),
            const SectionTitle(
              title: 'Documents',
              subtitle: 'Invoices, bills, and supporting files.',
            ),
            const SizedBox(height: 10),
            if (documents.isEmpty)
              const AppCard(child: Text('No documents uploaded yet'))
            else
              ...documents.map((doc) {
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      doc['fileName'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => openDocument(doc['filePath']),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      onPressed: () => deleteDocument(doc['id']),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final String value;

  const _AmountBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
