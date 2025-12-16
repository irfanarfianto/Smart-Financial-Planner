import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_alert_dialog.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

class TransactionDetailSheet extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionDetailSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'INCOME';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              Center(
                child: Column(
                  children: [
                    Text(
                      isIncome ? 'Pemasukan' : 'Pengeluaran',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(transaction.amount),
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32, thickness: 1),

              // Details
              _DetailRow(
                label: 'Deskripsi',
                value: transaction.description ?? '-',
              ),
              _DetailRow(
                label: 'Tanggal',
                value: transaction.transactionDate != null
                    ? DateFormat(
                        'dd MMMM yyyy, HH:mm',
                        'id_ID',
                      ).format(transaction.transactionDate!)
                    : '-',
              ),
              if (!isIncome)
                _DetailRow(
                  label: 'Kategori',
                  value: transaction.category ?? '-',
                ),

              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDelete(context),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await context.push(
                          '/edit-transaction',
                          extra: {'transaction': transaction},
                        );
                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi berhasil diupdate'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Edit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    if (transaction.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID transaksi tidak valid')));
      return;
    }

    // Show confirmation dialog using AppAlertDialog
    final confirmed = await AppAlertDialog.show(
      context,
      title: 'Hapus Transaksi?',
      message: 'Transaksi yang sudah dihapus tidak dapat dikembalikan.',
      positiveButtonText: 'Hapus',
      negativeButtonText: 'Batal',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && context.mounted) {
      // Close detail sheet
      Navigator.pop(context);

      // Dispatch delete event
      context.read<TransactionBloc>().add(DeleteTransaction(transaction.id!));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
