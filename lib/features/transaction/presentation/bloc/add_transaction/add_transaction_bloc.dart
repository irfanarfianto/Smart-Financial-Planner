import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/services/ocr_service.dart';
import '../../../../../core/services/storage_service.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/add_transaction.dart';
import '../../../../dashboard/presentation/widgets/financial_health_widget.dart';
import '../../../../wallet/domain/entities/wallet.dart';
import 'add_transaction_event.dart';
import 'add_transaction_state.dart';

class AddTransactionBloc
    extends Bloc<AddTransactionEvent, AddTransactionState> {
  final AddTransaction addTransaction;
  final OcrService ocrService;
  final StorageService storageService;

  AddTransactionBloc({
    required this.addTransaction,
    required this.ocrService,
    required this.storageService,
  }) : super(AddTransactionState(date: DateTime.now())) {
    on<TransactionTypeChanged>(_onTypeChanged);
    on<TransactionAmountChanged>(_onAmountChanged);
    on<TransactionCategoryChanged>(_onCategoryChanged);
    on<TransactionDescriptionChanged>(_onDescriptionChanged);
    on<TransactionDateChanged>(_onDateChanged);
    on<ScanReceiptRequested>(_onScanReceipt);
    on<WarningDismissed>(
      (event, emit) => emit(state.copyWith(clearWarning: true)),
    );
    on<SubmitTransactionRequested>(_onSubmitTransaction);
  }

  void _onTypeChanged(
    TransactionTypeChanged event,
    Emitter<AddTransactionState> emit,
  ) {
    emit(
      state.copyWith(
        type: event.type,
        category: null, // Reset category when type changes
        clearCategory: true,
      ),
    );
  }

  void _onAmountChanged(
    TransactionAmountChanged event,
    Emitter<AddTransactionState> emit,
  ) {
    emit(state.copyWith(amount: event.amount));
  }

  void _onCategoryChanged(
    TransactionCategoryChanged event,
    Emitter<AddTransactionState> emit,
  ) {
    emit(state.copyWith(category: event.category));
  }

  void _onDescriptionChanged(
    TransactionDescriptionChanged event,
    Emitter<AddTransactionState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onDateChanged(
    TransactionDateChanged event,
    Emitter<AddTransactionState> emit,
  ) {
    emit(state.copyWith(date: event.date));
  }

  Future<void> _onScanReceipt(
    ScanReceiptRequested event,
    Emitter<AddTransactionState> emit,
  ) async {
    final imageFile = event.source == ImageSource.camera
        ? await ocrService.pickImageFromCamera()
        : await ocrService.pickImageFromGallery();

    if (imageFile == null) return;

    emit(
      state.copyWith(
        status: AddTransactionStatus.scanning,
        receiptImage: imageFile,
      ),
    );

    try {
      final result = await ocrService.processImage(imageFile);

      emit(
        state.copyWith(
          status: AddTransactionStatus.initial,
          // Only update fields if OCR found something
          amount: result.amount?.toStringAsFixed(0) ?? state.amount,
          description: result.merchantName ?? state.description,
          date: result.date ?? state.date,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AddTransactionStatus.failure,
          errorMessage: 'Gagal memindai struk: $e',
        ),
      );
      // Reset status to initial after error so user can try again
      emit(state.copyWith(status: AddTransactionStatus.initial));
    }
  }

  Future<void> _onSubmitTransaction(
    SubmitTransactionRequested event,
    Emitter<AddTransactionState> emit,
  ) async {
    // 1. Validation
    if (state.type == 'EXPENSE' && state.category == null) {
      emit(
        state.copyWith(
          status: AddTransactionStatus.failure,
          errorMessage: 'Pilih kategori pengeluaran',
        ),
      );
      emit(state.copyWith(status: AddTransactionStatus.initial));
      return;
    }

    final amountValue = double.tryParse(
      state.amount.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    if (amountValue == null || amountValue <= 0) {
      emit(
        state.copyWith(
          status: AddTransactionStatus.failure,
          errorMessage: 'Nominal tidak valid',
        ),
      );
      emit(state.copyWith(status: AddTransactionStatus.initial));
      return;
    }

    if (state.description.isEmpty) {
      emit(
        state.copyWith(
          status: AddTransactionStatus.failure,
          errorMessage: 'Keterangan wajib diisi',
        ),
      );
      emit(state.copyWith(status: AddTransactionStatus.initial));
      return;
    }

    // 2. Financial Health Check (Warning)
    if (!event.ignoreWarning &&
        state.type == 'EXPENSE' &&
        state.category == 'NEEDS') {
      // Safe wallet retrieval
      Wallet? needsWallet;
      try {
        needsWallet = event.wallets.firstWhere((w) => w.category == 'NEEDS');
      } catch (_) {
        if (event.wallets.isNotEmpty) {
          needsWallet = event.wallets.first;
        }
      }

      if (needsWallet != null) {
        final warning = FinancialHealthWidget.getPurchaseWarning(
          needsWallet.currentBalance,
          amountValue,
        );

        if (warning != null) {
          emit(state.copyWith(warningMessage: warning));
          return; // Stop and wait for user confirmation
        }
      }
    }

    // 3. Upload Receipt
    emit(
      state.copyWith(
        status: AddTransactionStatus.uploading,
        clearWarning: true,
      ),
    );

    String? receiptUrl;
    if (state.receiptImage != null) {
      try {
        receiptUrl = await storageService.uploadReceipt(state.receiptImage!);
      } catch (e) {
        emit(
          state.copyWith(
            status: AddTransactionStatus.failure,
            errorMessage: 'Gagal upload struk: $e',
          ),
        );
        emit(state.copyWith(status: AddTransactionStatus.initial));
        return;
      }
    }

    // 4. Submit Transaction
    emit(state.copyWith(status: AddTransactionStatus.submitting));

    final transaction = TransactionEntity(
      amount: amountValue,
      type: state.type,
      category: state.type == 'EXPENSE' ? state.category : null,
      description: state.description,
      transactionDate: state.date,
      receiptUrl: receiptUrl,
    );

    final result = await addTransaction(
      AddTransactionParams(transaction: transaction),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AddTransactionStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: AddTransactionStatus.success)),
    );
  }
}
