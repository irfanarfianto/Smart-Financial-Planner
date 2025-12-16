import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../widgets/transaction_type_selector.dart';
import '../widgets/category_dropdown.dart';
import '../widgets/transaction_date_picker.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionEntity transaction;

  const EditTransactionPage({super.key, required this.transaction});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late String _selectedType;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize with existing transaction data
    _descriptionController.text = widget.transaction.description ?? '';
    // Format initial amount with currency formatter
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    _amountController.text = formatter.format(widget.transaction.amount).trim();
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.transactionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Validate category for EXPENSE
      if (_selectedType == 'EXPENSE' && _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
        );
        return;
      }

      // Parse formatted currency value
      final cleanAmount = _amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      final updatedTransaction = TransactionEntity(
        id: widget.transaction.id,
        userId: widget.transaction.userId,
        amount: double.parse(cleanAmount),
        type: _selectedType,
        category: _selectedCategory,
        description: _descriptionController.text,
        transactionDate: _selectedDate,
      );

      context.read<TransactionBloc>().add(
        UpdateTransaction(updatedTransaction),
      );
      context.pop(true); // Return true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _selectedType == 'INCOME';

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Edit Transaksi'),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selection
              TransactionTypeSelector(
                selectedType: _selectedType,
                onTypeChanged: (type) {
                  setState(() {
                    _selectedType = type;
                    if (type == 'INCOME') {
                      _selectedCategory = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              AppTextField(
                label: 'Nominal',
                controller: _amountController,
                hintText: '0',
                keyboardType: TextInputType.number,
                prefixText: 'Rp  ',
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah harus diisi';
                  }
                  // Parse formatted currency (remove dots/commas)
                  final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanValue.isEmpty ||
                      double.tryParse(cleanValue) == null) {
                    return 'Jumlah tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category (for EXPENSE only)
              if (!isIncome) ...[
                CategoryDropdown(
                  label: 'Kategori',
                  selectedCategory: _selectedCategory,
                  onChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Description
              AppTextField(
                label: 'Keterangan',
                controller: _descriptionController,
                hintText: 'Contoh: Gaji Bulanan, Beli Kopi...',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              Text('Tanggal', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TransactionDatePicker(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: AppButton(text: 'Simpan', onPressed: _handleSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
