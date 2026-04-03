// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - Safety Tips Screen
/// Categories with search, bookmarkable tip cards.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({super.key});

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<int> _bookmarked = {};

  final List<String> _categories = [
    'All', 'Travel', 'Night Safety', 'Online', 'Self Defense', 'Workplace'
  ];

  final List<_SafetyTip> _allTips = [
    _SafetyTip(
      title: 'Share Your Live Location',
      description: 'Always share your real-time location with family members when travelling alone, especially at night.',
      category: 'Travel',
      icon: Icons.share_location_rounded,
    ),
    _SafetyTip(
      title: 'Be Aware of Surroundings',
      description: 'Avoid using headphones in deserted areas. Stay alert and keep checking your surroundings.',
      category: 'Night Safety',
      icon: Icons.visibility_rounded,
    ),
    _SafetyTip(
      title: 'Trust Your Instincts',
      description: 'If a situation feels unsafe, leave immediately. Your gut feeling is your best defense.',
      category: 'Self Defense',
      icon: Icons.psychology_rounded,
    ),
    _SafetyTip(
      title: 'Keep Emergency Numbers Ready',
      description: 'Save Police (100), Women Helpline (1091), and Emergency (112) on speed dial.',
      category: 'Travel',
      icon: Icons.phone_rounded,
    ),
    _SafetyTip(
      title: 'Use Verified Cab Services',
      description: 'Always verify the cab number plate and driver details before getting in. Share trip details with family.',
      category: 'Travel',
      icon: Icons.local_taxi_rounded,
    ),
    _SafetyTip(
      title: 'Protect Online Identity',
      description: 'Never share personal details like home address, phone number, or daily routine on social media.',
      category: 'Online',
      icon: Icons.security_rounded,
    ),
    _SafetyTip(
      title: 'Learn Basic Self-Defense',
      description: 'Join a self-defense class. Key targets — eyes, nose, throat, groin, and shins.',
      category: 'Self Defense',
      icon: Icons.sports_martial_arts_rounded,
    ),
    _SafetyTip(
      title: 'Document Workplace Harassment',
      description: 'Keep written records of any harassment — dates, times, quotes. Report to Internal Complaints Committee.',
      category: 'Workplace',
      icon: Icons.work_rounded,
    ),
    _SafetyTip(
      title: 'Avoid Isolated ATMs at Night',
      description: 'Use ATMs inside malls or busy areas after dark. Always check if anyone is lurking nearby.',
      category: 'Night Safety',
      icon: Icons.atm_rounded,
    ),
    _SafetyTip(
      title: 'Strong Passwords Everywhere',
      description: 'Use unique passwords with uppercase, lowercase, numbers, and symbols. Enable 2FA on all accounts.',
      category: 'Online',
      icon: Icons.lock_rounded,
    ),
  ];

  List<_SafetyTip> get _filteredTips {
    return _allTips.where((tip) {
      final matchesCategory =
          _selectedCategory == 'All' || tip.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          tip.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tip.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Safety Tips',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search tips...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),

          // Category chips
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Tips list
          Expanded(
            child: _filteredTips.isEmpty
                ? Center(
                    child: Text(
                      'No tips found',
                      style: GoogleFonts.poppins(color: AppColors.textLight),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTips.length,
                    itemBuilder: (_, index) {
                      final tip = _filteredTips[index];
                      final tipIndex = _allTips.indexOf(tip);
                      final isBookmarked = _bookmarked.contains(tipIndex);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(tip.icon,
                                        color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tip.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isBookmarked
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: isBookmarked
                                          ? AppColors.primary
                                          : AppColors.textLight,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isBookmarked) {
                                          _bookmarked.remove(tipIndex);
                                        } else {
                                          _bookmarked.add(tipIndex);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tip.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tip.category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SafetyTip {
  final String title;
  final String description;
  final String category;
  final IconData icon;

  const _SafetyTip({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });
}