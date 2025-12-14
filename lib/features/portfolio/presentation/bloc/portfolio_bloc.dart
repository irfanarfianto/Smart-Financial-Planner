import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../onboarding/domain/usecases/get_financial_models.dart';
import '../../../onboarding/domain/usecases/select_financial_model.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final GetFinancialModels getFinancialModels;
  final SelectFinancialModel selectFinancialModel;

  PortfolioBloc({
    required this.getFinancialModels,
    required this.selectFinancialModel,
  }) : super(PortfolioInitial()) {
    on<FetchFinancialModels>(_onFetchModels);
    on<SelectModel>(_onSelectModel);
  }

  Future<void> _onFetchModels(
    FetchFinancialModels event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(PortfolioLoading());
    final result = await getFinancialModels(NoParams());
    result.fold(
      (failure) => emit(PortfolioError(failure.message)),
      (models) => emit(PortfolioLoaded(models)),
    );
  }

  Future<void> _onSelectModel(
    SelectModel event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(PortfolioSelectionLoading());

    final result = await selectFinancialModel(
      SelectFinancialModelParams(modelId: event.modelId),
    );

    result.fold(
      (failure) => emit(PortfolioError(failure.message)),
      (_) => emit(PortfolioSelectionSuccess()),
    );
  }
}
