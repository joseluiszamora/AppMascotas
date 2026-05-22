import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/blocs/auth/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth/auth_event.dart';
import '../../../auth/presentation/blocs/auth/auth_state.dart';
import '../../../pets/presentation/pages/pets_page.dart';
import '../../../notifications/domain/usecases/get_unread_notifications_count.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/presentation/blocs/profile_cubit.dart';
import '../../../profile/presentation/blocs/profile_state.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/domain/usecases/get_recent_reports.dart';
import '../../../reports/presentation/widgets/report_list_components.dart';
import 'reports_map_page.dart';

// ─────────────────────────────────────────────
// Shell principal con bottom navigation
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _mapRefreshKey = 0;

  void _openPetsSection() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _openReportsSection() {
    setState(() {
      _currentIndex = 2;
      _mapRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final user = state is AuthAuthenticated ? state.user : null;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  _HomeTab(
                    user: user,
                    onOpenPetsSection: _openPetsSection,
                    onOpenReportsSection: _openReportsSection,
                  ),
                  const PetsPage(),
                  ReportsMapPage(refreshToken: _mapRefreshKey),
                  _ProfileTab(user: user, isAuthLoading: isLoading),
                ],
              ),
              bottomNavigationBar: _BottomNav(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() {
                  _currentIndex = i;
                  if (i == 2) {
                    _mapRefreshKey++;
                  }
                }),
              ),
            ),
            if (isLoading)
              const ColoredBox(
                color: Color(0x55000000),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Tab 0: Inicio
// ─────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab({
    required this.user,
    required this.onOpenPetsSection,
    required this.onOpenReportsSection,
  });

  final UserEntity? user;
  final VoidCallback onOpenPetsSection;
  final VoidCallback onOpenReportsSection;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _reportsRefreshKey = 0;
  int _notificationsRefreshKey = 0;

  Future<void> _openNotifications() async {
    await context.push<bool>(AppRoutes.notifications);
    if (!mounted) return;
    setState(() => _notificationsRefreshKey++);
  }

  Future<void> _openLostReportForm() async {
    final created = await context.push<bool>(AppRoutes.lostReportForm);
    if (created == true && mounted) {
      setState(() => _reportsRefreshKey++);
    }
  }

  Future<void> _openFoundReportForm() async {
    final created = await context.push<bool>(AppRoutes.foundReportForm);
    if (created == true && mounted) {
      setState(() => _reportsRefreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user?.name?.split(' ').first;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildHeader(firstName),
            const SizedBox(height: 24),
            _HeroBanner(onCreateReportTap: _openLostReportForm),
            const SizedBox(height: 28),
            _buildSectionTitle('¿Qué necesitas hacer?'),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 28),
            _buildSectionTitle('Reportes recientes'),
            const SizedBox(height: 16),
            _RecentReportsSection(key: ValueKey(_reportsRefreshKey)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? firstName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola${firstName != null ? ', $firstName' : ''}! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ayuda a encontrar mascotas perdidas',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _NotificationsButton(
          key: ValueKey(_notificationsRefreshKey),
          onTap: _openNotifications,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _QuickActionCard(
          icon: Icons.pets_rounded,
          label: 'Mis Mascotas',
          sublabel: 'Ver y gestionar',
          bgColor: AppColors.pastelYellow,
          iconColor: AppColors.primary,
          onTap: widget.onOpenPetsSection,
        ),
        _QuickActionCard(
          icon: Icons.feed_rounded,
          label: 'Reportes',
          sublabel: 'Explora la comunidad',
          bgColor: AppColors.pastelBlue,
          iconColor: Color(0xFF4488EE),
          onTap: widget.onOpenReportsSection,
        ),
        _QuickActionCard(
          icon: Icons.search_off_rounded,
          label: 'Reportar perdida',
          sublabel: 'Avisa a la comunidad',
          bgColor: AppColors.pastelPink,
          iconColor: AppColors.lostPet,
          onTap: _openLostReportForm,
        ),
        _QuickActionCard(
          icon: Icons.favorite_rounded,
          label: 'Reportar encontrada',
          sublabel: 'Ayuda al dueño',
          bgColor: AppColors.pastelGreen,
          iconColor: AppColors.foundPet,
          onTap: _openFoundReportForm,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onCreateReportTap});

  final VoidCallback onCreateReportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculo decorativo de fondo
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Perdiste\na tu mascota?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCreateReportTap,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Crear reporte',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.pets_rounded, size: 80, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tarjeta de acción rápida
// ─────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatefulWidget {
  const _NotificationsButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<_NotificationsButton> {
  late Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<GetUnreadNotificationsCount>()();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _future,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

// ─────────────────────────────────────────────
// Reportes recientes
// ─────────────────────────────────────────────
class _RecentReportsSection extends StatefulWidget {
  const _RecentReportsSection({super.key});

  @override
  State<_RecentReportsSection> createState() => _RecentReportsSectionState();
}

class _RecentReportsSectionState extends State<_RecentReportsSection> {
  late Future<List<ReportEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<GetRecentReports>()();
  }

  void _retry() {
    setState(() {
      _future = sl<GetRecentReports>()();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReportEntity>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.wifi_tethering_error_rounded,
                  size: 40,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No pudimos cargar los reportes recientes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: _retry, child: const Text('Reintentar')),
              ],
            ),
          );
        }

        final reports = snapshot.data ?? const <ReportEntity>[];
        if (reports.isEmpty) {
          return const _EmptyReportsCard();
        }

        return Column(
          children: reports
              .map(
                (report) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReportListCard(report: report),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _EmptyReportsCard extends StatelessWidget {
  const _EmptyReportsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_rounded, size: 40, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Sin reportes recientes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cuando la comunidad publique reportes activos aparecerán aquí.',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 3: Perfil
// ─────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.user, required this.isAuthLoading});

  final UserEntity? user;
  final bool isAuthLoading;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  @override
  void initState() {
    super.initState();
    // El perfil ya fue cargado por _RouterNotifier al autenticar.
    // Solo recargar si por alguna razón está en estado inicial.
    final state = context.read<ProfileCubit>().state;
    if (widget.user != null && state is ProfileInitial) {
      context.read<ProfileCubit>().loadProfile(widget.user!.id);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  Future<void> _openEditProfile(
    BuildContext context,
    ProfileEntity profile,
  ) async {
    final updated = await context.push<ProfileEntity>(
      AppRoutes.profileEdit,
      extra: profile,
    );
    if (updated != null && context.mounted) {
      context.read<ProfileCubit>().loadProfile(updated.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthLoading = widget.isAuthLoading;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final profile = switch (profileState) {
          ProfileLoaded(:final profile) => profile,
          ProfileUpdating(:final profile) => profile,
          ProfileUpdateSuccess(:final profile) => profile,
          _ => null,
        };

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (profile != null)
                      GestureDetector(
                        onTap: () => _openEditProfile(context, profile),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: AppColors.primaryDark,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Editar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar + nombre
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: profile?.avatarUrl != null
                          ? Image.network(
                              profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profileState is ProfileLoading)
                            Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                          else
                            Text(
                              profile?.fullName.isNotEmpty == true
                                  ? profile!.fullName
                                  : (widget.user?.name ?? 'Mi perfil'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preferencias
                if (profile != null)
                  _buildPreferenceChip(profile.petPreferences),
                if (profileState is ProfileError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      profileState.message,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const Spacer(),

                // Botón cerrar sesión
                GestureDetector(
                  onTap: isAuthLoading ? null : () => _confirmSignOut(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.pastelPink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isAuthLoading
                                ? AppColors.textHint
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreferenceChip(PetPreference pref) {
    final (label, icon) = switch (pref) {
      PetPreference.dogs => ('Perros', '🐶'),
      PetPreference.cats => ('Gatos', '🐱'),
      PetPreference.others => ('Otros animales', '🐾'),
      _ => ('Perros y gatos', '🐾'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom navigation flotante
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.pets_rounded, label: 'Mascotas'),
    (icon: Icons.feed_rounded, label: 'Reportes'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isActive = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: Colors.white, size: 22),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
