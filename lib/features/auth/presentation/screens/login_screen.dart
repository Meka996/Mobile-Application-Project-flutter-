import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth_service.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../shared/shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService, this.onSignUp});

  final AuthService? authService;
  final VoidCallback? onSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(email: _email, password: _password);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _showMessage('No account found. Check your email and password.');
      } else if (e.code == 'wrong-password') {
        _showMessage('Incorrect password.');
      } else if (e.code == 'invalid-email') {
        _showMessage('Please enter a valid email.');
      } else {
        _showMessage(e.message ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppLayout.page),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const SizedBox(height: AppLayout.section),
                const VeloraLogo(greeting: 'Welcome Back to'),

                const SizedBox(height: AppLayout.small),

                const Text(
                  'Login to continue shopping.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppLayout.section),

                VeloraTextField(
                  hint: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value ?? '').trim().contains('@')
                      ? null
                      : 'Enter a valid email address.',
                  onChanged: (value) => _email = value,
                ),

                const SizedBox(height: AppLayout.large),

                VeloraTextField(
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your password.'
                      : null,
                  onChanged: (value) => _password = value,
                ),

                const SizedBox(height: AppLayout.page),

                VeloraButton(
                  text: _isLoading ? 'Logging in...' : 'Login',
                  icon: Icons.login,
                  onPressed: _isLoading ? null : _login,
                ),
                if (widget.onSignUp != null)
                  TextButton(
                    onPressed: _isLoading ? null : widget.onSignUp,
                    child: const Text('Create an account'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
