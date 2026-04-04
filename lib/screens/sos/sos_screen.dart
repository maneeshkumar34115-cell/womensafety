// ignore_for_file: use_build_context_synchronously
// SafeGuardHer - SOS Alert Screen
// Sends REAL SMS to emergency contacts with GPS location.
// Logs SOS to Firestore. Volume-down 3x rapid trigger.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/location_service.dart';
import '../../services/contacts_service.dart';
import '../../services/auth_service.dart';
import '../../services/sms_service.dart';
import '../../providers/settings_provider.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with TickerProviderStateMixin {
  bool _isHolding = false;
  bool _sosActivated = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  int _countdown = 3;
  bool _flashOn = false;
  Timer? _flashTimer;
  bool _isSending = false;
  String _statusMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _volumeDownCount = 0;
  Timer? _volumeResetTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _locationLoopTimer;
  Timer? _vibrationTimer;
  Timer? _graceTimer;

  bool _inGracePeriod = false;
  int _gracePeriodCountdown = 5;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.sms.request();
    await Permission.location.request();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _flashTimer?.cancel();
    _volumeResetTimer?.cancel();
    _locationLoopTimer?.cancel();
    _vibrationTimer?.cancel();
    _graceTimer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    Vibration.cancel();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
      _volumeDownCount++;
      _volumeResetTimer?.cancel();
      _volumeResetTimer = Timer(const Duration(milliseconds: 800), () {
        _volumeDownCount = 0;
      });

      if (_volumeDownCount >= 3 && !_sosActivated) {
        _volumeDownCount = 0;
        _activateSOS();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
      _countdown = 3;
    });
    HapticFeedback.heavyImpact();

    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _holdProgress += 1 / 30;
        _countdown = 3 - (_holdProgress * 3).floor();
        if (_countdown < 0) _countdown = 0;
      });

      if (_holdProgress >= 1.0) {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (!_sosActivated) {
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
        _countdown = 3;
      });
    }
  }

  Future<void> _activateSOS() async {
    setState(() {
      _sosActivated = true;
      _isSending = false;
      _inGracePeriod = true;
      _gracePeriodCountdown = 5;
      _statusMessage = 'Alerting contacts in $_gracePeriodCountdown seconds...';
    });
    HapticFeedback.heavyImpact();

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Audio and Vibration
    if (settings.sosSiren) {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.play(AssetSource('sounds/siren.mp3'));
    }
    
    if (settings.sosVibration) {
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 1000);
        }
      });
    }

    // Flash screen
    _flashTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _flashOn = !_flashOn);
    });
    Future.delayed(const Duration(seconds: 2), () {
      _flashTimer?.cancel();
      if (mounted) setState(() => _flashOn = false);
    });

    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_gracePeriodCountdown > 1) {
        setState(() {
          _gracePeriodCountdown--;
          _statusMessage = 'Alerting contacts in $_gracePeriodCountdown seconds...';
        });
      } else {
        timer.cancel();
        _executeSOSPayload();
      }
    });
  }

  Future<void> _executeSOSPayload() async {
    if (!mounted) return;
    setState(() {
      _inGracePeriod = false;
      _isSending = true;
      _statusMessage = 'Fetching your location...';
    });

    // Check SMS permission
    final smsStatus = await Permission.sms.status;
    if (!smsStatus.isGranted) {
      await Permission.sms.request();
    }

    // Get GPS location
    double lat = 0, lng = 0;
    try {
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final pos = await locationService.getCurrentLocation();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _statusMessage = 'Sending SOS SMS to contacts...');

    final auth = Provider.of<AuthService>(context, listen: false);
    final contactsService =
        Provider.of<ContactsService>(context, listen: false);
    final contacts = contactsService.contacts;
    final userName = auth.currentUser?.fullName ?? 'User';
    final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Build emergency message
    final emergencyMessage =
        '🆘 EMERGENCY! $userName needs help immediately!\n'
        'Live Location: https://maps.google.com/?q=$lat,$lng\n'
        'Time: $timeStr';

    // Send real SMS
    List<String> sentTo = [];
    try {
      sentTo = await SmsService.sendEmergencySMS(
        contacts: contacts,
        message: emergencyMessage,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'SMS error: $e', isError: true);
      }
    }

    // Log to Firestore
    try {
      await FirebaseFirestore.instance.collection('sos_logs').add({
        'userId': auth.currentUser?.uid ?? 'unknown',
        'userName': userName,
        'latitude': lat,
        'longitude': lng,
        'contactsNotified': sentTo,
        'totalContacts': contacts.length,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    } catch (e) {
      // Firestore may not be configured
    }

    if (!mounted) return;

    setState(() {
      _isSending = false;
      _statusMessage = sentTo.isNotEmpty
          ? 'SOS SMS sent to ${sentTo.length} contact(s)!'
          : contacts.isEmpty
              ? 'No emergency contacts added yet.'
              : 'SMS sending attempted. Check phone for delivery.';
    });

    if (mounted) {
      showAppSnackBar(
        context,
        sentTo.isNotEmpty
            ? 'SOS SMS sent to: ${sentTo.join(", ")}'
            : 'SOS triggered! Add contacts for SMS alerts.',
      );
    }
    
    // Start continuous location sharing loop
    _locationLoopTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final pos = await Provider.of<LocationService>(context, listen: false).getCurrentLocation();
      if (pos != null) {
        final locMessage = '🆘 Live Update: $userName is at https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
        for (var contact in contacts) {
          SmsService.sendSingleSMS(phone: contact.phone, message: locMessage);
        }
      }
    });
  }

  Future<void> _sendSafeNow() async {
    if (_inGracePeriod) {
      _resetSOS();
      if (mounted) showAppSnackBar(context, 'SOS cancelled before sending.');
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = 'Sending "I am safe" message...';
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final contactsService =
        Provider.of<ContactsService>(context, listen: false);
    final userName = auth.currentUser?.fullName ?? 'User';
    final safeMessage =
        '$userName is now safe. Thank you for your concern.';

    try {
      await SmsService.sendSafeNowSMS(
        contacts: contactsService.contacts,
        message: safeMessage,
      );

      // Update Firestore log
      try {
        final logs = await FirebaseFirestore.instance
            .collection('sos_logs')
            .where('userId', isEqualTo: auth.currentUser?.uid ?? '')
            .where('status', isEqualTo: 'active')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (logs.docs.isNotEmpty) {
          await logs.docs.first.reference.update({
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}

      if (!mounted) return;
      showAppSnackBar(context, '"I am safe" sent to all contacts');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Could not send safe message', isError: true);
    }

    _resetSOS();
  }

  void _resetSOS() {
    _flashTimer?.cancel();
    _locationLoopTimer?.cancel();
    _vibrationTimer?.cancel();
    _graceTimer?.cancel();
    _audioPlayer.stop();
    Vibration.cancel();
    
    setState(() {
      _sosActivated = false;
      _inGracePeriod = false;
      _isHolding = false;
      _holdProgress = 0.0;
      _countdown = 3;
      _flashOn = false;
      _isSending = false;
      _statusMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: _flashOn ? Colors.red : AppColors.background,
        appBar: AppBar(
          title: Text('SOS Emergency',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_sosActivated) ...[
                // Power Button SOS info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.power_settings_new_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Power Button SOS is active — press power 3 times rapidly even with phone locked',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Volume hint
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Press volume-down 3 times rapidly for quick SOS',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Emergency quick-dial
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickDialButton(
                        number: '100',
                        label: 'Police',
                        color: const Color(0xFF1565C0),
                        icon: Icons.local_police_rounded,
                      ),
                      _QuickDialButton(
                        number: '112',
                        label: 'Emergency',
                        color: AppColors.danger,
                        icon: Icons.emergency_rounded,
                      ),
                      _QuickDialButton(
                        number: '1091',
                        label: 'Women',
                        color: AppColors.primary,
                        icon: Icons.support_agent_rounded,
                      ),
                      _QuickDialButton(
                        number: '102',
                        label: 'Ambulance',
                        color: AppColors.success,
                        icon: Icons.local_hospital_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Hold the button for 3 seconds to activate emergency SOS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: AppColors.textLight, height: 1.5),
                  ),
                ),
                const SizedBox(height: 48),

                // SOS Button
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: GestureDetector(
                    onTapDown: (_) => _startHold(),
                    onTapUp: (_) => _cancelHold(),
                    onTapCancel: () => _cancelHold(),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: _holdProgress,
                              strokeWidth: 8,
                              backgroundColor: Colors.red.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.danger),
                            ),
                          ),
                          Container(
                            width: 170,
                            height: 170,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.danger,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sos_rounded,
                                    color: Colors.white, size: 48),
                                const SizedBox(height: 4),
                                Text(
                                  _isHolding ? '$_countdown' : 'SOS',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: _isHolding ? 40 : 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isHolding ? 'Keep holding...' : 'Hold to activate',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isHolding ? AppColors.danger : AppColors.textLight,
                  ),
                ),
              ] else ...[
                if (_isSending) ...[
                  const CircularProgressIndicator(color: AppColors.danger),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: AppColors.textLight),
                    ),
                  ),
                ] else ...[
                  // Pulse active state
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                        color: AppColors.danger,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sos_rounded, color: Colors.white, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'SOS\nACTIVE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: _inGracePeriod ? 22 : 28,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          if (_inGracePeriod) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$_gracePeriodCountdown',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: _inGracePeriod ? Colors.white : AppColors.textLight, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 48),
                  GradientButton(
                    text: _inGracePeriod ? 'Cancel SOS Now' : 'Cancel SOS / I am safe',
                    icon: Icons.cancel_rounded,
                    onPressed: _sendSafeNow,
                    width: 250,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Dial Button for Emergency Numbers ─────────────────────────────────

class _QuickDialButton extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  final IconData icon;

  const _QuickDialButton({
    required this.number,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final uri = Uri.parse('tel:$number');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          Text(
            number,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}