import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/dashboard_providers.dart';
import '../controllers/profile_notifier.dart';
import '../widgets/change_email_modal.dart';
import '../widgets/change_password_modal.dart';
import 'help_and_support_screen.dart';
import '../../../../core/widgets/clickable.dart';

class TeacherProfileScreen extends ConsumerStatefulWidget {
  final int totalClasses;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  const TeacherProfileScreen({super.key, this.totalClasses = 0, this.onBack, this.onLogout});

  @override
  ConsumerState<TeacherProfileScreen> createState() =>
      _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends ConsumerState<TeacherProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(profileNotifierProvider.notifier).fetchProfile());
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
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(profileNotifierProvider.notifier).fetchProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  /// Converts backend role strings like ROLE_TEACHER → "Teacher"
  String _formatRole(String role) {
    return role
        .replaceAll('ROLE_', '')
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildContent(BuildContext context, ProfileSuccess state) {
    final p = state.profile;
    final empId =
        'EMP-${DateTime.now().year}-${p.teacherId?.toString().padLeft(3, '0') ?? '001'}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // ── Avatar + Name + Role ─────────────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              Clickable(
                onTap: state.isSaving ? null : () => _pickAndUploadImage(),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFCBD5E1),
                  backgroundImage:
                      p.imageUrl != null ? NetworkImage(p.imageUrl!) : null,
                  child: p.imageUrl == null
                      ? const Icon(Icons.person,
                          size: 50, color: Color(0xFF475569))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Clickable(
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
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            p.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.role.isNotEmpty
                ? _formatRole(p.role)
                : 'Teacher',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // ── Edit Profile button ──────────────────────────────────────────
          OutlinedButton.icon(
            onPressed:
                state.isSaving ? null : () => _showEditDialog(context, p.name),
            icon: const Icon(Icons.edit_outlined,
                size: 16, color: Color(0xFF2563EB)),
            label: const Text('Edit Profile',
                style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2563EB)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ),
          const SizedBox(height: 24),

          // ── Employee ID / Classes tiles ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  label: 'EMPLOYEE ID',
                  value: empId,
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  label: 'CLASSES',
                  value: widget.totalClasses.toString(),
                  icon: Icons.school_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Account Settings ─────────────────────────────────────────────
          _sectionHeader('Account Settings'),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.email_outlined,
            title: 'Change Email',
            subtitle: p.email,
            onTap: () => ChangeEmailModal.show(context, p.email),
          ),
          _settingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Secure your account with a new password',
            onTap: () => ChangePasswordModal.show(context),
          ),
          _settingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs and direct campus support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpAndSupportScreen()),
            ),
          ),
          const SizedBox(height: 20),

          // ── Logout ───────────────────────────────────────────────────────
          _logoutButton(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _infoTile(
      {required String label,
      required String value,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              )),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              )),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          )),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF0F172A))),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_right,
            color: Color(0xFF94A3B8), size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 18),
        label: const Text('Logout',
            style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final ok = await ref
        .read(profileNotifierProvider.notifier)
        .uploadProfileImage(File(picked.path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Profile photo updated!' : 'Failed to upload photo'),
        backgroundColor:
            ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ));
    }
  }

  void _showEditDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final ok = await ref
                  .read(profileNotifierProvider.notifier)
                  .updateName(controller.text.trim());
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Profile updated!'
                      : 'Failed to update profile'),
                  backgroundColor:
                      ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(profileNotifierProvider.notifier)
                  .logoutAndClear();
              if (widget.onLogout != null) {
                widget.onLogout!();
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
