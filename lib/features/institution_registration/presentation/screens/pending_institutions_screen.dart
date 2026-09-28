import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bridge_mobile/features/institutions/domain/entities/institution_entities.dart';
import 'package:bridge_mobile/features/institutions/presentation/controllers/institution_providers.dart';
import 'package:bridge_mobile/features/institutions/presentation/controllers/institution_state.dart';
import 'pending_institution_detail_screen.dart';

/// Super Admin screen showing the queue of pending institution registrations.
class PendingInstitutionsScreen extends ConsumerStatefulWidget {
  const PendingInstitutionsScreen({super.key});

  @override
  ConsumerState<PendingInstitutionsScreen> createState() =>
      _PendingInstitutionsScreenState();
}

class _PendingInstitutionsScreenState
    extends ConsumerState<PendingInstitutionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pendingInstitutionsProvider.notifier).loadPending(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingInstitutionsProvider);

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
              'Pending Registrations',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Super Admin Dashboard',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF2563EB)),
            onPressed: () =>
                ref.read(pendingInstitutionsProvider.notifier).loadPending(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: () =>
            ref.read(pendingInstitutionsProvider.notifier).loadPending(),
        child: switch (state) {
          PendingInstitutionsLoading() => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          PendingInstitutionsError(:final message) => _ErrorState(
              message: message,
              onRetry: () =>
                  ref.read(pendingInstitutionsProvider.notifier).loadPending(),
            ),
          PendingInstitutionsLoaded(:final institutions) when
                  institutions.isEmpty =>
            const _EmptyState(),
          PendingInstitutionsLoaded(:final institutions) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: institutions.length,
              itemBuilder: (_, i) => _PendingCard(
                institution: institutions[i],
                onTap: () => _openDetail(institutions[i]),
              ),
            ),
          InstitutionActionLoading() => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  void _openDetail(PendingInstitution institution) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: const [],
          child: PendingInstitutionDetailScreen(institution: institution),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final PendingInstitution institution;
  final VoidCallback onTap;

  const _PendingCard({required this.institution, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        institution.name.isNotEmpty
                            ? institution.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PENDING',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.person_outline_rounded,
                    label: institution.adminName ?? 'Unknown Admin',
                  ),
                  const SizedBox(width: 12),
                  _MetaChip(
                    icon: Icons.insert_drive_file_outlined,
                    label:
                        '${institution.documentCount} doc${institution.documentCount != 1 ? 's' : ''}',
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Color(0xFFCBD5E1)),
                ],
              ),
              if (institution.submittedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Submitted: ${_formatDate(institution.submittedAt!)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
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
            child: const Icon(Icons.inbox_rounded,
                size: 40, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'No pending registrations',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All institution requests have been reviewed.',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF94A3B8)),
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
            Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
