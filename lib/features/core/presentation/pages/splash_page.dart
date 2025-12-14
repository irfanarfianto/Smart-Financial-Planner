import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // Show logo for 2s

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) context.go('/login');
    } else {
      // Check if user has selected a model
      try {
        final userId = session.user.id;
        final response = await Supabase.instance.client
            .from('profiles')
            .select('active_model_id')
            .eq('id', userId)
            .maybeSingle();

        if (response != null && response['active_model_id'] != null) {
          if (mounted) context.go('/dashboard');
        } else {
          if (mounted) context.go('/onboarding');
        }
      } catch (e) {
        // If error (e.g. profile doesn't exist), go to onboarding or login?
        // Assuming profile trigger creates profile, or onboarding handles it.
        // We'll go to Onboarding to be safe.
        if (mounted) context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150),
          ],
        ),
      ),
    );
  }
}
