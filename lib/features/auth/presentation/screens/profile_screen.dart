import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth_service.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../shared/shared.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onOrdersPressed});

  final VoidCallback? onOrdersPressed;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _profileExists = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Please login again.';
      });
      return;
    }

    try {
      final document = await _authService.getUserProfile(user.uid);

      if (!mounted) return;

      final data = document.data();

      setState(() {
        _profileExists = document.exists;
        _nameController.text = data?['name']?.toString() ?? '';
        _phoneController.text = data?['phone']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load your profile. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      if (_profileExists) {
        await _authService.updateUserProfile(
          uid: user.uid,
          name: name,
          phone: phone,
        );
      } else {
        await _authService.completeProfile(
          uid: user.uid,
          name: name,
          phone: phone,
        );
        await _loadProfile();
      }

      if (!mounted) return;

      _showMessage('Profile updated successfully!');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not update profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Logout failed. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final error = _errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (widget.onOrdersPressed != null)
            TextButton(
              onPressed: widget.onOrdersPressed,
              child: const Text('My Orders'),
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(label: 'Loading profile')
          : error != null
          ? StateMessage.error(
              title: 'Profile unavailable',
              message: error,
              onRetry: _loadProfile,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.formMaxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(AppLayout.page),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 80),
                      const SizedBox(height: AppLayout.large),
                      Text(
                        'My Account',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (!_profileExists) ...[
                        const SizedBox(height: AppLayout.small),
                        const Text(
                          'Enter your name to finish setting up your profile.',
                        ),
                      ],
                      const SizedBox(height: AppLayout.page),
                      Text('Email Address', style: theme.textTheme.labelLarge),
                      const SizedBox(height: AppLayout.small),
                      SelectableText(
                        user?.email ?? 'No email available',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppLayout.page),
                      VeloraTextField(
                        controller: _nameController,
                        hint: 'Full Name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final name = (value ?? '').trim();
                          if (name.isEmpty) return 'Enter your name.';
                          if (name.length > 80) {
                            return 'Use 80 characters or less.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppLayout.large),
                      VeloraTextField(
                        controller: _phoneController,
                        hint: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: AppLayout.page),
                      VeloraButton(
                        text: _isSaving
                            ? 'Saving...'
                            : _profileExists
                            ? 'Save Changes'
                            : 'Save Profile',
                        icon: Icons.save_outlined,
                        onPressed: _isSaving ? null : _updateProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
