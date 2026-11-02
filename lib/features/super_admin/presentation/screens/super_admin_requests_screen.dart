import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clickable.dart';
import '../../../support/data/models/support_ticket_model.dart';
import '../../../support/presentation/controllers/support_providers.dart';

typedef SuperAdminTicketsScreen = SuperAdminRequestsScreen;

class SuperAdminRequestsScreen extends ConsumerStatefulWidget {
  const SuperAdminRequestsScreen({super.key});

  @override
  ConsumerState<SuperAdminRequestsScreen> createState() =>
      _SuperAdminRequestsScreenState();
}

class _SuperAdminRequestsScreenState
    extends ConsumerState<SuperAdminRequestsScreen> {
  final _searchController = TextEditingController();

  final List<String> _statuses = [
    'ALL',
    'OPEN',
    'IN_PROGRESS',
    'RESOLVED',
    'CLOSED',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(superAdminTicketsProvider.notifier).loadTickets(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFD97706);
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB);
      case 'RESOLVED':
        return const Color(0xFF16A34A);
      case 'CLOSED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFFEF3C7);
      case 'IN_PROGRESS':
        return const Color(0xFFDBEAFE);
      case 'RESOLVED':
        return const Color(0xFFDCFCE7);
      case 'CLOSED':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showTicketDetailsModal(SupportTicketModel ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TicketDetailModal(
        ticket: ticket,
        onStatusUpdated: (newStatus) {
          ref
              .read(superAdminTicketsProvider.notifier)
              .updateTicketStatus(ticket.ticketId, newStatus);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminTicketsProvider);
    final notifier = ref.read(superAdminTicketsProvider.notifier);

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
              'Support & Issue Tickets',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Review help requests and bug reports from users',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Refresh tickets',
            onPressed: () => notifier.loadTickets(page: state.currentPage),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => notifier.loadTickets(page: 0),
        child: Column(
          children: [
            // ── Search & Filter Controls ──────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (val) => notifier.search(val),
                      decoration: InputDecoration(
                        hintText: 'Search by ticket #, subject, or user email...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: Color(0xFF64748B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.search('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statuses.map((status) {
                        final isSelected = state.selectedStatus == status;
                        final label = status == 'ALL'
                            ? 'All Tickets'
                            : status.replaceAll('_', ' ');

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            onSelected: (_) => notifier.filterStatus(status),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Ticket Count Summary ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF1F5F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.totalElements} ${state.totalElements == 1 ? 'ticket' : 'tickets'} total',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (state.totalPages > 1)
                    Text(
                      'Page ${state.currentPage + 1} of ${state.totalPages}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),

            // ── Main List Content ─────────────────────────────────────────
            Expanded(
              child: _buildBody(state, notifier),
            ),

            // ── Pagination Footer ─────────────────────────────────────────
            if (state.totalPages > 1)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: (state.currentPage > 0 && !state.isLoading)
                          ? () => notifier.loadTickets(
                              page: state.currentPage - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text('Previous', style: TextStyle(fontSize: 12)),
                    ),
                    Text(
                      'Page ${state.currentPage + 1} of ${state.totalPages}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: (state.currentPage < state.totalPages - 1 &&
                              !state.isLoading)
                          ? () => notifier.loadTickets(
                              page: state.currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('Next', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      SuperAdminTicketsState state, SuperAdminTicketsNotifier notifier) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 12),
            Text('Loading support tickets...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => notifier.loadTickets(page: state.currentPage),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 48,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Issue Tickets Found',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.searchQuery.isNotEmpty
                    ? 'No tickets matching "${state.searchQuery}". Try a different keyword.'
                    : 'There are currently no tickets matching this filter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.tickets.length,
      itemBuilder: (context, index) {
        final ticket = state.tickets[index];
        final statusColor = _getStatusColor(ticket.status);
        final statusBg = _getStatusBgColor(ticket.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Clickable(
            onTap: () => _showTicketDetailsModal(ticket),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          ticket.ticketNumber,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ticket.status.replaceAll('_', ' '),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Subject
                  Text(
                    ticket.subject,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description snippet
                  Text(
                    ticket.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submitter & Date Footer
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 15, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${ticket.userName} (${ticket.userRole})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(ticket.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TicketDetailModal extends StatefulWidget {
  final SupportTicketModel ticket;
  final ValueChanged<String> onStatusUpdated;

  const _TicketDetailModal({
    required this.ticket,
    required this.onStatusUpdated,
  });

  @override
  State<_TicketDetailModal> createState() => _TicketDetailModalState();
}

class _TicketDetailModalState extends State<_TicketDetailModal> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
  }

  void _updateStatus(String newStatus) {
    widget.onStatusUpdated(newStatus);
    setState(() {
      _currentStatus = newStatus;
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket status updated to $newStatus'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: Ticket # + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.ticketNumber,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      t.category,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Text(
                    _currentStatus.replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Submitter Details
            Text(
              'Submitted By',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        t.userName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.userRole,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        t.userEmail,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subject
            Text(
              'Subject',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.subject,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Issue Description',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                t.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Update Actions
            Text(
              'Update Ticket Status',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusButton(
                  label: 'In Progress',
                  isActive: _currentStatus == 'IN_PROGRESS',
                  color: const Color(0xFF2563EB),
                  onTap: () => _updateStatus('IN_PROGRESS'),
                ),
                _StatusButton(
                  label: 'Resolved',
                  isActive: _currentStatus == 'RESOLVED',
                  color: const Color(0xFF16A34A),
                  onTap: () => _updateStatus('RESOLVED'),
                ),
                _StatusButton(
                  label: 'Closed',
                  isActive: _currentStatus == 'CLOSED',
                  color: const Color(0xFF64748B),
                  onTap: () => _updateStatus('CLOSED'),
                ),
                _StatusButton(
                  label: 'Re-open',
                  isActive: _currentStatus == 'OPEN',
                  color: const Color(0xFFD97706),
                  onTap: () => _updateStatus('OPEN'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: isActive ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
