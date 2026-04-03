// SafeGuardHer - Live Location Screen
// Real interactive Google Map with GPS, satellite toggle, polyline trail,
// pulsing marker, permission dialogs, and confirmation bottom sheet.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/location_service.dart';
import '../../services/contacts_service.dart';
import '../../services/auth_service.dart';
import '../../services/sms_service.dart';

const LatLng _defaultCenter = LatLng(22.9676, 76.0534); // Dewas, MP

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen>
    with TickerProviderStateMixin {
  bool _isSharing = false;
  bool _isLoading = true;
  bool _mapReady = false;
  LatLng _userLocation = _defaultCenter;
  String _latitude = '--';
  String _longitude = '--';
  String _lastUpdated = 'Never';
  Timer? _trackingTimer;
  DateTime? _lastUpdateTime;

  // Map
  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;

  // Polyline trail
  final List<LatLng> _locationHistory = [];

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchLocation();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _pulseController.dispose();
    _stopSharing();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
      final locService =
          Provider.of<LocationService>(context, listen: false);
      final pos = await locService.getCurrentLocation();
      if (pos != null && mounted) {
        final newLoc = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = newLoc;
          _latitude = pos.latitude.toStringAsFixed(6);
          _longitude = pos.longitude.toStringAsFixed(6);
          _lastUpdateTime = DateTime.now();
          _lastUpdated = 'Just now';
          // Add to trail
          if (_locationHistory.isEmpty ||
              _locationHistory.last != newLoc) {
            _locationHistory.add(newLoc);
          }
        });
        _animateMapTo(_userLocation);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastUpdated = 'Location error');
        showAppSnackBar(context, 'Could not get location: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _animateMapTo(LatLng target) {
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (_) {}
  }

  // ─── Permission checks ────────────────────────────────────────────────

  Future<bool> _checkLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog(
          'Location Permission',
          'Location permission is permanently denied. Please enable it in app settings.',
        );
      }
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _checkSmsPermission() async {
    var status = await Permission.sms.status;
    if (status.isDenied) {
      status = await Permission.sms.request();
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog(
          'SMS Permission',
          'SMS permission is permanently denied. Please enable it in app settings to send location SMS.',
        );
      }
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _checkBackgroundLocationPermission() async {
    // First show rationale
    if (mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('Background Location',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          content: Text(
            'To keep sharing your location when the app is in the background, '
            'we need "Allow all the time" location access.\n\n'
            'This ensures your trusted contacts always have your latest position.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textLight, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Skip',
                  style: GoogleFonts.poppins(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Allow',
                  style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
        ),
      );

      if (proceed != true) return true; // User can skip background permission
    }

    var status = await Permission.locationAlways.status;
    if (status.isDenied) {
      status = await Permission.locationAlways.request();
    }
    return true; // Non-critical — sharing still works in foreground
  }

  void _showPermissionDeniedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(message,
            style:
                GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Open Settings',
                style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ─── Confirmation bottom sheet ────────────────────────────────────────

  void _toggleSharing() async {
    HapticFeedback.mediumImpact();

    if (_isSharing) {
      // Stop sharing — no confirmation needed
      setState(() => _isSharing = false);
      _stopSharing();
      showAppSnackBar(context, 'Location sharing stopped');
      return;
    }

    // Starting sharing — check permissions first
    final hasLocation = await _checkLocationPermission();
    if (!hasLocation) return;

    final hasSms = await _checkSmsPermission();
    if (!hasSms) return;

    await _checkBackgroundLocationPermission();

    // Show confirmation bottom sheet
    if (mounted) {
      _showConfirmationSheet();
    }
  }

  void _showConfirmationSheet() {
    final contactsService =
        Provider.of<ContactsService>(context, listen: false);
    final contacts = contactsService.contacts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_location_rounded,
                    size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 16),

              Text(
                'Share Live Location',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'You are about to share your live location with '
                '${contacts.length} trusted contact${contacts.length == 1 ? '' : 's'}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.5),
              ),
              const SizedBox(height: 20),

              // Contact list
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: contacts.map((contact) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              contact.name[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contact.name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(contact.phone,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textLight)),
                              ],
                            ),
                          ),
                          Icon(Icons.sms_rounded,
                              size: 18, color: AppColors.primary),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An SMS with your live location link will be sent',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textLight),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(ctx);
                        setState(() => _isSharing = true);
                        _startSharing();
                      },
                      icon: const Icon(Icons.share_location_rounded,
                          size: 20),
                      label: Text('Start Sharing',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  // ─── Sharing logic ────────────────────────────────────────────────────

  Future<void> _startSharing() async {
    // First fetch current location
    await _fetchLocation();

    // Send ONE SMS to all emergency contacts
    final auth = Provider.of<AuthService>(context, listen: false);
    final contactsService =
        Provider.of<ContactsService>(context, listen: false);
    final userName = auth.currentUser?.fullName ?? 'User';
    final userId = auth.currentUser?.uid ?? 'unknown';

    final trackingMessage =
        '📍 $userName is sharing live location.\n'
        'Track here: https://maps.google.com/?q=$_latitude,$_longitude\n'
        'This location updates every 10 seconds.';

    for (final contact in contactsService.contacts) {
      await SmsService.sendSingleSMS(
        phone: contact.phone,
        message: trackingMessage,
      );
    }

    // Update Firestore with live location
    _updateFirestoreLocation(userId);

    // Start periodic updates every 10 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _fetchLocation();
      _updateFirestoreLocation(userId);
      if (mounted) {
        _updateLastUpdatedText();
      }
    });

    if (mounted) {
      showAppSnackBar(context,
          'Location sharing started — SMS sent to ${contactsService.contacts.length} contact(s)');
    }
  }

  Future<void> _updateFirestoreLocation(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('live_locations')
          .doc(userId)
          .set({
        'latitude': double.tryParse(_latitude) ?? 0,
        'longitude': double.tryParse(_longitude) ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': _isSharing,
      });
    } catch (_) {
      // Firestore may not be configured
    }
  }

  Future<void> _stopSharing() async {
    _trackingTimer?.cancel();
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid ?? 'unknown';
    try {
      await FirebaseFirestore.instance
          .collection('live_locations')
          .doc(userId)
          .set({
        'isActive': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _updateLastUpdatedText() {
    if (_lastUpdateTime == null) return;
    final diff = DateTime.now().difference(_lastUpdateTime!);
    if (diff.inSeconds < 5) {
      _lastUpdated = 'Just now';
    } else {
      _lastUpdated = '${diff.inSeconds}s ago';
    }
    setState(() {});
  }

  void _toggleMapType() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_mapType) {
        case MapType.normal:
          _mapType = MapType.satellite;
          break;
        case MapType.satellite:
          _mapType = MapType.hybrid;
          break;
        default:
          _mapType = MapType.normal;
      }
    });
  }

  String get _mapTypeLabel {
    switch (_mapType) {
      case MapType.satellite:
        return 'Satellite';
      case MapType.hybrid:
        return 'Hybrid';
      default:
        return 'Normal';
    }
  }

  IconData get _mapTypeIcon {
    switch (_mapType) {
      case MapType.satellite:
        return Icons.satellite_alt_rounded;
      case MapType.hybrid:
        return Icons.layers_rounded;
      default:
        return Icons.map_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Live Tracking',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (_isSharing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, __) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.danger
                                .withValues(alpha: _pulseAnimation.value),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.danger
                                    .withValues(alpha: _pulseAnimation.value * 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('LIVE',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLocation,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userLocation,
                      zoom: 15.0,
                    ),
                    mapType: _mapType,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      setState(() => _mapReady = true);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    // Polyline trail
                    polylines: _locationHistory.length >= 2
                        ? {
                            Polyline(
                              polylineId: const PolylineId('location_trail'),
                              points: _locationHistory,
                              color: AppColors.primary,
                              width: 4,
                              patterns: [
                                PatternItem.dash(10),
                                PatternItem.gap(6),
                              ],
                            ),
                          }
                        : {},
                    // Sharing radius circle
                    circles: _isSharing
                        ? {
                            Circle(
                              circleId: const CircleId('sharing_radius'),
                              center: _userLocation,
                              radius: 60,
                              fillColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              strokeColor:
                                  AppColors.primary.withValues(alpha: 0.3),
                              strokeWidth: 2,
                            )
                          }
                        : {},
                    markers: {
                      Marker(
                        markerId: const MarkerId('user_location'),
                        position: _userLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed),
                      )
                    },
                  ),

                  // Loading overlay
                  if (_isLoading && !_mapReady)
                    Container(
                      color: AppColors.background,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: AppColors.primary),
                            const SizedBox(height: 12),
                            Text('Loading map...',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ),

                  // Map type toggle
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _MapButton(
                      icon: _mapTypeIcon,
                      label: _mapTypeLabel,
                      onTap: _toggleMapType,
                    ),
                  ),

                  // Zoom controls + recenter
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(
                      children: [
                        _MapIconButton(
                          icon: Icons.add,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _mapController
                                ?.animateCamera(CameraUpdate.zoomIn());
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapIconButton(
                          icon: Icons.remove,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _mapController
                                ?.animateCamera(CameraUpdate.zoomOut());
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapIconButton(
                          icon: Icons.my_location_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    _userLocation, 16));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controls panel
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CoordChip(label: 'Latitude', value: _latitude),
                      const SizedBox(width: 12),
                      _CoordChip(label: 'Longitude', value: _longitude),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 16, color: AppColors.textLight),
                      const SizedBox(width: 6),
                      Text(
                        'Last updated: $_lastUpdated',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textLight),
                      ),
                      const Spacer(),
                      if (_locationHistory.length >= 2)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_locationHistory.length} points',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),

                  // Share toggle with confirmation
                  Container(
                    decoration: BoxDecoration(
                      color: _isSharing
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: _isSharing
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2))
                          : null,
                    ),
                    child: SwitchListTile(
                      value: _isSharing,
                      onChanged: (_) => _toggleSharing(),
                      title: Text('Share Live Location',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text(
                        _isSharing
                            ? 'Updating every 10 seconds'
                            : 'Send location to trusted contacts',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isSharing
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isSharing
                              ? Icons.share_location_rounded
                              : Icons.location_off_rounded,
                          color: _isSharing
                              ? AppColors.primary
                              : AppColors.textLight,
                          size: 22,
                        ),
                      ),
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      thumbColor:
                          WidgetStatePropertyAll(AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    text: 'Refresh Location',
                    icon: Icons.my_location_rounded,
                    onPressed: _fetchLocation,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map Type Toggle Button ─────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MapButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textDark),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Map Icon Button ────────────────────────────────────────────────────────

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }
}

// ─── Coord Chip ─────────────────────────────────────────────────────────────

class _CoordChip extends StatelessWidget {
  final String label;
  final String value;
  const _CoordChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
