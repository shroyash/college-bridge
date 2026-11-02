import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/super_admin_models.dart';
import '../controllers/super_admin_providers.dart';
import 'super_admin_profile_modal.dart';
import 'super_admin_shell.dart';
import 'super_admin_requests_screen.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(superAdminDashboardProvider.notifier).loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(superAdminTabProvider, (previous, next) {
      if (next == 0) {
        ref.read(superAdminDashboardProvider.notifier).loadDashboard();
      }
    });

    final state = ref.watch(superAdminDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Super Admin',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Support & Issue Tickets',
            icon: const Icon(Icons.confirmation_number_outlined,
                color: Color(0xFF2563EB)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SuperAdminRequestsScreen(),
                ),
              );
            },
          ),
          // REMOVED: System Broadcast IconButton
          // REMOVED: NotificationBadgeIcon
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => SuperAdminProfileModal.show(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF475569),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: () =>
            ref.read(superAdminDashboardProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Global System Health Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Global System Health',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All tenant clusters operational',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bar_chart_rounded,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'OPTIMAL',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. Multi-Tenant Overview Grid ──
              Text(
                'MULTI-TENANT OVERVIEW',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              if (state.isLoading && state.stats == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  ),
                )
              else if (state.error != null && state.stats == null)
                _ErrorCard(
                  error: state.error!,
                  onRetry: () => ref
                      .read(superAdminDashboardProvider.notifier)
                      .loadDashboard(),
                )
              else if (state.stats != null)
                _MetricGrid(stats: state.stats!),

              const SizedBox(height: 24),

              // ── 3. Pending Institutions Queue ──
              Text(
                'PENDING INSTITUTIONS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              if (state.pendingQueue.isEmpty)
                const _EmptyPendingCard()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.pendingQueue.length,
                  itemBuilder: (_, index) {
                    final inst = state.pendingQueue[index];
                    return _PendingReviewCard(institution: inst);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric Grid matching mock layout
// ─────────────────────────────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  final SuperAdminDashboardStats stats;

  const _MetricGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Total Institutions
        _StatCard(
          title: 'Total\ninstitutions',
          value: '${stats.totalInstitutions}',
          icon: Icons.business_rounded,
          iconColor: const Color(0xFF475569),
          titleColor: const Color(0xFF64748B),
          valueColor: const Color(0xFF0F172A),
        ),

        // 2. Pending Approval (Orange left accent border)
        _StatCard(
          title: 'Pending\napproval',
          value: '${stats.pendingInstitutions}',
          icon: Icons.assignment_late_outlined,
          iconColor: const Color(0xFFF97316),
          titleColor: const Color(0xFFF97316),
          valueColor: const Color(0xFFF97316),
          leftAccentColor: const Color(0xFFF97316),
        ),

        // 3. Active Institutions
        _StatCard(
          title: 'Active\ninstitutions',
          value: '${stats.activeInstitutions}',
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          titleColor: const Color(0xFF64748B),
          valueColor: const Color(0xFF0F172A),
        ),

        // 4. Suspended (Red left accent border)
        _StatCard(
          title: 'Suspended',
          value: '${stats.suspendedInstitutions}',
          icon: Icons.block_rounded,
          iconColor: const Color(0xFFDC2626),
          titleColor: const Color(0xFFDC2626),
          valueColor: const Color(0xFFDC2626),
          leftAccentColor: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color titleColor;
  final Color valueColor;
  final Color? leftAccentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.titleColor,
    required this.valueColor,
    this.leftAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Optional Left Color Accent Bar
          if (leftAccentColor != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: leftAccentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending Institution Card matching mock layout
// ─────────────────────────────────────────────────────────────────────────────

class _PendingReviewCard extends ConsumerWidget {
  final SuperAdminPendingInstitution institution;

  const _PendingReviewCard({required this.institution});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution.institutionName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // Switch to Institutions tab (Index 2 in updated 4-tab shell)
              ref.read(superAdminTabProvider.notifier).state = 2;
              ref.read(superAdminInstitutionsProvider.notifier).setTab(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Review',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (institution.code != null && institution.code!.isNotEmpty) {
      parts.add('Code ${institution.code}');
    }
    if (institution.location.isNotEmpty) {
      parts.add(institution.location);
    }
    if (parts.isEmpty) {
      parts.add('Submitted recently');
    }
    return parts.join(' · ');
  }
}

class _EmptyPendingCard extends StatelessWidget {
  const _EmptyPendingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          'No pending institution registration requests.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF991B1B)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          )
        ],
      ),
    );
  }
}