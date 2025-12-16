import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../bloc/add_transaction/add_transaction_bloc.dart';
import '../bloc/add_transaction/add_transaction_event.dart';
import '../bloc/add_transaction/add_transaction_state.dart';
import '../widgets/category_dropdown.dart';
import '../widgets/transaction_date_picker.dart';
import '../widgets/transaction_type_selector.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onScanReceipt(BuildContext context) {
    showModalBottomSheet<ImageSource>(
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
    ).then((source) {
      if (source != null && context.mounted) {
        context.read<AddTransactionBloc>().add(ScanReceiptRequested(source));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddTransactionBloc>(),
      child: BlocConsumer<AddTransactionBloc, AddTransactionState>(
        listenWhen: (previous, current) {
          return previous.status != current.status ||
              previous.amount != current.amount ||
              previous.description != current.description ||
              (previous.warningMessage != current.warningMessage &&
                  current.warningMessage != null);
        },
        listener: (context, state) {
          // Sync controllers with state (e.g. from OCR)
          if (state.amount.isNotEmpty &&
              _amountController.text.replaceAll(RegExp(r'[^0-9]'), '') !=
                  state.amount.replaceAll(RegExp(r'[^0-9]'), '')) {
            _amountController.text = state.amount;
          }
          if (state.description.isNotEmpty &&
              _descriptionController.text.isEmpty) {
            _descriptionController.text = state.description;
          }

          // Handle Status
          if (state.status == AddTransactionStatus.success) {
            AppToast.success(context, 'Transaksi berhasil disimpan!');
            context.pop(true);
          } else if (state.status == AddTransactionStatus.failure) {
            AppToast.error(context, state.errorMessage ?? 'Terjadi kesalahan');
          } else if (state.status == AddTransactionStatus.scanning) {
            AppToast.info(context, 'Memproses struk...');
          }

          // Handle Warning Dialog
          if (state.warningMessage != null) {
            showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('⚠️ Peringatan Keuangan'),
                content: Text(state.warningMessage!),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tetap Lanjutkan'),
                  ),
                ],
              ),
            ).then((proceed) {
              if (proceed == true && context.mounted) {
                final walletState = context.read<WalletBloc>().state;
                List<Wallet> wallets = [];
                if (walletState is WalletLoaded) {
                  wallets = walletState.wallets;
                }
                context.read<AddTransactionBloc>().add(
                  SubmitTransactionRequested(
                    wallets: wallets,
                    ignoreWarning: true,
                  ),
                );
              } else if (context.mounted) {
                context.read<AddTransactionBloc>().add(WarningDismissed());
              }
            });
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TransactionTypeSelector(
                    selectedType: state.type,
                    onTypeChanged: (type) {
                      context.read<AddTransactionBloc>().add(
                        TransactionTypeChanged(type),
                      );
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
                          onChanged: (value) {
                            context.read<AddTransactionBloc>().add(
                              TransactionAmountChanged(value),
                            );
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
                        child:
                            state.status == AddTransactionStatus.scanning ||
                                state.status == AddTransactionStatus.uploading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                onPressed: () => _onScanReceipt(context),
                                tooltip: 'Scan Struk',
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (state.type == 'EXPENSE') ...[
                    CategoryDropdown(
                      selectedCategory: state.category,
                      onChanged: (value) {
                        context.read<AddTransactionBloc>().add(
                          TransactionCategoryChanged(value),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Keterangan',
                    hintText: 'Contoh: Gaji Bulanan, Beli Kopi...',
                    onChanged: (value) {
                      context.read<AddTransactionBloc>().add(
                        TransactionDescriptionChanged(value),
                      );
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
                    selectedDate: state.date,
                    onDateChanged: (date) {
                      context.read<AddTransactionBloc>().add(
                        TransactionDateChanged(date),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  if (state.receiptImage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Struk terlampir',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                          Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  AppButton(
                    text: 'Simpan',
                    isLoading:
                        state.status == AddTransactionStatus.submitting ||
                        state.status == AddTransactionStatus.uploading,
                    onPressed: () {
                      final walletState = context.read<WalletBloc>().state;
                      List<Wallet> wallets = [];
                      if (walletState is WalletLoaded) {
                        wallets = walletState.wallets;
                      }
                      context.read<AddTransactionBloc>().add(
                        SubmitTransactionRequested(wallets: wallets),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
