import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/super_admin_providers.dart';
import '../../domain/entities/super_admin_models.dart';
import 'institution_detail_modal.dart';

class SuperAdminInstitutionsScreen extends ConsumerStatefulWidget {
  const SuperAdminInstitutionsScreen({super.key});

  @override
  ConsumerState<SuperAdminInstitutionsScreen> createState() =>
      _SuperAdminInstitutionsScreenState();
}

class _SuperAdminInstitutionsScreenState
    extends ConsumerState<SuperAdminInstitutionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(superAdminInstitutionsProvider.notifier).loadData(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminInstitutionsProvider);
    final notifier = ref.read(superAdminInstitutionsProvider.notifier);

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
              'Institutions Management',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Multi-tenant administration & approvals',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Dual Tab Header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'All Institutions',
                    isSelected: state.currentTab == 0,
                    onTap: () => notifier.setTab(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: 'Pending',
                    badgeCount: state.pendingTotalCount,
                    isSelected: state.currentTab == 1,
                    onTap: () => notifier.setTab(1),
                  ),
                ),
              ],
            ),
          ),

          // ── Search & Filter Bar ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => notifier.setSearch(val),
                      decoration: InputDecoration(
                        hintText: state.currentTab == 0
                            ? 'Search institution name or code...'
                            : 'Search pending requests...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                if (state.currentTab == 0) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showFilterDialog(context, notifier, state),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.filter_list_rounded,
                        color: Color(0xFF2563EB)),
                  ),
                ],
              ],
            ),
          ),

          // ── Content Area ──
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: () => notifier.loadData(refresh: true),
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : state.error != null
                      ? _ErrorView(
                          message: state.error!,
                          onRetry: () => notifier.loadData(refresh: true),
                        )
                      : state.currentTab == 0
                          ? state.allInstitutions.isEmpty
                              ? const _EmptyView(
                                  message: 'No institutions found.')
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: state.allInstitutions.length,
                                  itemBuilder: (_, index) {
                                    final inst = state.allInstitutions[index];
                                    return _AllInstitutionCard(
                                      institution: inst,
                                    );
                                  },
                                )
                          : state.pendingInstitutions.isEmpty
                              ? const _EmptyView(
                                  message: 'No pending requests.')
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: state.pendingInstitutions.length,
                                  itemBuilder: (_, index) {
                                    final inst =
                                        state.pendingInstitutions[index];
                                    return _PendingInstitutionCard(
                                      institution: inst,
                                      onViewDetails: () => _showPendingDetailModal(
                                          context, inst, notifier),
                                      onApprove: () => _confirmApprove(
                                          context, notifier, inst),
                                      onReject: () =>
                                          _confirmReject(context, notifier, inst),
                                    );
                                  },
                                ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context,
      SuperAdminInstitutionsNotifier notifier, SuperAdminInstitutionsState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Institutions',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['ALL', 'ACTIVE', 'SUSPENDED'].map((status) {
                  final isSelected = state.statusFilter == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      Navigator.pop(context);
                      notifier.setStatusFilter(status);
                    },
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmApprove(BuildContext context,
      SuperAdminInstitutionsNotifier notifier, SuperAdminPendingInstitution inst) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Institution?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Approving "${inst.institutionName}" will grant access to all its members and activate its administrator.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await notifier.approveInstitution(inst.institutionId);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${inst.institutionName} approved!'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Approve',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context,
      SuperAdminInstitutionsNotifier notifier, SuperAdminPendingInstitution inst) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Registration?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a rejection reason for "${inst.institutionName}":',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Invalid institutional documentation',
                hintStyle: GoogleFonts.inter(fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await notifier.rejectInstitution(inst.institutionId, reason);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Registration rejected.'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Reject',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showPendingDetailModal(
      BuildContext context,
      SuperAdminPendingInstitution inst,
      SuperAdminInstitutionsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PendingDetailModal(
        institution: inst,
        onApprove: () => _confirmApprove(context, notifier, inst),
        onReject: () => _confirmReject(context, notifier, inst),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _AllInstitutionCard extends StatelessWidget {
  final SuperAdminInstitution institution;

  const _AllInstitutionCard({
    required this.institution,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = institution.status == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: () => InstitutionDetailModal.show(context, institution),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.business_rounded
                          : Icons.block_rounded,
                      color: isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFDC2626),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        if (institution.code != null && institution.code!.isNotEmpty)
                          Text(
                            'Code: ${institution.code}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          )
                        else
                          Text(
                            'Location: ${institution.location}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _Badge(status: institution.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => InstitutionDetailModal.show(context, institution, initialTabIndex: 0),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_alt_rounded,
                                  size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                '${institution.totalStudents} Students',
                                style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => InstitutionDetailModal.show(context, institution, initialTabIndex: 1),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school_rounded,
                                  size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                '${institution.totalTeachers} Teachers',
                                style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => InstitutionDetailModal.show(context, institution),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingInstitutionCard extends StatelessWidget {
  final SuperAdminPendingInstitution institution;
  final VoidCallback onViewDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingInstitutionCard({
    required this.institution,
    required this.onViewDetails,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pending_actions_rounded,
                        color: Color(0xFFF97316), size: 22),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          institution.contactPerson != null
                              ? 'Contact: ${institution.contactPerson}'
                              : 'Location: ${institution.location}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Badge(status: 'PENDING'),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.info_outline_rounded,
                        size: 14, color: Color(0xFF2563EB)),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                        backgroundColor: const Color(0xFFFFF1F2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingDetailModal extends StatelessWidget {
  final SuperAdminPendingInstitution institution;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingDetailModal({
    required this.institution,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final inst = institution;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  inst.institutionName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const _Badge(status: 'PENDING'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _DetailInfoRow('Institution Code', inst.code ?? 'N/A'),
          _DetailInfoRow('Contact Person', inst.contactPerson ?? 'N/A'),
          _DetailInfoRow('Contact Email', inst.email ?? 'N/A'),
          _DetailInfoRow('Location', inst.location),
          if (inst.website != null && inst.website!.isNotEmpty)
            _DetailInfoRow('Website', inst.website!),
          if (inst.submittedAt != null)
            _DetailInfoRow('Submitted At', inst.submittedAt!),
          const SizedBox(height: 16),
          Text(
            'Verification Documents (${inst.documents.length})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          if (inst.documents.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    'No verification documents attached.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            Column(
              children: inst.documents.map((doc) {
                final isImage = doc.documentUrl.toLowerCase().endsWith('.jpg') ||
                    doc.documentUrl.toLowerCase().endsWith('.jpeg') ||
                    doc.documentUrl.toLowerCase().endsWith('.png') ||
                    doc.documentUrl.toLowerCase().startsWith('http');
                return InkWell(
                  onTap: () => _openDocument(context, doc),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isImage ? Icons.image_rounded : Icons.description_rounded,
                            size: 20,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.documentType,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                isImage ? 'Tap to preview document' : doc.documentUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded,
                            size: 16, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onReject();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    backgroundColor: const Color(0xFFFFF1F2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Reject Registration',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onApprove();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Approve Institution',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _openDocument(BuildContext context, PendingDocument doc) {
    final url = doc.documentUrl.toLowerCase();
    final isImage = url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.startsWith('http');

    if (isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _DocumentImageViewerScreen(
            url: doc.documentUrl,
            title: doc.documentType,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(doc.documentType,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SelectableText('Document URL:\n${doc.documentUrl}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class _DocumentImageViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const _DocumentImageViewerScreen({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: url.startsWith('http')
              ? Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                )
              : const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _Badge extends StatelessWidget {
  final String status;

  const _Badge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => const Color(0xFF10B981),
      'PENDING' => const Color(0xFFF97316),
      'SUSPENDED' => const Color(0xFFEF4444),
      _ => const Color(0xFF64748B),
    };

    final bgColor = switch (status) {
      'ACTIVE' => const Color(0xFFECFDF5),
      'PENDING' => const Color(0xFFFFF7ED),
      'SUSPENDED' => const Color(0xFFFEF2F2),
      _ => const Color(0xFFF1F5F9),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.domain_disabled_rounded,
              size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
