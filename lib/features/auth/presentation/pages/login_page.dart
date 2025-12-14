import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // For register

  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                // Navigate to root which will redirect to dashboard/onboarding
                context.go('/');
              } else if (state is AuthFailureState) {
                AppToast.error(context, state.message);
              }
            },
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or Title
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 64,
                        color: AppColors.ambitiousNavy,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Smart Financial Planner',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: AppTextStyles.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Form
                      if (!_isLogin) ...[
                        AppTextField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          label: 'Nama Lengkap',
                        ),
                        const SizedBox(height: 16),
                      ],

                      AppTextField(
                        controller: _emailController,
                        hintText: 'email@example.com',
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        hintText: '********',
                        label: 'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      AppButton(
                        text: _isLogin ? 'Login' : 'Daftar',
                        isLoading: state is AuthLoading,
                        onPressed: () {
                          final email = _emailController.text;
                          final password = _passwordController.text;

                          if (email.isEmpty || password.isEmpty) {
                            AppToast.warning(context, 'Mohon isi semua data');
                            return;
                          }

                          if (_isLogin) {
                            context.read<AuthBloc>().add(
                              LoginRequested(email, password),
                            );
                          } else {
                            final name = _nameController.text;
                            if (name.isEmpty) {
                              AppToast.warning(
                                context,
                                'Nama lengkap wajib diisi',
                              );
                              return;
                            }
                            context.read<AuthBloc>().add(
                              RegisterRequested(
                                email: email,
                                password: password,
                                fullName: name,
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Switcher
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            text: _isLogin
                                ? 'Belum punya akun? '
                                : 'Sudah punya akun? ',
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: _isLogin
                                    ? 'Daftar Sekarang'
                                    : 'Login Disini',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.ambitiousNavy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
