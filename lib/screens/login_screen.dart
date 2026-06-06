// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  bool _showPass   = false;
  String? _error;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email and password are required.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'user-not-found'   => 'No account found for that email.',
          'wrong-password'   => 'Incorrect password.',
          'invalid-email'    => 'Invalid email address.',
          'user-disabled'    => 'This account has been disabled.',
          'invalid-credential' => 'Invalid email or password.',
          _                  => e.message ?? 'Login failed.',
        };
      });
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.green],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.shopping_cart_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text('Marnie Store', style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 28,
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('POS System v2.1', style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 32),

                AppCard(padding: const EdgeInsets.all(24), child: Column(children: [
                  Text('Sign In', style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 18,
                      fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Password',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    onSubmitted: (_) => _login(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary, size: 20),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.red.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: GoogleFonts.dmSans(
                            color: AppColors.red, fontSize: 13))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Sign In',
                    icon: Icons.login,
                    loading: _loading,
                    onPressed: _login,
                  ),
                ])),
                const SizedBox(height: 20),
                Text('Powered by Firebase · Works Offline',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }
}
