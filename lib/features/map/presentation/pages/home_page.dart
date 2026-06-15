import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
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
    if (!_ensureAuthenticated(
      message: 'Inicia sesión con Google para gestionar tus mascotas.',
    )) {
      return;
    }

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

  bool _isPrivateTab(int index) => index == 1 || index == 3;

  bool _ensureAuthenticated({
    required String message,
    String redirectLocation = AppRoutes.home,
  }) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.push(AppRoutes.loginWithRedirect(redirectLocation));
    return false;
  }

  void _selectTab(int index) {
    if (_isPrivateTab(index) &&
        !_ensureAuthenticated(
          message: index == 1
              ? 'Inicia sesión con Google para gestionar tus mascotas.'
              : 'Inicia sesión con Google para ver tu perfil.',
        )) {
      return;
    }

    setState(() {
      _currentIndex = index;
      if (index == 2) {
        _mapRefreshKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) => current is AuthUnauthenticated,
      listener: (_, _) {
        if (_isPrivateTab(_currentIndex)) {
          setState(() => _currentIndex = 0);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final user = state is AuthAuthenticated ? state.user : null;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: context.appColors.background,
                body: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _HomeTab(
                      user: user,
                      onOpenPetsSection: _openPetsSection,
                      onOpenReportsSection: _openReportsSection,
                    ),
                    PetsPage(),
                    ReportsMapPage(refreshToken: _mapRefreshKey),
                    _ProfileTab(user: user, isAuthLoading: isLoading),
                  ],
                ),
                bottomNavigationBar: _BottomNav(
                  currentIndex: _currentIndex,
                  onTap: _selectTab,
                ),
              ),
              if (isLoading)
                ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
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
    if (!_ensureAuthenticated(
      message: 'Inicia sesión con Google para ver tus notificaciones.',
      redirectLocation: AppRoutes.notifications,
    )) {
      return;
    }

    await context.push<bool>(AppRoutes.notifications);
    if (!mounted) return;
    setState(() => _notificationsRefreshKey++);
  }

  Future<void> _openLostReportForm() async {
    if (!_ensureAuthenticated(
      message: 'Inicia sesión con Google para crear un reporte.',
      redirectLocation: AppRoutes.lostReportForm,
    )) {
      return;
    }

    final created = await context.push<bool>(AppRoutes.lostReportForm);
    if (created == true && mounted) {
      setState(() => _reportsRefreshKey++);
    }
  }

  Future<void> _openFoundReportForm() async {
    if (!_ensureAuthenticated(
      message: 'Inicia sesión con Google para crear un reporte.',
      redirectLocation: AppRoutes.foundReportForm,
    )) {
      return;
    }

    final created = await context.push<bool>(AppRoutes.foundReportForm);
    if (created == true && mounted) {
      setState(() => _reportsRefreshKey++);
    }
  }

  bool _ensureAuthenticated({
    required String message,
    required String redirectLocation,
  }) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.push(AppRoutes.loginWithRedirect(redirectLocation));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user?.name?.split(' ').first;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            _buildHeader(firstName),
            SizedBox(height: 24),
            _HeroBanner(onCreateReportTap: _openLostReportForm),
            SizedBox(height: 28),
            _buildSectionTitle('¿Qué necesitas hacer?'),
            SizedBox(height: 16),
            _buildQuickActions(),
            SizedBox(height: 28),
            _buildSectionTitle('Reportes recientes'),
            SizedBox(height: 16),
            _RecentReportsSection(key: ValueKey(_reportsRefreshKey)),
            SizedBox(height: 24),
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ayuda a encontrar mascotas perdidas',
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textSecondary,
                ),
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: context.appColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _QuickActionCard(
          icon: Icons.pets_rounded,
          label: 'Mis Mascotas',
          sublabel: 'Ver y gestionar',
          bgColor: context.appColors.pastelYellow,
          iconColor: AppColors.primary,
          onTap: widget.onOpenPetsSection,
        ),
        _QuickActionCard(
          icon: Icons.feed_rounded,
          label: 'Reportes',
          sublabel: 'Explora la comunidad',
          bgColor: context.appColors.pastelBlue,
          iconColor: Color(0xFF4488EE),
          onTap: widget.onOpenReportsSection,
        ),
        _QuickActionCard(
          icon: Icons.search_off_rounded,
          label: 'Reportar perdida',
          sublabel: 'Avisa a la comunidad',
          bgColor: context.appColors.pastelPink,
          iconColor: context.appColors.lostPet,
          onTap: _openLostReportForm,
        ),
        _QuickActionCard(
          icon: Icons.favorite_rounded,
          label: 'Reportar encontrada',
          sublabel: 'Ayuda al dueño',
          bgColor: context.appColors.pastelGreen,
          iconColor: context.appColors.foundPet,
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
        gradient: LinearGradient(
          colors: [AppColors.primary, context.appColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 24,
            offset: Offset(0, 8),
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
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Perdiste\na tu mascota?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCreateReportTap,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Crear reporte',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.appColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.pets_rounded, size: 80, color: Colors.white),
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
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 16,
              offset: Offset(0, 4),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appColors.textSecondary,
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
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.appColors.border),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: context.appColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: BoxConstraints(minWidth: 18),
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.appColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wifi_tethering_error_rounded,
                  size: 40,
                  color: context.appColors.textHint,
                ),
                SizedBox(height: 12),
                Text(
                  'No pudimos cargar los reportes recientes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
                  ),
                ),
                SizedBox(height: 10),
                TextButton(onPressed: _retry, child: Text('Reintentar')),
              ],
            ),
          );
        }

        final reports = snapshot.data ?? <ReportEntity>[];
        if (reports.isEmpty) {
          return _EmptyReportsCard();
        }

        return Column(
          children: reports
              .map(
                (report) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
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
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_rounded,
            size: 40,
            color: context.appColors.textHint,
          ),
          SizedBox(height: 12),
          Text(
            'Sin reportes recientes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cuando la comunidad publique reportes activos aparecerán aquí.',
            style: TextStyle(fontSize: 13, color: context.appColors.textHint),
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
        title: Text('Cerrar sesión'),
        content: Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.appColors.error,
            ),
            child: Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(AuthSignOutRequested());
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (profile != null)
                      GestureDetector(
                        onTap: () => _openEditProfile(context, profile),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.primaryLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: context.appColors.primaryDark,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Editar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24),

                // Avatar + nombre
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.appColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: profile?.avatarUrl != null
                          ? Image.network(
                              profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profileState is ProfileLoading)
                            Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: context.appColors.border,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                          else
                            Text(
                              profile?.fullName.isNotEmpty == true
                                  ? profile!.fullName
                                  : (widget.user?.name ?? 'Mi perfil'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                          SizedBox(height: 4),
                          Text(
                            widget.user?.email ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Preferencias
                if (profile != null)
                  _buildPreferenceChip(profile.petPreferences),
                if (profileState is ProfileError)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      profileState.message,
                      style: TextStyle(
                        color: context.appColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),

                SizedBox(height: 24),
                _buildThemeSection(),

                SizedBox(height: 32),

                // Botón cerrar sesión
                GestureDetector(
                  onTap: isAuthLoading ? null : () => _confirmSignOut(context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: context.appColors.pastelPink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: context.appColors.error,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isAuthLoading
                                ? context.appColors.textHint
                                : context.appColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.appColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 14)),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return BlocBuilder<ThemeCubit, AppThemePreference>(
      builder: (context, preference) {
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.appColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.contrast_rounded,
                      color: context.appColors.primaryDark,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apariencia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Por defecto usa tu dispositivo',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              SegmentedButton<AppThemePreference>(
                segments: AppThemePreference.values
                    .map(
                      (option) => ButtonSegment<AppThemePreference>(
                        value: option,
                        icon: Icon(option.icon),
                        label: Text(option.label),
                      ),
                    )
                    .toList(),
                selected: {preference},
                onSelectionChanged: (selection) {
                  context.read<ThemeCubit>().setPreference(selection.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  side: WidgetStateProperty.all(
                    BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 24,
              offset: Offset(0, 8),
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
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: Colors.white, size: 22),
                    if (isActive) ...[
                      SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
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
