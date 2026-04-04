// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - Settings Screen
/// Notification toggle, SOS settings, language selector,
/// dark mode toggle, and app info section.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String tr(BuildContext context, String text) {
    return AppStrings.tr(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    // For local dark mode inversion of hardcoded Card colors
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textLight;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      appBar: AppBar(
        title: Text(tr(context, 'Settings'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Notifications ──────────────────────────────────────────
            _SectionTitle(title: tr(context, 'Notifications')),
            Card(
              color: cardColor,
              child: SwitchListTile(
                value: settings.notificationsEnabled,
                onChanged: (v) {
                  settings.toggleNotifications(v);
                  showAppSnackBar(
                    context,
                    tr(context, v ? 'Notifications enabled' : 'Notifications disabled'),
                  );
                },
                title: Text(tr(context, 'Push Notifications'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                subtitle: Text(tr(context, 'Receive safety alerts and reminders'),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: subtitleColor)),
                secondary: const Icon(Icons.notifications_active_rounded,
                    color: AppColors.primary),
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // ─── SOS Settings ───────────────────────────────────────────
            _SectionTitle(title: tr(context, 'SOS Settings')),
            Card(
              color: cardColor,
              child: Column(
                children: [
                   SwitchListTile(
                    value: settings.sosVibration,
                     onChanged: (v) => settings.toggleSosVibration(v),
                     title: Text(tr(context, 'Vibration on SOS'),
                         style:
                             GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                     subtitle: Text(tr(context, 'Vibrate when SOS is triggered'),
                        style: GoogleFonts.poppins(
                             fontSize: 12, color: subtitleColor)),
                     secondary:
                        const Icon(Icons.vibration, color: AppColors.warning),
                     activeThumbColor: AppColors.primary,
                   ),
                  Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                  SwitchListTile(
                    value: settings.sosSiren,
                    onChanged: (v) => settings.toggleSosSiren(v),
                    title: Text(tr(context, 'Siren Sound on SOS'),
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                    subtitle: Text(tr(context, 'Play loud siren when SOS activates'),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: subtitleColor)),
                    secondary: const Icon(Icons.volume_up_rounded,
                        color: AppColors.danger),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Language ───────────────────────────────────────────────
            _SectionTitle(title: tr(context, 'Language')),
            Card(
              color: cardColor,
              child: ListTile(
                leading: const Icon(Icons.language_rounded,
                    color: AppColors.secondary),
                title: Text(tr(context, 'App Language'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                subtitle: Text(tr(context, settings.isHindi ? 'Hindi' : 'English'),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: subtitleColor)),
                trailing: DropdownButton<String>(
                  value: settings.isHindi ? 'Hindi' : 'English',
                  underline: const SizedBox.shrink(),
                  dropdownColor: cardColor,
                  items: ['English', 'Hindi']
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(tr(context, l),
                                style: GoogleFonts.poppins(fontSize: 14, color: textColor)),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    final bool isNowHindi = (v == 'Hindi');
                    await settings.toggleLanguage(isNowHindi);
                    showAppSnackBar(context, isNowHindi ? 'भाषा हिंदी में बदल दी गई है' : 'Language changed to English');
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Appearance ─────────────────────────────────────────────
            _SectionTitle(title: tr(context, 'Appearance')),
            Card(
              color: cardColor,
              child: SwitchListTile(
                 value: settings.isDarkMode,
                 onChanged: (v) {
                   settings.toggleDarkMode(v);
                   showAppSnackBar(
                    context,
                    tr(context, v ? 'Dark mode enabled' : 'Light mode enabled'),
                  );
                 },
                 title: Text(tr(context, 'Dark Mode'),
                     style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                 subtitle: Text(tr(context, 'Reduce eye strain at night'),
                     style: GoogleFonts.poppins(
                         fontSize: 12, color: subtitleColor)),
                 secondary: Icon(
                   settings.isDarkMode
                       ? Icons.dark_mode_rounded
                       : Icons.light_mode_rounded,
                   color: settings.isDarkMode ? Colors.indigo : Colors.amber,
                 ),
                 activeThumbColor: AppColors.primary,
               ),
            ),
            const SizedBox(height: 20),

            // ─── App Info ───────────────────────────────────────────────
            _SectionTitle(title: tr(context, 'About')),
            Card(
              color: cardColor,
              child: Column(
                children: [
                   ListTile(
                     leading: const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary),
                    title: Text(tr(context, 'App Version'),
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                    trailing: Text('1.0.0',
                         style: GoogleFonts.poppins(
                             color: subtitleColor, fontSize: 13)),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                  ListTile(
                     leading: const Icon(Icons.description_outlined,
                         color: AppColors.primary),
                     title: Text(tr(context, 'Terms of Service'),
                         style:
                             GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                     trailing: Icon(Icons.chevron_right_rounded,
                         color: subtitleColor),
                     onTap: () {},
                   ),
                   Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                   ListTile(
                     leading: const Icon(Icons.privacy_tip_outlined,
                         color: AppColors.primary),
                     title: Text(tr(context, 'Privacy Policy'),
                         style:
                             GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                     trailing: Icon(Icons.chevron_right_rounded,
                         color: subtitleColor),
                     onTap: () {},
                   ),
                   Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                   ListTile(
                    leading: const Icon(Icons.star_outline_rounded,
                         color: Colors.amber),
                    title: Text(tr(context, 'Rate this App'),
                         style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: subtitleColor),
                    onTap: () =>
                         showAppSnackBar(context, tr(context, 'Thanks for rating us!')),
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
                     tr(context, 'Your Safety, Our Priority'),
                     style: GoogleFonts.poppins(
                       fontSize: 12,
                       color: subtitleColor,
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
    final isDark = context.watch<SettingsProvider>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : AppColors.textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
