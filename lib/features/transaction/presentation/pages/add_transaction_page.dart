import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../../../dashboard/presentation/widgets/financial_health_widget.dart';
import '../widgets/transaction_type_selector.dart';
import '../widgets/category_dropdown.dart';
import '../widgets/transaction_date_picker.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'INCOME'; // INCOME, EXPENSE
  String? _selectedCategory; // NEEDS, INVEST, SAVING (For Expense)
  DateTime _selectedDate = DateTime.now();
  File? _receiptImage; // Store scanned receipt image
  // Store uploaded receipt URL

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    // Show bottom sheet to choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih Sumber Gambar', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 32),
              title: const Text('Kamera'),
              subtitle: const Text('Ambil foto struk sekarang'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 32),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih dari galeri foto'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    final ocrService = sl<OcrService>();
    final imageFile = source == ImageSource.camera
        ? await ocrService.pickImageFromCamera()
        : await ocrService.pickImageFromGallery();

    if (imageFile == null) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ocrService.processImage(imageFile);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      // Fill in the form with OCR results
      if (result.amount != null) {
        _amountController.text = result.amount!.toStringAsFixed(0);
      }
      if (result.date != null) {
        setState(() {
          _selectedDate = result.date!;
        });
      }
      if (result.merchantName != null) {
        _descriptionController.text = result.merchantName!;
      }

      // Store receipt image for upload
      setState(() {
        _receiptImage = imageFile;
      });

      AppToast.success(context, 'Struk berhasil dipindai!');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      AppToast.error(context, 'Gagal memindai struk: $e');
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == 'EXPENSE' && _selectedCategory == null) {
        AppToast.warning(context, 'Pilih kategori pengeluaran');
        return;
      }

      final amount = double.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      if (amount == null || amount <= 0) {
        return;
      }

      // Upload receipt if exists
      String? receiptUrl;
      if (_receiptImage != null) {
        try {
          // Show uploading indicator
          if (!mounted) return;
          AppToast.info(context, 'Mengupload struk...');

          final storageService = sl<StorageService>();
          receiptUrl = await storageService.uploadReceipt(_receiptImage!);

          setState(() {});
        } catch (e) {
          if (!mounted) return;
          AppToast.error(context, 'Gagal upload struk: $e');
          // Continue without receipt
        }
      }

      // Check purchase warning for NEEDS expenses
      if (_selectedType == 'EXPENSE' && _selectedCategory == 'NEEDS') {
        final walletBloc = context.read<WalletBloc>();
        if (walletBloc.state is WalletLoaded) {
          final needsWallet = (walletBloc.state as WalletLoaded).wallets
              .firstWhere(
                (w) => w.category == 'NEEDS',
                orElse: () => (walletBloc.state as WalletLoaded).wallets.first,
              );

          final warning = FinancialHealthWidget.getPurchaseWarning(
            needsWallet.currentBalance,
            amount,
          );

          if (warning != null) {
            // Show warning dialog
            final proceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('⚠️ Peringatan Keuangan'),
                content: Text(warning),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tetap Lanjutkan'),
                  ),
                ],
              ),
            );

            if (proceed != true) return;
          }
        }
      }

      final transaction = TransactionEntity(
        amount: amount,
        type: _selectedType,
        category: _selectedType == 'EXPENSE' ? _selectedCategory : null,
        description: _descriptionController.text,
        transactionDate: _selectedDate,
        receiptUrl: receiptUrl,
      );

      context.read<TransactionBloc>().add(CreateTransaction(transaction));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionBloc>(),
      child: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            AppToast.success(context, 'Transaksi berhasil disimpan!');
            context.pop(true); // Return result to refresh dashboard
          } else if (state is TransactionFailure) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Catat Transaksi',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 20),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _amountController,
                            label: 'Nominal',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 8, 16),
                              child: Text(
                                'Rp',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            inputFormatters: [CurrencyInputFormatter()],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: _scanReceipt,
                            tooltip: 'Scan Struk',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_selectedType == 'EXPENSE') ...[
                      CategoryDropdown(
                        selectedCategory: _selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Keterangan',
                      hintText: 'Contoh: Gaji Bulanan, Beli Kopi...',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tanggal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TransactionDatePicker(
                      selectedDate: _selectedDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    AppButton(
                      text: 'Simpan',
                      isLoading: state is TransactionLoading,
                      onPressed: () => _submit(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
