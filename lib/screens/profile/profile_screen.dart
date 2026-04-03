// ignore_for_file: use_build_context_synchronously
// SafeGuardHer - Profile Screen
// Matte professional gradient header, clean cards below.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _nameCtrl = TextEditingController(text: auth.currentUser?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: auth.currentUser?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to log out? Your emergency contacts and settings will be preserved.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: Text('Log Out',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<AuthService>(context, listen: false).signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header — matte gradient with dark overlay
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8e244d), Color(0xFFb83260)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Title with settings button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF1F1F1),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            ),
                            icon: const Icon(Icons.settings_rounded,
                                color: Color(0xFFF1F1F1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Profile avatar — no border, subtle bg
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            child: Text(
                              (user?.fullName ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF1F1F1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () => showAppSnackBar(
                                    context, 'Profile photo updated!'),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.fullName ?? 'User',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF1F1F1),
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFFF1F1F1).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dark overlay for matte effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x1A000000),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Profile details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Edit toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personal Information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          if (_isEditing) {
                            showAppSnackBar(context, 'Profile updated!');
                          }
                          setState(() => _isEditing = !_isEditing);
                        },
                        icon: Icon(
                          _isEditing
                              ? Icons.check_rounded
                              : Icons.edit_rounded,
                          size: 18,
                        ),
                        label: Text(_isEditing ? 'Save' : 'Edit',
                            style: GoogleFonts.poppins(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info cards — white, elevation 1, borderRadius 12
                  _ProfileField(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: user?.fullName ?? '',
                    controller: _nameCtrl,
                    isEditing: _isEditing,
                  ),
                  _ProfileField(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '',
                    isEditing: false,
                  ),
                  _ProfileField(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user?.phone ?? '',
                    controller: _phoneCtrl,
                    isEditing: _isEditing,
                  ),

                  const SizedBox(height: 32),

                  _ProfileAction(
                    icon: Icons.security_rounded,
                    label: 'Privacy & Security',
                    onTap: () {},
                  ),
                  _ProfileAction(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _ProfileAction(
                    icon: Icons.info_outline_rounded,
                    label: 'About RAKSHAHER',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'RAKSHAHER',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            '© 2025 RAKSHAHER. All rights reserved.',
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.danger),
                      label: Text(
                        'Log Out',
                        style: GoogleFonts.poppins(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextEditingController? controller;
  final bool isEditing;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.controller,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                isEditing && controller != null
                    ? TextField(
                        controller: controller,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}