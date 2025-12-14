import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_financial_planner/features/portfolio/presentation/bloc/portfolio_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_state.dart';
import '../widgets/financial_model_card.dart';

class PortfolioSelectionPage extends StatefulWidget {
  const PortfolioSelectionPage({super.key});

  @override
  State<PortfolioSelectionPage> createState() => _PortfolioSelectionPageState();
}

class _PortfolioSelectionPageState extends State<PortfolioSelectionPage> {
  int? _selectedModelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PortfolioBloc>()..add(FetchFinancialModels()),
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Light background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Pilih Persona Keuangan',
            style: AppTextStyles.headlineMedium,
          ),
        ),
        body: BlocConsumer<PortfolioBloc, PortfolioState>(
          listener: (context, state) {
            if (state is PortfolioSelectionSuccess) {
              // Navigate to Dashboard
              context.go('/dashboard');
            } else if (state is PortfolioError) {
              AppToast.error(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is PortfolioLoading && state is! PortfolioLoaded) {
              return const AppLoading();
            } else if (state is PortfolioLoaded) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Tentukan cara mainmu.',
                      style: AppTextStyles.displaySmall.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih satu dari tiga strategi alokasi yang paling cocok dengan tujuanmu saat ini.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.models.length,
                        itemBuilder: (context, index) {
                          final model = state.models[index];
                          return FinancialModelCard(
                            model: model,
                            isSelected: _selectedModelId == model.id,
                            onTap: () {
                              setState(() {
                                _selectedModelId = model.id;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Terapkan Strategi',
                      onPressed: _selectedModelId != null
                          ? () {
                              context.read<PortfolioBloc>().add(
                                SelectModel(_selectedModelId!),
                              );
                            }
                          : null, // Disable if none selected
                      color: _selectedModelId != null
                          ? AppColors.ambitiousNavy
                          : Colors.grey,
                      isLoading: state is PortfolioSelectionLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            } else if (state is PortfolioError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
