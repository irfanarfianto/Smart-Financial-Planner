import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_alert_dialog.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/financial_model_selector.dart';

class FinancialSettingsPage extends StatefulWidget {
  const FinancialSettingsPage({super.key});

  @override
  State<FinancialSettingsPage> createState() => _FinancialSettingsPageState();
}

class _FinancialSettingsPageState extends State<FinancialSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _fixedCostController = TextEditingController();
  int? _selectedModelId;
  bool _isInitialized = false;

  final List<Map<String, dynamic>> _models = [
    {
      'id': 1,
      'name': 'Growth Mode',
      'color': AppColors.growthGreen,
      'description': 'Fokus pertumbuhan agresif.',
    },
    {
      'id': 2,
      'name': 'Ambisius Builder',
      'color': AppColors.ambitiousNavy,
      'description': 'Membangun aset dengan ambisius.',
    },
    {
      'id': 3,
      'name': 'Regenerasi Finansial',
      'color': AppColors.regenerationOrange,
      'description': 'Memperbaiki kondisi keuangan.',
    },
  ];

  @override
  void dispose() {
    _fixedCostController.dispose();
    super.dispose();
  }

  void _initData(ProfileLoaded state) {
    if (!_isInitialized) {
      _fixedCostController.text = state.profile.fixedCostThreshold.toString();
      _selectedModelId = state.profile.activeModelId;
      _isInitialized = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fixedCost =
        double.tryParse(
          _fixedCostController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    final Map<String, dynamic> updates = {};
    updates['fixed_cost_threshold'] = fixedCost;
    updates['active_model_id'] = _selectedModelId;

    context.read<ProfileBloc>().add(UpdateProfileEvent(updates));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Keuangan',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) async {
          if (state is ProfileUpdateSuccess) {
            // Show result dialog if Model changed, or just Toast?
            // User likes dialog for model change.
            await AppAlertDialog.show(
              context,
              title: 'Berhasil',
              message:
                  'Pengaturan keuangan berhasil diperbarui. Alokasi baru akan diterapkan mulai pemasukan berikutnya.',
              positiveButtonText: 'Mengerti',
              icon: Icons.check_circle,
            );

            if (context.mounted) context.pop();
          } else if (state is ProfileError) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoaded) {
            _initData(state);
          }

          final isLoading = state is ProfileLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model Keuangan',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  FinancialModelSelector(
                    selectedModelId: _selectedModelId,
                    onModelSelected: (modelId) {
                      setState(() {
                        _selectedModelId = modelId;
                      });
                    },
                    models: _models,
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Safety Net',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Minimal biaya hidup per bulan untuk kebutuhan dasar',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _fixedCostController,
                    label: 'Fixed Cost Threshold',
                    prefixIcon: const Icon(Icons.shield),
                    hintText: 'Contoh: 2500000',
                    keyboardType: TextInputType.number,
                    prefixText: 'Rp ',
                    inputFormatters: [CurrencyInputFormatter()],
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 40),

                  AppButton(
                    text: 'Simpan Perubahan',
                    isLoading: isLoading,
                    onPressed: _save,
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
