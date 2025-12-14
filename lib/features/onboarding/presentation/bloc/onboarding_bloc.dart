import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_financial_models.dart';
import '../../domain/usecases/select_financial_model.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetFinancialModels getFinancialModels;
  final SelectFinancialModel selectFinancialModel;

  OnboardingBloc({
    required this.getFinancialModels,
    required this.selectFinancialModel,
  }) : super(OnboardingInitial()) {
    on<FetchFinancialModelsEvent>(_onFetchFinancialModels);
    on<SelectModelEvent>(_onSelectModel);
  }

  Future<void> _onFetchFinancialModels(
    FetchFinancialModelsEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    final result = await getFinancialModels(NoParams());
    result.fold(
      (failure) => emit(OnboardingError(failure.message)),
      (models) => emit(FinancialModelsLoaded(models)),
    );
  }

  Future<void> _onSelectModel(
    SelectModelEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    // Keep showing loading or previous state? Better to show loading overlay.
    // However, since we might need the models listed, we shouldn't wipe them from state unnecessarily.
    // But for now simplest is just loading.
    emit(OnboardingLoading());
    final result = await selectFinancialModel(
      SelectFinancialModelParams(modelId: event.modelId),
    );
    result.fold(
      (failure) => emit(OnboardingError(failure.message)),
      (_) => emit(OnboardingSuccess()),
    );
  }
}
