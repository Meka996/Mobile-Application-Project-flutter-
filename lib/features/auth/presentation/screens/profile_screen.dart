import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/velora_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
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

      if (!document.exists || document.data() == null) {
        setState(() {
          _errorMessage = 'Profile not found. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      final data = document.data()!;

      setState(() {
        _nameController.text = data['name']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMessage('Name cannot be empty.');
      return;
    }

    if (name.length > 80) {
      _showMessage('Name must be 80 characters or less.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.updateUserProfile(
        uid: user.uid,
        name: name,
        phone: phone,
      );

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

    return Scaffold(
      backgroundColor: AppTheme.offWhite,

      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.offWhite,
        foregroundColor: AppTheme.deepRose,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                      color: AppTheme.deepRose,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 100,
                  color: AppTheme.deepRose,
                ),

                const SizedBox(height: 15),

                const Text(
                  'My Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepRose,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Email Address',
                  style: TextStyle(
                    color: AppTheme.deepRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  user?.email ?? 'No email available',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 25),

                VeloraButton(
                  text: _isSaving ? 'Saving...' : 'Save Changes',
                  icon: Icons.save_outlined,
                  onPressed: _isSaving ? null : _updateProfile,
                ),

                const SizedBox(height: 16),

                VeloraButton(
                  text: 'Logout',
                  icon: Icons.logout,
                  onPressed: _logout,
                ),
              ],
            ),
    );
  }
}
