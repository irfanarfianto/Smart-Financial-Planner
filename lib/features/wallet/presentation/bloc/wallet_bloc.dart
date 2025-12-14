import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_wallets.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWallets getWallets;

  WalletBloc({required this.getWallets}) : super(WalletInitial()) {
    on<FetchWallets>(_onFetchWallets);
  }

  Future<void> _onFetchWallets(
    FetchWallets event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    final result = await getWallets(NoParams());
    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (wallets) => emit(WalletLoaded(wallets)),
    );
  }
}
