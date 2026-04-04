
// SafeGuardHer - Fake Call Screen
// Full incoming call simulation with voice recorder for family members.
// Records audio, uploads to Firebase Storage, plays during fake call.
// ignore_for_file: use_build_context_synchronously, unused_field

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/auth_service.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with SingleTickerProviderStateMixin {
  String _selectedDelay = '5s';
  bool _callActive = false;
  bool _callAnswered = false;
  int _callDuration = 0;
  Timer? _ringTimer;
  Timer? _callTimer;
  final List<Map<String, String>> _contacts = [
    {'id': '1', 'name': 'Papa', 'phone': '+91 98765 43210'},
  ];
  String _selectedContactId = '1';
  String? _selectedVoiceUrl;

  Map<String, String> get _currentContact => _contacts.firstWhere(
        (c) => c['id'] == _selectedContactId,
        orElse: () => _contacts.first,
      );

  // Voice recording
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  List<Map<String, dynamic>> _savedVoices = [];

  late AnimationController _ringAnimation;

  final Map<String, int> _delays = {
    '5s': 5,
    '30s': 30,
    '1 min': 60,
    '5 min': 300,
  };

  @override
  void initState() {
    super.initState();
    _ringAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadVoices();
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _callTimer?.cancel();
    _ringAnimation.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final userId = auth.currentUser?.uid ?? 'default';
      final snapshot = await FirebaseFirestore.instance
          .collection('fake_call_voices')
          .doc(userId)
          .collection('voices')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _savedVoices = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
      }
    } catch (_) {
      // Firestore may not be configured
    }
  }

  void _scheduleFakeCall() {
    final delay = _delays[_selectedDelay] ?? 5;
    showAppSnackBar(
      context,
      'Fake call from "${_currentContact['name']}" in $_selectedDelay',
    );

    _ringTimer = Timer(Duration(seconds: delay), () {
      if (mounted) {
        setState(() => _callActive = true);
        _ringAnimation.repeat(reverse: true);
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _acceptCall() {
    _ringAnimation.stop();
    setState(() => _callAnswered = true);
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
    });

    // Play recorded voice if selected
    if (_selectedVoiceUrl != null && _selectedVoiceUrl!.isNotEmpty) {
      _player.play(UrlSource(_selectedVoiceUrl!));
    }
  }

  void _endCall() {
    _ringTimer?.cancel();
    _callTimer?.cancel();
    _ringAnimation.stop();
    _player.stop();
    setState(() {
      _callActive = false;
      _callAnswered = false;
      _callDuration = 0;
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Voice Recording ───────────────────────────────────────────
  Future<void> _showRecordDialog() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Record Caller Voice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: CustomTextField(
          label: 'Caller Name',
          hint: 'e.g. Papa, Bhaiya, Boss',
          prefixIcon: Icons.person,
          controller: nameCtrl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text),
            child: Text(
              'Start Recording',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _startRecording(result);
    }
  }

  Future<void> _startRecording(String voiceName) async {
    final micPerm = await Permission.microphone.request();
    if (!micPerm.isGranted) {
      if (mounted) {
        showAppSnackBar(context, 'Microphone permission denied', isError: true);
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() => _isRecording = true);

      // Show recording bottom sheet
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _RecordingSheet(
          voiceName: voiceName,
          onStop: () async {
            Navigator.pop(ctx);
            await _stopRecording(voiceName, path);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Recording error: $e', isError: true);
      }
    }
  }

  Future<void> _stopRecording(String voiceName, String filePath) async {
    final recordPath = await _recorder.stop();
    setState(() => _isRecording = false);

    final actualPath = recordPath ?? filePath;
    final file = File(actualPath);
    if (!await file.exists()) {
      if (mounted) {
        showAppSnackBar(context, 'Recording file not found', isError: true);
      }
      return;
    }

    // Upload to Firebase Storage
    String storageUrl = '';
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final userId = auth.currentUser?.uid ?? 'default';
      final storagePath =
          'fake_call_voices/$userId/${voiceName.replaceAll(' ', '_')}.m4a';
      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putFile(file);
      storageUrl = await ref.getDownloadURL();

      // Save metadata to Firestore
      await FirebaseFirestore.instance
          .collection('fake_call_voices')
          .doc(userId)
          .collection('voices')
          .add({
            'name': voiceName,
            'storageUrl': storageUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await _loadVoices();

      if (mounted) {
        showAppSnackBar(context, 'Voice "$voiceName" saved!');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Upload error: $e', isError: true);
      }
    }
  }

  void _showAddEditContactDialog({Map<String, String>? contact}) {
    final isEdit = contact != null;
    final nameCtrl = TextEditingController(text: isEdit ? contact['name'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? contact['phone'] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Contact' : 'Add New Contact',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Caller Name',
              hint: 'Papa',
              prefixIcon: Icons.person,
              controller: nameCtrl,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Phone Number',
              hint: '+91 98765 43210',
              prefixIcon: Icons.phone,
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              setState(() {
                if (isEdit) {
                  final index = _contacts.indexWhere((c) => c['id'] == contact['id']);
                  if (index != -1) {
                    _contacts[index] = {
                      'id': contact['id']!,
                      'name': nameCtrl.text,
                      'phone': phoneCtrl.text,
                    };
                  }
                } else {
                  final newId = DateTime.now().millisecondsSinceEpoch.toString();
                  _contacts.add({
                    'id': newId,
                    'name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                  });
                  _selectedContactId = newId;
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save' : 'Add', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     'Select Contact',
                     style: GoogleFonts.poppins(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 12),
               ..._contacts.map((contact) {
                 final isSelected = _selectedContactId == contact['id'];
                 return Container(
                   margin: const EdgeInsets.only(bottom: 8),
                   decoration: BoxDecoration(
                     color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                     borderRadius: BorderRadius.circular(12),
                     border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                   ),
                   child: ListTile(
                     leading: const CircleAvatar(
                       backgroundColor: Color(0xFFFBE4E4),
                       child: Text('🧑', style: TextStyle(fontSize: 20)),
                     ),
                     title: Text(contact['name']!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                     subtitle: Text(contact['phone']!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                     trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           icon: const Icon(Icons.edit_rounded, color: AppColors.textLight, size: 20),
                           onPressed: () {
                             Navigator.pop(ctx);
                             _showAddEditContactDialog(contact: contact);
                           },
                         ),
                         IconButton(
                           icon: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
                           onPressed: () {
                             if (_contacts.length <= 1) {
                               showAppSnackBar(context, 'At least 1 contact must remain', isError: true);
                               return;
                             }
                             setState(() {
                               _contacts.removeWhere((c) => c['id'] == contact['id']);
                               if (_selectedContactId == contact['id']) {
                                 _selectedContactId = _contacts.first['id']!;
                               }
                             });
                             Navigator.pop(ctx);
                           },
                         ),
                       ],
                     ),
                     onTap: () {
                       setState(() => _selectedContactId = contact['id']!);
                       Navigator.pop(ctx);
                     },
                   ),
                 );
               }),
               const Divider(height: 32),
               Text(
                 'Caller Voice (optional)',
                 style: GoogleFonts.poppins(
                   fontSize: 14,
                   fontWeight: FontWeight.w500,
                 ),
               ),
               const SizedBox(height: 8),
               if (_savedVoices.isEmpty)
                 Text(
                   'No recorded voices. Tap + to record.',
                   style: GoogleFonts.poppins(
                     fontSize: 12,
                     color: AppColors.textLight,
                   ),
                 )
               else
                 ..._savedVoices.map((voice) {
                   final isSelected = _selectedVoiceUrl == voice['storageUrl'];
                   return ListTile(
                     leading: Icon(
                       isSelected
                           ? Icons.radio_button_checked
                           : Icons.radio_button_off,
                       color: isSelected ? AppColors.primary : AppColors.textLight,
                     ),
                     title: Text(
                       voice['name'] ?? '',
                       style: GoogleFonts.poppins(fontSize: 14),
                     ),
                     onTap: () {
                       setState(() => _selectedVoiceUrl = voice['storageUrl']);
                       setModalState(() {});
                       showAppSnackBar(
                         context,
                         'Voice "${voice['name']}" selected',
                       );
                     },
                     dense: true,
                   );
                 }),
               const SizedBox(height: 16),
             ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen incoming call UI
    if (_callActive) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _ringAnimation,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _callAnswered
                        ? 1.0
                        : 1.0 + (_ringAnimation.value * 0.05),
                    child: child,
                  );
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _currentContact['name']!,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _callAnswered
                    ? _formatDuration(_callDuration)
                    : '${_currentContact['phone']!}  •  Incoming Call',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
              const Spacer(flex: 3),

              if (!_callAnswered) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _acceptCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // In-call controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CallButton(icon: Icons.mic_off_rounded, label: 'Mute'),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _CallButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Speaker',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    }

    // Setup screen
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Fake Call',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_rounded),
            tooltip: 'Record Voice',
            onPressed: _showRecordDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Schedule a Fake Call',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Pick a delay and a simulated call will ring to help you exit any uncomfortable situation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Caller info
            GestureDetector(
              onTap: _showContactPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFFBE4E4),
                      child: Text('🧑', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentContact['name']!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _currentContact['phone']!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                          ),
                          if (_selectedVoiceUrl != null)
                            Text(
                              '🔊 Voice attached',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFFA6C51),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () => _showAddEditContactDialog(),
              child: CustomPaint(
                painter: DashedRectPainter(color: AppColors.primary),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Add New Contact',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Ring after:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: _delays.keys.map((label) {
                final isSelected = _selectedDelay == label;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedDelay = label),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),

            GradientButton(
              text: 'Start Fake Call Timer',
              icon: Icons.timer_rounded,
              onPressed: _scheduleFakeCall,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CallButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _RecordingSheet extends StatefulWidget {
  final String voiceName;
  final VoidCallback onStop;
  const _RecordingSheet({required this.voiceName, required this.onStop});

  @override
  State<_RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends State<_RecordingSheet> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: AppColors.danger, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Recording...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '"${widget.voiceName}"',
            style: GoogleFonts.poppins(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _fmt(_seconds),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Stop & Save',
            icon: Icons.stop_rounded,
            onPressed: widget.onStop,
          ),
        ],
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;

  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    double dashWidth = 6.0;
    double dashSpace = 4.0;
    double distance = 0.0;

    for (var pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}