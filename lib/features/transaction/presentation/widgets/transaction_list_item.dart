import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'INCOME';
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description ?? 'Tidak ada deskripsi',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              transaction.transactionDate != null
                  ? DateFormat(
                      'dd MMM yyyy, HH:mm',
                      'id_ID',
                    ).format(transaction.transactionDate!)
                  : 'Tanggal tidak tersedia',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            if (!isIncome && transaction.category != null) ...[
              const SizedBox(height: 2),
              Text(
                transaction.category!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transaction.amount)}',
          style: AppTextStyles.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
