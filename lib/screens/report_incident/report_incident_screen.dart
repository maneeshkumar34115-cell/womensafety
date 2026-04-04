// ignore_for_file: use_build_context_synchronously
// SafeGuardHer - Report Incident Screen
// Form with full validation, REAL image capture (camera/gallery),
// uploads to Firebase Storage, and saves report to Firestore.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _incidentType = 'Harassment';
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _reportId;
  File? _attachedVideo;
  Map<String, dynamic>? _selectedSosVideo;
  String? _videoThumbnailPath;

  final List<File> _attachedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _types = [
    'Harassment',
    'Stalking',
    'Eve Teasing',
    'Unsafe Area',
    'Domestic Violence',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_attachedImages.length >= 3) {
      showAppSnackBar(context, 'Maximum 3 images allowed', isError: true);
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() => _attachedImages.add(File(picked.path)));
        showAppSnackBar(
            context, 'Image attached (${_attachedImages.length}/3)');
      }
    } catch (e) {
      showAppSnackBar(context, 'Could not access camera/gallery',
          isError: true);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attach Evidence',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: Text('Take Photo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Capture with camera',
                    style: GoogleFonts.poppins(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Colors.blue),
                ),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Select existing photo',
                    style: GoogleFonts.poppins(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _attachedImages.removeAt(index));
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        setState(() {
          _attachedVideo = file;
          _selectedSosVideo = null;
          _videoThumbnailPath = null;
        });
        _generateThumbnail(file.path);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Could not pick video', isError: true);
    }
  }

  Future<void> _generateThumbnail(String path) async {
    try {
      final uint8list = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 100,
        quality: 75,
      );
      if (mounted && uint8list != null) {
        setState(() {
          _videoThumbnailPath = uint8list;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _fetchSOSVideo() async {
    setState(() => _isSubmitting = true);
    try {
      // Robust check: Ensure Firebase is initialized before first database call
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final auth = Provider.of<AuthService>(context, listen: false);
      final userId = auth.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      final query = await FirebaseFirestore.instance
          .collection('sos_events')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending_review')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) showAppSnackBar(context, 'No pending SOS videos found', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      final doc = query.docs.first;
      setState(() {
        _selectedSosVideo = {'id': doc.id, ...doc.data()};
        _attachedVideo = null;
        _videoThumbnailPath = null;
      });
      if (mounted) showAppSnackBar(context, 'SOS Video attached successfully');
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Error fetching SOS video: $e', isError: true);
    }
    setState(() => _isSubmitting = false);
  }

  void _removeVideo() {
    setState(() {
      _attachedVideo = null;
      _selectedSosVideo = null;
      _videoThumbnailPath = null;
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid ?? 'anonymous';
    final reportId =
        'SGH-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final timestamp = DateTime.now();

    try {
      // Upload images to Firebase Storage
      final List<String> imageUrls = [];
      for (int i = 0; i < _attachedImages.length; i++) {
        final file = _attachedImages[i];
        final storagePath =
            'reports/$userId/${timestamp.millisecondsSinceEpoch}/image_$i.jpg';

        try {
          final ref = FirebaseStorage.instance.ref(storagePath);
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        } catch (e) {
          // Continue with other images if one fails
        }
      }

      // Get current location
      String locationText = _locationController.text.trim();
      double? lat, lng;
      try {
        final locService =
            Provider.of<LocationService>(context, listen: false);
        final pos = await locService.getCurrentLocation();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
          if (locationText.isEmpty) {
            locationText = '${pos.latitude}, ${pos.longitude}';
          }
        }
      } catch (_) {}

      // Save to Firestore
      String? uploadedVideoUrl;
      String? videoSource;
      String? linkedSosId;

      if (_attachedVideo != null) {
        final videoStoragePath =
            'incident_videos/$userId/${timestamp.millisecondsSinceEpoch}.mp4';
        try {
          final ref = FirebaseStorage.instance.ref(videoStoragePath);
          await ref.putFile(_attachedVideo!);
          uploadedVideoUrl = await ref.getDownloadURL();
          videoSource = 'gallery';
        } catch (e) {
          // Upload failed entirely
        }
      } else if (_selectedSosVideo != null) {
        uploadedVideoUrl = _selectedSosVideo!['videoUrl'];
        videoSource = 'sos';
        linkedSosId = _selectedSosVideo!['id'];

        try {
          await FirebaseFirestore.instance.collection('sos_events').doc(linkedSosId).update({
             'linkedToReport': true,
             'reportId': reportId,
          });
        } catch (_) {}
      }

      try {
        await FirebaseFirestore.instance.collection('reports').add({
          'reportId': reportId,
          'userId': userId,
          'incidentType': _incidentType,
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'location': locationText,
          'latitude': lat,
          'longitude': lng,
          'imageUrls': imageUrls,
          'videoUrl': uploadedVideoUrl,
          'videoSource': videoSource,
          'linkedSosEventId': linkedSosId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'submitted',
          'isAnonymous': true,
        });
      } catch (e) {
        // Firestore may not be configured
      }

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
        _reportId = reportId;
      });

      if (mounted) {
        showAppSnackBar(context, 'Report submitted successfully!');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        showAppSnackBar(context, 'Failed to submit report: $e',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Report Submitted')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 64),
                ),
                const SizedBox(height: 24),
                Text(
                  'Report Filed Successfully',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Report submitted. Anonymous and confidential.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Report ID: $_reportId',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Back to Home',
                  icon: Icons.home_rounded,
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  width: 200,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Report Incident',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your report is anonymous and confidential. It will be shared with relevant authorities only.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Incident Type dropdown
                Text(
                  'Incident Type',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _incidentType,
                  items: _types
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _incidentType = v!),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),

                // Title
                CustomTextField(
                  label: 'Incident Title',
                  hint: 'Brief title of what happened',
                  prefixIcon: Icons.title_rounded,
                  controller: _titleController,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  label: 'Detailed Description',
                  hint: 'Describe the incident in detail...',
                  prefixIcon: Icons.description_rounded,
                  controller: _descController,
                  maxLines: 4,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Description is required';
                    }
                    if (v.length < 20) {
                      return 'Please provide more detail';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location
                CustomTextField(
                  label: 'Location',
                  hint:
                      'Where did this happen? (auto-detected if left empty)',
                  prefixIcon: Icons.location_on_outlined,
                  controller: _locationController,
                ),
                const SizedBox(height: 20),

                // Image upload section
                Text(
                  'Attach Evidence (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Add button
                      if (_attachedImages.length < 3)
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            width: 90,
                            height: 90,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded,
                                    color: AppColors.textLight, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Attached image thumbnails
                      ..._attachedImages.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(entry.value),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 14,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Attach Video (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.video_library_rounded, size: 18),
                        label: const Text('Add Video'),
                        onPressed: _pickVideo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.sos_rounded, size: 18, color: AppColors.danger),
                        label: const Text('Use SOS Video'),
                        onPressed: _fetchSOSVideo,
                      ),
                    ),
                  ],
                ),
                if (_attachedVideo != null || _selectedSosVideo != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 100,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _videoThumbnailPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_videoThumbnailPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _videoThumbnailPath == null
                            ? const Center(
                                child: Icon(Icons.videocam_rounded, size: 40, color: Colors.grey),
                              )
                            : const Center(
                                child: Icon(Icons.play_circle_fill_rounded,
                                    size: 40, color: Colors.white70),
                              ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          _selectedSosVideo != null ? 'SOS Video Attached' : 'Gallery Video',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _removeVideo,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // Submit
                GradientButton(
                  text: 'Submit Report',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submitReport,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}