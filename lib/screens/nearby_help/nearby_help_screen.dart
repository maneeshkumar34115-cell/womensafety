// SafeGuardHer - Nearby Help Screen
// Real OpenStreetMap data via Overpass API (FREE). Map + List view.
// Features: shimmer loading, filter chips with icons, retry logic,
// location permission prompts, spinning refresh, rich empty state.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';

class NearbyHelpScreen extends StatefulWidget {
  const NearbyHelpScreen({super.key});

  @override
  State<NearbyHelpScreen> createState() => _NearbyHelpScreenState();
}

class _NearbyHelpScreenState extends State<NearbyHelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  List<NearbyPlace> _places = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocationDenied = false;
  double _userLat = 22.9676;
  double _userLng = 76.0534;
  bool _isRefreshing = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaces();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        setState(() => _isLocationDenied = true);
        return;
      }
    }
    if (status.isPermanentlyDenied) {
      setState(() => _isLocationDenied = true);
      return;
    }
    setState(() => _isLocationDenied = false);
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _errorMessage = null;
    });

    // Check location permission first
    await _checkAndRequestLocationPermission();
    if (_isLocationDenied) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'Location permission is required to find nearby help.';
      });
      return;
    }

    // Get real user location
    try {
      final locService =
          Provider.of<LocationService>(context, listen: false);
      final pos = await locService.getCurrentLocation();
      if (pos != null) {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      }
    } catch (_) {}

    // Fetch real nearby places from OpenStreetMap Overpass API
    try {
      final places = await PlacesService.fetchAllNearbyPlaces(
        lat: _userLat,
        lng: _userLng,
      );
      if (mounted) {
        setState(() {
          _places = places;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  List<NearbyPlace> get _filteredPlaces {
    if (_selectedFilter == 'All') return _places;
    return _places.where((p) => p.type == _selectedFilter).toList();
  }

  Future<void> _makeCall(NearbyPlace place) async {
    HapticFeedback.lightImpact();
    String phone = place.phone;

    if (phone.isEmpty) {
      if (mounted) {
        showAppSnackBar(context, 'Phone number not available', isError: true);
      }
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDirections(double lat, double lng) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(
        'https://maps.google.com/?daddr=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Police':
        return const Color(0xFF1565C0);
      case 'Hospital':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Police':
        return Icons.local_police_rounded;
      case 'Hospital':
        return Icons.local_hospital_rounded;
      default:
        return Icons.support_agent_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Nearby Help',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded), text: 'List'),
            Tab(icon: Icon(Icons.map_rounded), text: 'Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(),
          _buildMapView(),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        // Filter chips with icons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChipItem(
                  label: 'All',
                  icon: Icons.apps_rounded,
                  isSelected: _selectedFilter == 'All',
                  onTap: () => setState(() => _selectedFilter = 'All'),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Police',
                  icon: Icons.shield_rounded,
                  isSelected: _selectedFilter == 'Police',
                  color: const Color(0xFF1565C0),
                  onTap: () => setState(() => _selectedFilter = 'Police'),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Hospital',
                  icon: Icons.medical_services_rounded,
                  isSelected: _selectedFilter == 'Hospital',
                  color: const Color(0xFF2E7D32),
                  onTap: () => setState(() => _selectedFilter = 'Hospital'),
                ),
                const SizedBox(width: 8),
                _FilterChipItem(
                  label: 'Help Center',
                  icon: Icons.support_agent_rounded,
                  isSelected: _selectedFilter == 'Help Center',
                  color: AppColors.primary,
                  onTap: () =>
                      setState(() => _selectedFilter = 'Help Center'),
                ),
              ],
            ),
          ),
        ),

        // Results count + refresh
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_filteredPlaces.length} places found',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _isRefreshing ? null : _loadPlaces,
                icon: AnimatedRotation(
                  turns: _isRefreshing ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: _SpinningRefreshIcon(isSpinning: _isRefreshing),
                ),
                label: Text('Refresh',
                    style: GoogleFonts.poppins(fontSize: 12)),
              ),
            ],
          ),
        ),

        // Location denied prompt
        if (_isLocationDenied)
          _buildPermissionPrompt(),

        // Error message with retry
        if (_errorMessage != null && !_isLocationDenied)
          _buildErrorBanner(),

        // Content
        Expanded(
          child: _isLoading
              ? _buildShimmerList()
              : _filteredPlaces.isEmpty
                  ? _buildEmptyState()
                  : _buildPlacesList(),
        ),
      ],
    );
  }

  Widget _buildPermissionPrompt() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.location_disabled_rounded,
                size: 48, color: AppColors.warning),
            const SizedBox(height: 12),
            Text(
              'Location Permission Required',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'We need your location to find nearby police stations, hospitals, and help centers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await openAppSettings();
              },
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: Text('Open Settings',
                  style: GoogleFonts.poppins(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_errorMessage!,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.danger)),
            ),
            TextButton(
              onPressed: _loadPlaces,
              child: Text('Retry',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(44, 44, radius: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(150, 14),
                      const SizedBox(height: 6),
                      _shimmerBox(80, 10),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _shimmerBox(double.infinity, 10),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _shimmerBox(double.infinity, 40)),
                  const SizedBox(width: 12),
                  Expanded(child: _shimmerBox(double.infinity, 40)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.shimmerBase.withValues(alpha: value),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_searching_rounded,
                  size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Places Found Nearby',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any ${_selectedFilter == 'All' ? 'places' : _selectedFilter.toLowerCase()} within 5km of your current location. Try refreshing or expanding your search.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPlaces,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text('Try Again',
                  style: GoogleFonts.poppins(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredPlaces.length,
      itemBuilder: (_, index) {
        final place = _filteredPlaces[index];
        final color = _getTypeColor(place.type);
        final icon = _getTypeIcon(place.type);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                          Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(place.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Text(place.type,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.near_me_rounded,
                                size: 12,
                                color: AppColors.textLight),
                            const SizedBox(width: 2),
                            Text(
                              '${place.distanceKm.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textLight),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.place_rounded,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(place.address,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight)),
                    ),
                  ],
                ),
                if (place.phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(place.phone,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makeCall(place),
                        icon: const Icon(Icons.call_rounded,
                            size: 18),
                        label: Text('Call',
                            style:
                                GoogleFonts.poppins(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          side: BorderSide(
                              color: color.withValues(alpha: 0.5)),
                          foregroundColor: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDirections(
                            place.lat, place.lng),
                        icon: const Icon(
                            Icons.directions_rounded,
                            size: 18),
                        label: Text('Navigate',
                            style:
                                GoogleFonts.poppins(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Map View using flutter_map (OpenStreetMap - FREE) ─────────────────

  Widget _buildMapView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_userLat, _userLng),
        initialZoom: 13.0,
      ),
      children: [
        // OpenStreetMap tile layer (FREE, no API key needed)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.my_first_app',
        ),

        // User location marker
        MarkerLayer(
          markers: [
            // User's own location (blue dot)
            Marker(
              point: LatLng(_userLat, _userLng),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Place markers
            ..._filteredPlaces.map((place) {
              final color = _getTypeColor(place.type);
              final icon = _getTypeIcon(place.type);
              return Marker(
                point: LatLng(place.lat, place.lng),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => _showPlaceBottomSheet(place),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  void _showPlaceBottomSheet(NearbyPlace place) {
    final color = _getTypeColor(place.type);
    final icon = _getTypeIcon(place.type);

    showModalBottomSheet(
      context: context,
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(place.type,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${place.distanceKm.toStringAsFixed(1)} km away',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.place_rounded,
                      size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(place.address,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textLight)),
                  ),
                ],
              ),
              if (place.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_rounded,
                        size: 16, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(place.phone,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _makeCall(place);
                      },
                      icon: const Icon(Icons.call_rounded, size: 20),
                      label: Text('Call',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        foregroundColor: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openDirections(place.lat, place.lng);
                      },
                      icon:
                          const Icon(Icons.directions_rounded, size: 20),
                      label: Text('Navigate',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
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
}

// ─── Filter Chip with Icon ──────────────────────────────────────────────────

class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? chipColor
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : chipColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Spinning Refresh Icon ──────────────────────────────────────────────────

class _SpinningRefreshIcon extends StatefulWidget {
  final bool isSpinning;
  const _SpinningRefreshIcon({required this.isSpinning});

  @override
  State<_SpinningRefreshIcon> createState() => _SpinningRefreshIconState();
}

class _SpinningRefreshIconState extends State<_SpinningRefreshIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isSpinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinningRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _controller.repeat();
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: const Icon(Icons.refresh_rounded, size: 18),
        );
      },
    );
  }
}
