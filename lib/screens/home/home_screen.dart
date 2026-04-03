/// SafeGuardHer - Home Dashboard Screen
/// Central hub with welcome greeting, safety status card,
/// 8 action grid tiles, frosted glass bottom navigation, and haptic feedback.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../services/auth_service.dart';
import '../sos/sos_screen.dart';
import '../contacts/contacts_screen.dart';
import '../live_location/live_location_screen.dart';
import '../fake_call/fake_call_screen.dart';
import '../safety_tips/safety_tips_screen.dart';
import '../nearby_help/nearby_help_screen.dart';
import '../report_incident/report_incident_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardBody(),
      const LiveLocationScreen(),
      const ContactsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      extendBody: true,
      // Floating SOS button — always accessible from any tab
      floatingActionButton: _currentIndex == 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 60),
              child: FloatingActionButton.large(
                heroTag: 'sos_fab',
                backgroundColor: AppColors.danger,
                elevation: 8,
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SOSScreen()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sos_rounded,
                        color: Colors.white, size: 32),
                    Text('SOS',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FrostedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// The main dashboard body with greeting, safety card, and action grid
class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  void _navigateTo(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firstName = auth.currentUser?.fullName.split(' ').first ?? 'User';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with greeting and settings icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.welcomeBack,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      firstName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Settings gear
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _navigateTo(context, const SettingsScreen());
                      },
                      icon: const Icon(Icons.settings_rounded,
                          color: AppColors.textLight),
                    ),
                    // Profile avatar
                    GestureDetector(
                      onTap: () => HapticFeedback.lightImpact(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            firstName[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Safety status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Shield icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.safetyStatus,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All safety features active',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Green dot indicator
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Power Button SOS status badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.power_settings_new_rounded,
                            color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Power Button SOS: Active',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '3-Press',
                            style: GoogleFonts.poppins(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Quick Actions heading
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // 8-tile action grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
              children: [
                _ActionTile(
                  icon: Icons.sos_rounded,
                  label: AppStrings.sos,
                  color: AppColors.danger,
                  onTap: () =>
                      _navigateTo(context, const SOSScreen()),
                ),
                _ActionTile(
                  icon: Icons.share_location_rounded,
                  label: AppStrings.shareLocation,
                  color: const Color(0xFF1565C0),
                  onTap: () => _navigateTo(
                      context, const LiveLocationScreen()),
                ),
                _ActionTile(
                  icon: Icons.phone_in_talk_rounded,
                  label: AppStrings.fakeCall,
                  color: const Color(0xFFE65100),
                  onTap: () => _navigateTo(
                      context, const FakeCallScreen()),
                ),
                _ActionTile(
                  icon: Icons.lightbulb_outline_rounded,
                  label: AppStrings.safetyTips,
                  color: const Color(0xFF00695C),
                  onTap: () => _navigateTo(
                      context, const SafetyTipsScreen()),
                ),
                _ActionTile(
                  icon: Icons.contacts_rounded,
                  label: AppStrings.contacts,
                  color: AppColors.secondary,
                  onTap: () => _navigateTo(
                      context, const ContactsScreen()),
                ),
                _ActionTile(
                  icon: Icons.route_rounded,
                  label: AppStrings.trackJourney,
                  color: const Color(0xFF283593),
                  onTap: () => _navigateTo(
                      context, const LiveLocationScreen()),
                ),
                _ActionTile(
                  icon: Icons.local_hospital_rounded,
                  label: AppStrings.nearbyHelp,
                  color: const Color(0xFF2E7D32),
                  onTap: () => _navigateTo(
                      context, const NearbyHelpScreen()),
                ),
                _ActionTile(
                  icon: Icons.report_problem_rounded,
                  label: AppStrings.reportIncident,
                  color: Colors.redAccent,
                  onTap: () => _navigateTo(
                      context, const ReportIncidentScreen()),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Emergency helpline quick access
            Text(
              'Emergency Helplines',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            const _HelplineCard(
              name: 'Police',
              number: '100',
              icon: Icons.local_police_rounded,
              color: Color(0xFF1565C0),
            ),
            const _HelplineCard(
              name: 'Women Helpline',
              number: '1091',
              icon: Icons.support_agent_rounded,
              color: AppColors.primary,
            ),
            const _HelplineCard(
              name: 'Emergency',
              number: '112',
              icon: Icons.emergency_rounded,
              color: AppColors.danger,
            ),
            const _HelplineCard(
              name: 'Ambulance',
              number: '102',
              icon: Icons.local_hospital_rounded,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Single action tile in the grid
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helpline quick-call card
class _HelplineCard extends StatelessWidget {
  final String name;
  final String number;
  final IconData icon;
  final Color color;

  const _HelplineCard({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          number,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.call_rounded,
              color: Color(0xFF2E7D32), size: 22),
        ),
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.parse('tel:$number');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $number...')),
              );
            }
          }
        },
      ),
    );
  }
}
