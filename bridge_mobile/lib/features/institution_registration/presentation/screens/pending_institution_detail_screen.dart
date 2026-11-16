import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clickable.dart';

import 'package:bridge_mobile/features/institutions/domain/entities/institution_entities.dart';
import 'package:bridge_mobile/features/institutions/presentation/controllers/institution_providers.dart';
import 'package:bridge_mobile/features/institutions/presentation/controllers/institution_state.dart';

/// Detail screen for a pending institution. Shows documents, admin info,
/// and Approve / Reject action buttons.
class PendingInstitutionDetailScreen extends ConsumerStatefulWidget {
  final PendingInstitution institution;

  const PendingInstitutionDetailScreen({
    super.key,
    required this.institution,
  });

  @override
  ConsumerState<PendingInstitutionDetailScreen> createState() =>
      _PendingInstitutionDetailScreenState();
}

class _PendingInstitutionDetailScreenState
    extends ConsumerState<PendingInstitutionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingInstitutionsProvider);
    final isActionLoading = state is InstitutionActionLoading &&
        state.institutionId == widget.institution.institutionId;

    ref.listen<PendingInstitutionsState>(pendingInstitutionsProvider, (_, next) {
      if (next is PendingInstitutionsLoaded) {
        // Institution was removed from list (approved/rejected) — pop back
        final stillExists = next.institutions
            .any((i) => i.institutionId == widget.institution.institutionId);
        if (!stillExists && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Action completed successfully ✓'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.of(context).pop();
        }
      } else if (next is PendingInstitutionsError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final inst = widget.institution;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          inst.name,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Institution Info ──
            _SectionCard(
              title: 'Institution Info',
              icon: Icons.business_rounded,
              child: Column(
                children: [
                  _DetailRow('Name', inst.name),
                  _DetailRow('Code', inst.code),
                  _DetailRow('Status', inst.status),
                  if (inst.submittedAt != null)
                    _DetailRow('Submitted', _formatDate(inst.submittedAt!)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Admin Info ──
            _SectionCard(
              title: 'Administrator',
              icon: Icons.manage_accounts_rounded,
              child: Column(
                children: [
                  _DetailRow('Name', inst.adminName ?? '—'),
                  _DetailRow('Email', inst.adminEmail ?? '—'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Documents ──
            _SectionCard(
              title: 'Documents (${inst.documentCount})',
              icon: Icons.folder_rounded,
              child: inst.documents.isEmpty
                  ? Text(
                      'No documents attached.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF94A3B8)),
                    )
                  : Column(
                      children: inst.documents
                          .map((doc) => _DocumentTile(document: doc))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // ── Action buttons ──
            if (isActionLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context),
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Color(0xFFEF4444)),
                      label: Text(
                        'Reject',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(context),
                      icon: const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white),
                      label: Text(
                        'Approve',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Approve Institution?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Approving "${widget.institution.name}" will activate the institution '
          'and its admin account. They will be able to log in immediately.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
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
                  .read(pendingInstitutionsProvider.notifier)
                  .approve(widget.institution.institutionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Approve',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Registration',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for rejection. This will be shown to the submitter.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Rejection reason is required'
                    : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Documents are incomplete or unreadable.',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFCBD5E1)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              ref.read(pendingInstitutionsProvider.notifier).reject(
                    widget.institution.institutionId,
                    reasonCtrl.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Reject',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
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

// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final InstitutionDocument document;

  const _DocumentTile({required this.document});

  bool get _isImage {
    final url = document.documentUrl.toLowerCase();
    return url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: () => _openDocument(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _isImage
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isImage
                    ? Icons.image_rounded
                    : Icons.picture_as_pdf_rounded,
                size: 16,
                color: _isImage
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.documentType,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _isImage ? 'Tap to view image' : 'Tap to view PDF',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _openDocument(BuildContext context) {
    if (_isImage) {
      // Full-screen image viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImageViewerScreen(url: document.documentUrl),
        ),
      );
    } else {
      // For PDFs: open in a WebView dialog (requires webview_flutter or url_launcher)
      // Using a simple dialog for now — replace with flutter_pdfview in production
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            document.documentType,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'PDF preview: ${document.documentUrl}',
            style: GoogleFonts.inter(fontSize: 12),
          ),
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

/// Full-screen image viewer for institution documents.
class _ImageViewerScreen extends StatelessWidget {
  final String url;

  const _ImageViewerScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Document Preview',
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
              : const Icon(Icons.broken_image_rounded,
                  color: Colors.white54, size: 64),
        ),
      ),
    );
  }
}
