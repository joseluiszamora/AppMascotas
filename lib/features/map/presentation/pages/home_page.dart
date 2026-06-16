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
  int _homeRefreshKey = 0;
  int _mapRefreshKey = 0;
  int _reportsPageKey = 0;
  ReportsMapInitialSection _reportsInitialSection =
      ReportsMapInitialSection.list;

  void _openPetsSection() {
    if (!_ensureAuthenticated(
      message: 'Inicia sesión con Google para gestionar tus mascotas.',
    )) {
      return;
    }

    setState(() {
      _currentIndex = 2;
    });
  }

  void _openMapSection() {
    setState(() {
      _currentIndex = 1;
      _reportsInitialSection = ReportsMapInitialSection.map;
      _mapRefreshKey++;
      _reportsPageKey++;
    });
  }

  void _openMyReportsSection() {
    if (!_ensureAuthenticated(
      message: 'Inicia sesión con Google para ver tus avisos.',
    )) {
      return;
    }

    setState(() {
      _currentIndex = 1;
      _reportsInitialSection = ReportsMapInitialSection.mine;
      _mapRefreshKey++;
      _reportsPageKey++;
    });
  }

  bool _isPrivateTab(int index) => index == 2 || index == 3;

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
          message: index == 2
              ? 'Inicia sesión con Google para gestionar tus mascotas.'
              : 'Inicia sesión con Google para ver tu perfil.',
        )) {
      return;
    }

    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _reportsInitialSection = ReportsMapInitialSection.map;
        _mapRefreshKey++;
        _reportsPageKey++;
      }
    });
  }

  Future<void> _openReportSheet() async {
    final selectedRoute = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReportActionSheet(
        onLostTap: () =>
            Navigator.of(sheetContext).pop(AppRoutes.lostReportForm),
        onFoundTap: () =>
            Navigator.of(sheetContext).pop(AppRoutes.foundReportForm),
      ),
    );

    if (!mounted || selectedRoute == null) return;
    await _openReportForm(selectedRoute);
  }

  Future<void> _openReportForm(String selectedRoute) async {
    if (!_ensureAuthenticated(
      message: 'Inicia sesión con Google para crear un reporte.',
      redirectLocation: selectedRoute,
    )) {
      return;
    }

    final created = await context.push<bool>(selectedRoute);
    if (created == true && mounted) {
      setState(() {
        _homeRefreshKey++;
        _mapRefreshKey++;
      });
    }
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
                      key: ValueKey(_homeRefreshKey),
                      user: user,
                      onOpenPetsSection: _openPetsSection,
                      onOpenMapSection: _openMapSection,
                      onCreateReportTap: _openReportSheet,
                      onCreateLostAlert: () =>
                          _openReportForm(AppRoutes.lostReportForm),
                      onCreateFoundNotice: () =>
                          _openReportForm(AppRoutes.foundReportForm),
                    ),
                    ReportsMapPage(
                      key: ValueKey(_reportsPageKey),
                      refreshToken: _mapRefreshKey,
                      initialSection: _reportsInitialSection,
                    ),
                    PetsPage(),
                    _ProfileTab(
                      user: user,
                      isAuthLoading: isLoading,
                      onOpenMyReports: _openMyReportsSection,
                      onOpenNotifications: () =>
                          context.push(AppRoutes.notifications),
                    ),
                  ],
                ),
                bottomNavigationBar: _BottomNav(
                  currentIndex: _currentIndex,
                  onTap: _selectTab,
                  onReportTap: _openReportSheet,
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
    super.key,
    required this.user,
    required this.onOpenPetsSection,
    required this.onOpenMapSection,
    required this.onCreateReportTap,
    required this.onCreateLostAlert,
    required this.onCreateFoundNotice,
  });

  final UserEntity? user;
  final VoidCallback onOpenPetsSection;
  final VoidCallback onOpenMapSection;
  final VoidCallback onCreateReportTap;
  final VoidCallback onCreateLostAlert;
  final VoidCallback onCreateFoundNotice;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
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
            _HomeReportHero(
              onCreateLostAlert: widget.onCreateLostAlert,
              onCreateFoundNotice: widget.onCreateFoundNotice,
            ),
            SizedBox(height: 18),
            _NearbyReportsSection(
              onOpenMap: widget.onOpenMapSection,
              onOpenPets: widget.onOpenPetsSection,
            ),
            SizedBox(height: 28),
            _buildSectionTitle('Reportes recientes'),
            SizedBox(height: 16),
            _RecentReportsSection(),
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
}

// ─────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────
class _HomeReportHero extends StatelessWidget {
  const _HomeReportHero({
    required this.onCreateLostAlert,
    required this.onCreateFoundNotice,
  });

  final VoidCallback onCreateLostAlert;
  final VoidCallback onCreateFoundNotice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.appColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: context.appColors.primaryDark,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _HeroReportAction(
            icon: Icons.search_off_rounded,
            title: '¿Perdiste tu mascota?',
            actionLabel: 'Crear alerta',
            color: context.appColors.lostPet,
            backgroundColor: context.appColors.pastelPink,
            onTap: onCreateLostAlert,
          ),
          SizedBox(height: 10),
          _HeroReportAction(
            icon: Icons.favorite_rounded,
            title: '¿Encontraste una mascota?',
            actionLabel: 'Publicar aviso',
            color: context.appColors.foundPet,
            backgroundColor: context.appColors.pastelGreen,
            onTap: onCreateFoundNotice,
          ),
        ],
      ),
    );
  }
}

class _HeroReportAction extends StatelessWidget {
  const _HeroReportAction({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyReportsSection extends StatefulWidget {
  const _NearbyReportsSection({
    required this.onOpenMap,
    required this.onOpenPets,
  });

  final VoidCallback onOpenMap;
  final VoidCallback onOpenPets;

  @override
  State<_NearbyReportsSection> createState() => _NearbyReportsSectionState();
}

class _NearbyReportsSectionState extends State<_NearbyReportsSection> {
  late Future<List<ReportEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<GetRecentReports>()();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReportEntity>>(
      future: _future,
      builder: (context, snapshot) {
        final reports = snapshot.data ?? <ReportEntity>[];
        final activeReports = reports
            .where(
              (report) =>
                  report.status == ReportStatus.active ||
                  report.status == ReportStatus.underReview,
            )
            .length;
        final lostReports = reports
            .where(
              (report) =>
                  report.type == ReportType.lost &&
                  (report.status == ReportStatus.active ||
                      report.status == ReportStatus.underReview),
            )
            .length;
        final weekStart = DateTime.now().subtract(Duration(days: 7));
        final foundThisWeek = reports
            .where(
              (report) =>
                  report.type == ReportType.found &&
                  report.createdAt.isAfter(weekStart),
            )
            .length;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reportes cercanos a ti',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? 'Actualizando actividad de la comunidad...'
                              : '$lostReports mascotas perdidas cerca',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.appColors.pastelBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      color: Color(0xFF4488EE),
                      size: 22,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InlineActionButton(
                      icon: Icons.map_rounded,
                      label: 'Ver mapa',
                      isPrimary: true,
                      onTap: widget.onOpenMap,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _InlineActionButton(
                      icon: Icons.pets_rounded,
                      label: 'Mis mascotas',
                      onTap: widget.onOpenPets,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActivityStat(
                      value: '$activeReports',
                      label: 'reportes activos cerca de tu zona',
                      color: context.appColors.primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _ActivityStat(
                      value: '$foundThisWeek',
                      label: 'encontrados esta semana',
                      color: context.appColors.foundPet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary
        ? context.appColors.primary
        : context.appColors.background;
    final foregroundColor = isPrimary
        ? Colors.white
        : context.appColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? context.appColors.primary
                  : context.appColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 92),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
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
  const _RecentReportsSection();

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
  const _ProfileTab({
    required this.user,
    required this.isAuthLoading,
    required this.onOpenMyReports,
    required this.onOpenNotifications,
  });

  final UserEntity? user;
  final bool isAuthLoading;
  final VoidCallback onOpenMyReports;
  final VoidCallback onOpenNotifications;

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
        final isUpdatingProfile = profileState is ProfileUpdating;

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
                if (profile != null)
                  _buildAlertPreferences(profile, isUpdatingProfile)
                else
                  _buildProfileLoadingCard(),

                SizedBox(height: 16),
                _buildProfileMenu(profile),

                SizedBox(height: 16),
                _buildThemeSection(),

                SizedBox(height: 16),

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

  Future<void> _updateProfilePreference(ProfileEntity profile) async {
    await context.read<ProfileCubit>().updateProfile(profile);
  }

  Widget _buildProfileLoadingCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 16,
            decoration: BoxDecoration(
              color: context.appColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              color: context.appColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertPreferences(ProfileEntity profile, bool isUpdating) {
    const radiusOptions = [1, 3, 5, 10];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.appColors.pastelBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertas cerca de mí',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Configura qué avisos quieres recibir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: profile.notificationsEnabled,
            onChanged: isUpdating
                ? null
                : (value) => _updateProfilePreference(
                    profile.copyWith(notificationsEnabled: value),
                  ),
            title: Text(
              'Recibir alertas de mascotas perdidas cerca de mí',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Radio de alertas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: radiusOptions
                .map(
                  (radius) => ChoiceChip(
                    label: Text('$radius km'),
                    selected: profile.notificationRadiusKm == radius,
                    onSelected: isUpdating
                        ? null
                        : (_) => _updateProfilePreference(
                            profile.copyWith(notificationRadiusKm: radius),
                          ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 14),
          Text(
            'Tipos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _petPreferenceChip(
                profile,
                PetPreference.dogs,
                'Perros',
                isUpdating,
              ),
              _petPreferenceChip(
                profile,
                PetPreference.cats,
                'Gatos',
                isUpdating,
              ),
              _petPreferenceChip(
                profile,
                PetPreference.others,
                'Otros',
                isUpdating,
              ),
              _petPreferenceChip(
                profile,
                PetPreference.both,
                'Perros y gatos',
                isUpdating,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _petPreferenceChip(
    ProfileEntity profile,
    PetPreference preference,
    String label,
    bool isUpdating,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: profile.petPreferences == preference,
      onSelected: isUpdating
          ? null
          : (_) => _updateProfilePreference(
              profile.copyWith(petPreferences: preference),
            ),
    );
  }

  Widget _buildProfileMenu(ProfileEntity? profile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        children: [
          _ProfileMenuItem(
            icon: Icons.campaign_rounded,
            title: 'Mis publicaciones',
            subtitle: 'Revisa tus avisos activos e historial.',
            onTap: widget.onOpenMyReports,
          ),
          _ProfileMenuItem(
            icon: Icons.notifications_rounded,
            title: 'Notificaciones',
            subtitle: 'Alertas y actividad reciente.',
            onTap: widget.onOpenNotifications,
          ),
          _ProfileMenuItem(
            icon: Icons.radar_rounded,
            title: 'Radio de alertas',
            subtitle: profile == null
                ? 'Configura distancia de búsqueda.'
                : '${profile.notificationRadiusKm} km alrededor de tu zona.',
            onTap: () =>
                _showProfileMessage('Ajusta el radio en Alertas cerca de mí.'),
          ),
          _ProfileMenuItem(
            icon: Icons.location_on_rounded,
            title: 'Privacidad y ubicación',
            subtitle: profile?.phoneVisible == true
                ? 'Tu teléfono puede mostrarse en avisos autorizados.'
                : 'Tu teléfono está privado por defecto.',
            onTap: profile == null
                ? () => _showProfileMessage(
                    'Carga tu perfil para editar privacidad.',
                  )
                : () => _openEditProfile(context, profile),
          ),
          _ProfileMenuItem(
            icon: Icons.help_rounded,
            title: 'Ayuda para encontrar mi mascota',
            subtitle: 'Consejos y próximos pasos después de publicar.',
            onTap: () => _showProfileMessage(
              'Pronto agregaremos una guía paso a paso para buscar mejor.',
            ),
          ),
          _ProfileMenuItem(
            icon: Icons.privacy_tip_rounded,
            title: 'Términos y privacidad',
            subtitle: 'Uso responsable de datos y ubicación aproximada.',
            onTap: () => _showProfileMessage(
              'Pronto podrás consultar los términos y la política de privacidad aquí.',
            ),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  void _showProfileMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.primaryDark,
        behavior: SnackBarBehavior.floating,
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

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.appColors.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: context.appColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appColors.textHint,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: context.appColors.border,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Bottom navigation flotante
// ─────────────────────────────────────────────
class _ReportActionSheet extends StatelessWidget {
  const _ReportActionSheet({required this.onLostTap, required this.onFoundTap});

  final VoidCallback onLostTap;
  final VoidCallback onFoundTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.appColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Crear reporte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Elige el tipo de ayuda que necesita la comunidad.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: 18),
          _ReportSheetAction(
            icon: Icons.search_off_rounded,
            title: 'Perdí mi mascota',
            subtitle: 'Publica una alerta para encontrarla.',
            iconColor: context.appColors.lostPet,
            backgroundColor: context.appColors.pastelPink,
            onTap: onLostTap,
          ),
          SizedBox(height: 12),
          _ReportSheetAction(
            icon: Icons.favorite_rounded,
            title: 'Encontré una mascota',
            subtitle: 'Ayuda a que vuelva con su familia.',
            iconColor: context.appColors.foundPet,
            backgroundColor: context.appColors.pastelGreen,
            onTap: onFoundTap,
          ),
        ],
      ),
    );
  }
}

class _ReportSheetAction extends StatelessWidget {
  const _ReportSheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onReportTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onReportTap;

  static const _leadingItems = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.map_rounded, label: 'Mapa'),
  ];

  static const _trailingItems = [
    (icon: Icons.pets_rounded, label: 'Mascotas'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        height: 76,
        padding: EdgeInsets.symmetric(horizontal: 10),
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
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_leadingItems.length, (i) {
                  final item = _leadingItems[i];
                  return _BottomNavItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: currentIndex == i,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
            _ReportNavButton(onTap: onReportTap),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_trailingItems.length, (i) {
                  final item = _trailingItems[i];
                  final tabIndex = i + 2;
                  return _BottomNavItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: currentIndex == tabIndex,
                    onTap: () => onTap(tabIndex),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportNavButton extends StatelessWidget {
  const _ReportNavButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Transform.translate(
          offset: Offset(0, -12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(90),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
              SizedBox(height: 2),
              Text(
                'Reportar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 58,
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 21),
            SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
