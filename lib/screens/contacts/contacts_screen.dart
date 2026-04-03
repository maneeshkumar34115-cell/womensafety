/// SafeGuardHer - Emergency Contacts Screen
/// ReorderableListView with add/delete, max 5 contacts,
/// stored via ContactsService.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/emergency_contact.dart';
import '../../services/contacts_service.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Emergency Contacts',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: Consumer<ContactsService>(
        builder: (_, service, __) {
          if (service.contacts.length >= 5) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showAddContactDialog(context),
            icon: const Icon(Icons.person_add_rounded),
            label: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          );
        },
      ),
      body: Consumer<ContactsService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (service.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No emergency contacts yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add up to 5 trusted contacts',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${service.contacts.length}/5 contacts',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Long press and drag to reorder priority',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 12),

                // Reorderable list
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: service.contacts.length,
                    onReorder: (oldIndex, newIndex) {
                      service.reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final contact = service.contacts[index];
                      return Card(
                        key: ValueKey(contact.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              contact.name[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            contact.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.phone,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                contact.relation,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Priority badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.danger, size: 22),
                                onPressed: () {
                                  service.deleteContact(contact.id);
                                  showAppSnackBar(context, 'Contact removed');
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Trusted Contact',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Name',
                  hint: 'e.g. Papa, Didi',
                  prefixIcon: Icons.person_outline,
                  controller: nameCtrl,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Phone',
                  hint: '+91 98765 43210',
                  prefixIcon: Icons.phone_outlined,
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone is required';
                    if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Relationship',
                  hint: 'Father, Friend, Sibling',
                  prefixIcon: Icons.favorite_border,
                  controller: relationCtrl,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Relation is required'
                      : null,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Save Contact',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final service =
                        Provider.of<ContactsService>(ctx, listen: false);
                    service.addContact(EmergencyContact(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      relation: relationCtrl.text.trim(),
                    ));
                    Navigator.pop(ctx);
                    showAppSnackBar(context, 'Contact added!');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
