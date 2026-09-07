import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/institution_entities.dart';
import '../controllers/institution_providers.dart';
import '../controllers/institution_state.dart';

/// Super Admin screen for managing active and suspended institutions.
/// Provides suspend/reactivate actions per institution.
class ManagedInstitutionsScreen extends ConsumerStatefulWidget {
  const ManagedInstitutionsScreen({super.key});

  @override
  ConsumerState<ManagedInstitutionsScreen> createState() =>
      _ManagedInstitutionsScreenState();
}

class _ManagedInstitutionsScreenState
    extends ConsumerState<ManagedInstitutionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(managedInstitutionsProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(managedInstitutionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Institutions',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Active & Suspended',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            onPressed: () =>
                ref.read(managedInstitutionsProvider.notifier).load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: () => ref.read(managedInstitutionsProvider.notifier).load(),
        child: switch (state) {
          ManagedInstitutionsLoading() => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          ManagedInstitutionsError(:final message) => _ErrorState(
              message: message,
              onRetry: () =>
                  ref.read(managedInstitutionsProvider.notifier).load(),
            ),
          ManagedInstitutionsLoaded(:final institutions)
              when institutions.isEmpty =>
            const _EmptyState(),
          ManagedInstitutionsLoaded(:final institutions) =>
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: institutions.length,
              itemBuilder: (_, i) => _InstitutionManageCard(
                institution: institutions[i],
                onSuspend: () =>
                    _confirmSuspend(context, institutions[i]),
                onReactivate: () =>
                    _confirmReactivate(context, institutions[i]),
              ),
            ),
          ManagedInstitutionActionLoading() =>
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  void _confirmSuspend(BuildContext context, ManagedInstitution inst) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Suspend Institution?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Suspending "${inst.name}" will immediately block all logins for that institution\'s users.',
          style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(managedInstitutionsProvider.notifier)
                  .suspend(inst.institutionId);
              _showToast(context, '${inst.name} suspended.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Suspend',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(BuildContext context, ManagedInstitution inst) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reactivate Institution?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Reactivating "${inst.name}" will restore login access for all its users.',
          style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(managedInstitutionsProvider.notifier)
                  .reactivate(inst.institutionId);
              _showToast(context, '${inst.name} reactivated.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Reactivate',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InstitutionManageCard extends StatelessWidget {
  final ManagedInstitution institution;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  const _InstitutionManageCard({
    required this.institution,
    required this.onSuspend,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = institution.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.business_rounded
                        : Icons.pause_circle_rounded,
                    color: isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF97316),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        institution.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Code: ${institution.code}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                _StatusBadge(status: institution.status),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            // ── Action button ──
            SizedBox(
              width: double.infinity,
              child: isActive
                  ? OutlinedButton.icon(
                      onPressed: onSuspend,
                      icon: const Icon(Icons.pause_rounded,
                          size: 16, color: Color(0xFFF97316)),
                      label: Text(
                        'Suspend Institution',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFED7AA)),
                        backgroundColor: const Color(0xFFFFF7ED),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onReactivate,
                      icon: const Icon(Icons.play_circle_rounded,
                          size: 16, color: Color(0xFF10B981)),
                      label: Text(
                        'Reactivate Institution',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        backgroundColor: const Color(0xFFF0FDF4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF97316),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF97316),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.domain_disabled_rounded,
                size: 40, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'No institutions found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
