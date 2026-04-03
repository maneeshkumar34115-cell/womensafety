// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - Settings Screen
/// Notification toggle, SOS settings, language selector,
/// dark mode toggle, and app info section.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _sosVibration = true;
  bool _sosSiren = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Notifications ──────────────────────────────────────────
            _SectionTitle(title: 'Notifications'),
            Card(
              child: SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (v) {
                  setState(() => _notificationsEnabled = v);
                  showAppSnackBar(
                    context,
                    v ? 'Notifications enabled' : 'Notifications disabled',
                  );
                },
                title: Text('Push Notifications',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Receive safety alerts and reminders',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textLight)),
                secondary: const Icon(Icons.notifications_active_rounded,
                    color: AppColors.primary),
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // ─── SOS Settings ───────────────────────────────────────────
            _SectionTitle(title: 'SOS Settings'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _sosVibration,
                    onChanged: (v) => setState(() => _sosVibration = v),
                    title: Text('Vibration on SOS',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text('Vibrate when SOS is triggered',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textLight)),
                    secondary:
                        const Icon(Icons.vibration, color: AppColors.warning),
                    activeThumbColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _sosSiren,
                    onChanged: (v) => setState(() => _sosSiren = v),
                    title: Text('Siren Sound on SOS',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text('Play loud siren when SOS activates',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textLight)),
                    secondary: const Icon(Icons.volume_up_rounded,
                        color: AppColors.danger),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Language ───────────────────────────────────────────────
            _SectionTitle(title: 'Language'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.language_rounded,
                    color: AppColors.secondary),
                title: Text('App Language',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text(_language,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textLight)),
                trailing: DropdownButton<String>(
                  value: _language,
                  underline: const SizedBox.shrink(),
                  items: ['English', 'Hindi']
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l,
                                style: GoogleFonts.poppins(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _language = v!);
                    showAppSnackBar(context, 'Language changed to $v');
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Appearance ─────────────────────────────────────────────
            _SectionTitle(title: 'Appearance'),
            Card(
              child: SwitchListTile(
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  showAppSnackBar(
                    context,
                    v ? 'Dark mode enabled' : 'Light mode enabled',
                  );
                },
                title: Text('Dark Mode',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Reduce eye strain at night',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textLight)),
                secondary: Icon(
                  _darkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: _darkMode ? Colors.indigo : Colors.amber,
                ),
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // ─── App Info ───────────────────────────────────────────────
            _SectionTitle(title: 'About'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary),
                    title: Text('App Version',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    trailing: Text('1.0.0',
                        style: GoogleFonts.poppins(
                            color: AppColors.textLight, fontSize: 13)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined,
                        color: AppColors.primary),
                    title: Text('Terms of Service',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: AppColors.primary),
                    title: Text('Privacy Policy',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star_outline_rounded,
                        color: Colors.amber),
                    title: Text('Rate this App',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight),
                    onTap: () =>
                        showAppSnackBar(context, 'Thanks for rating us!'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  const Icon(Icons.shield, color: AppColors.primary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'RAKSHAHER',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Your Safety, Our Priority',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Reusable section title widget
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}