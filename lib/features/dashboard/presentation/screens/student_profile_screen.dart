import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/dashboard_providers.dart';
import '../controllers/profile_notifier.dart';
import '../widgets/change_email_modal.dart';
import '../widgets/change_password_modal.dart';
import 'help_and_support_screen.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLogout;

  const StudentProfileScreen({super.key, this.onBack, this.onLogout});

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileNotifierProvider.notifier).fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2563EB), size: 24),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: profileState is ProfileLoading
            ? const Center(child: CircularProgressIndicator())
            : profileState is ProfileFailure
                ? _buildError((profileState).message)
                : profileState is ProfileSuccess
                    ? _buildContent(context, profileState)
                    : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(profileNotifierProvider.notifier).fetchProfile(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildContent(BuildContext context, ProfileSuccess state) {
    final p = state.profile;
    final faculty = p.studentDetails?.faculty ?? 'BCA';
    final semesterRaw = p.studentDetails?.semester ?? '1';
    // semesterRaw may be a number string like "3" or a label like "3rd"; normalise to display
    final semesterDisplay = int.tryParse(semesterRaw) != null
        ? '${semesterRaw}th Sem'
        : semesterRaw;
    final rollNo = 'BCA/${DateTime.now().year}/0${p.userId}';
    final email = p.email.isNotEmpty ? p.email : 'student@college.edu';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // ── Avatar + Name + Roll Card ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: state.isSaving ? null : () => _pickAndUploadImage(),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFEFF6FF),
                        backgroundImage: p.imageUrl != null ? NetworkImage(p.imageUrl!) : null,
                        child: p.imageUrl == null
                            ? Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: state.isSaving ? null : () => _pickAndUploadImage(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: state.isSaving
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Roll No: $rollNo',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: state.isSaving ? null : () => _showEditDialog(context, p.name),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                  label: const Text('Edit Name', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Academic Info Cards ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  label: 'FACULTY / PROGRAM',
                  value: faculty,
                  icon: Icons.school_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  label: 'SEMESTER',
                  value: semesterDisplay,
                  icon: Icons.layers_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Account Settings Section ─────────────────────────────────────────────
          _sectionHeader('Account Settings'),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.email_outlined,
            title: 'Change Email',
            subtitle: email,
            onTap: () => ChangeEmailModal.show(context, email),
          ),
          _settingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Secure your account with a new password',
            onTap: () => ChangePasswordModal.show(context),
          ),
          _settingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'Campus support & FAQs',
            onTap: () => _showHelpSupportModal(context),
          ),
          const SizedBox(height: 20),

          // ── Logout button ────────────────────────────────────────────────
          _logoutButton(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoTile({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: TextButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
        label: const Text(
          'Logout Account',
          style: TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Modals & Interactivity ──────────────────────────────────────────────────

  void _showHelpSupportModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpAndSupportScreen(),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final ok = await ref.read(profileNotifierProvider.notifier).uploadProfileImage(File(picked.path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Profile photo updated!' : 'Failed to upload photo'),
        backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ));
    }
  }

  void _showEditDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await ref.read(profileNotifierProvider.notifier).updateName(controller.text.trim());
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(ok ? 'Profile updated!' : 'Failed to update profile'),
                  backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(profileNotifierProvider.notifier).logoutAndClear();
              if (widget.onLogout != null) {
                widget.onLogout!();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
