import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/super_admin_providers.dart';
import '../../domain/entities/super_admin_models.dart';
import 'user_detail_modal.dart';

class SuperAdminUsersScreen extends ConsumerStatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  ConsumerState<SuperAdminUsersScreen> createState() =>
      _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState
    extends ConsumerState<SuperAdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(superAdminUsersProvider.notifier).loadUsers(),
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(superAdminUsersProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminUsersProvider);
    final notifier = ref.read(superAdminUsersProvider.notifier);

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
              'Global User Directory',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Cross-tenant user & admin management',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: () => notifier.loadUsers(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── 1. Metric Header Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _UserMetricCard(
                        title: 'Total Users',
                        value: '${state.totalUsersCount}',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 10),
                      _UserMetricCard(
                        title: 'Students',
                        value: '${state.studentsCount}',
                        icon: Icons.school_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 10),
                      _UserMetricCard(
                        title: 'Teachers',
                        value: '${state.teachersCount}',
                        icon: Icons.badge_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      _UserMetricCard(
                        title: 'Admins',
                        value: '${state.adminsCount}',
                        icon: Icons.admin_panel_settings_rounded,
                        color: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 2. Search & Filter Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            hintText: 'Search by name or email...',
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
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showFilterModal(context, notifier, state),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.tune_rounded,
                          color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── 3. Paginated User List ──
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              )
            else if (state.error != null)
              SliverFillRemaining(
                child: _ErrorState(
                  message: state.error!,
                  onRetry: () => notifier.loadUsers(refresh: true),
                ),
              )
            else if (state.users.isEmpty)
              const SliverFillRemaining(
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < state.users.length) {
                        return _UserCard(user: state.users[index]);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF2563EB)),
                          ),
                        );
                      }
                    },
                    childCount: state.users.length + (state.isMoreLoading ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context, SuperAdminUsersNotifier notifier,
      SuperAdminUsersState state) {
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
                'Filter Users',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                'Role',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['ALL', 'STUDENT', 'TEACHER', 'ADMIN'].map((role) {
                  final isSelected = state.roleFilter == role;
                  return ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (_) {
                      Navigator.pop(context);
                      notifier.setFilter(role: role);
                    },
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Status',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['ALL', 'ACTIVE', 'SUSPENDED'].map((status) {
                  final isSelected = state.statusFilter == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      Navigator.pop(context);
                      notifier.setFilter(status: status);
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
}

// ─────────────────────────────────────────────────────────────────────────────

class _UserMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _UserMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final SuperAdminUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.role.toUpperCase()) {
      'ADMIN' || 'SUPER_ADMIN' => const Color(0xFF7C3AED),
      'TEACHER' => const Color(0xFF0284C7),
      'STUDENT' => const Color(0xFF16A34A),
      _ => const Color(0xFF64748B),
    };

    final isSuspended = user.status.toUpperCase() == 'SUSPENDED';

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
        onTap: () => UserDetailModal.show(context, user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Initials Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: roleColor.withValues(alpha: 0.1),
                backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null || user.profileImage!.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.institutionName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.business_rounded,
                              size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.institutionName!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSuspended ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.status,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSuspended ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
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
          const Icon(Icons.people_outline_rounded,
              size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No matching users found.',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
