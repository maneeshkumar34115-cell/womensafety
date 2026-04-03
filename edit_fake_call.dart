import "dart:io";

void main() {
  var p = r"c:\Users\manee\OneDrive\Desktop\Women_safe\my_first_app\lib\screens\fake_call\fake_call_screen.dart";
  var c = File(p).readAsStringSync();

  c = c.replaceAll("import 'dart:io';", "import 'dart:io';\nimport 'dart:ui';");
  
  c = c.replaceFirst(
    "  String _callerName = 'Papa';\n  String _callerNumber = '+91 98765 43210';",
    "  List<Map<String, String>> _contacts = [\n    {'id': '1', 'name': 'Papa', 'phone': '+91 98765 43210'},\n  ];\n  String _selectedContactId = '1';\n\n  Map<String, String> get _currentContact => _contacts.firstWhere((c) => c['id'] == _selectedContactId, orElse: () => _contacts.first);"
  );

  c = c.replaceFirst(
    "'Fake call from \"`$_callerName\" in `$_selectedDelay',",
    "'Fake call from \"`${_currentContact['name']}\" in `$_selectedDelay',"
  );
  
  c = c.replaceFirst(
    "              Text(\n                _callerName,",
    "              Text(\n                _currentContact['name']!,"
  );
  
  c = c.replaceFirst(
    "                    : '`$_callerNumber  •  Incoming Call',",
    "                    : '`${_currentContact['phone']}  •  Incoming Call',"
  );
  
  // Delete the old _showCallerSetup entirely via regex
  c = c.replaceAll(RegExp(r"  void _showCallerSetup\(\) \{.*?(?=  @override\n  Widget build)", dotAll: true), "");

  // Replace caller card with new card + dashed button
  c = c.replaceAll(RegExp(r"            // Caller info.*?            const SizedBox\(height: 24\),", dotAll: true), 
"""            // Caller info
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
                      child: Text('??', style: TextStyle(fontSize: 24)),
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
                              '?? Voice attached',
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
            const SizedBox(height: 24),""");

  String newMethods = """
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
                    color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFBE4E4),
                      child: Text('??', style: TextStyle(fontSize: 20)),
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
                        'Voice "\${voice['name']}" selected',
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
""";
  c = c.replaceFirst("  @override", newMethods);

  String painterClass = """
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
""";
  
  c = c + painterClass;
  
  File(p).writeAsStringSync(c);
  // Also write to new projects folder so everything is completely in sync!
  var p2 = r"C:\projects\my_first_app\lib\screens\fake_call\fake_call_screen.dart";
  if (File(p2).existsSync()) {
      File(p2).writeAsStringSync(c);
  }
}
