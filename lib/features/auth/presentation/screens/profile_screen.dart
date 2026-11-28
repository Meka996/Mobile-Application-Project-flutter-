import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/velora_button.dart';
import '../../../orders/screens/order_history_screen.dart';

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
    } catch (_) {
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
      _showMessage('Username cannot be empty.');
      return;
    }
    if (name.length > 80) {
      _showMessage('Username must be 80 characters or less.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.updateUserProfile(
        uid: user.uid,
        name: name,
        phone: phone,
      );
      if (!mounted) return;
      _showMessage('Profile updated successfully!');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool hideCurrent = true;
    bool hideNew = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: hideCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    suffixIcon: IconButton(
                      icon: Icon(hideCurrent ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => hideCurrent = !hideCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: hideNew,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    helperText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(hideNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => hideNew = !hideNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final current = currentController.text;
                final password = newController.text;
                if (current.isEmpty || password.isEmpty) {
                  _showMessage('Please fill in all password fields.');
                  return;
                }
                if (password.length < 6) {
                  _showMessage('New password must be at least 6 characters.');
                  return;
                }
                if (password != confirmController.text) {
                  _showMessage('New passwords do not match.');
                  return;
                }

                Navigator.pop(dialogContext);
                try {
                  await _authService.changePassword(
                    currentPassword: current,
                    newPassword: password,
                  );
                  _showMessage('Password changed successfully.');
                } on FirebaseAuthException catch (error) {
                  if (error.code == 'wrong-password' ||
                      error.code == 'invalid-credential') {
                    _showMessage('Your current password is incorrect.');
                  } else if (error.code == 'weak-password') {
                    _showMessage('Please choose a stronger password.');
                  } else if (error.code == 'requires-recent-login') {
                    _showMessage('Please sign out and sign in again, then retry.');
                  } else {
                    _showMessage(error.message ?? 'Could not change password.');
                  }
                } catch (_) {
                  _showMessage('Could not change password. Please try again.');
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  void _openOrderHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OrderHistoryScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Logout failed. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        const Icon(Icons.error_outline, size: 55, color: AppTheme.deepRose),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Icon(Icons.account_circle, size: 100, color: AppTheme.deepRose),
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
                    const SizedBox(height: 25),
                    const Text(
                      'ACCOUNT INFORMATION',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepRose),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.email_outlined, user?.email ?? 'No email available'),
                    const SizedBox(height: 22),
                    const Text(
                      'EDIT PROFILE',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepRose),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    VeloraButton(
                      text: _isSaving ? 'Saving...' : 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: _isSaving ? null : _updateProfile,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'YOUR ACCOUNT',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepRose),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppTheme.isDarkMode,
                      builder: (context, isDark, child) => Card(
                        color: Theme.of(context).cardColor,
                        child: SwitchListTile(
                          secondary: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: AppTheme.deepRose,
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Change the app appearance'),
                          value: isDark,
                          activeThumbColor: AppTheme.deepRose,
                          onChanged: (value) => AppTheme.isDarkMode.value = value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Order History',
                      subtitle: 'View your previous orders and details',
                      onTap: _openOrderHistory,
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: _showChangePasswordDialog,
                    ),
                    const SizedBox(height: 24),
                    VeloraButton(
                      text: 'Logout',
                      icon: Icons.logout,
                      onPressed: _logout,
                    ),
                  ],
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.deepRose),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.blushPink.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.deepRose),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
