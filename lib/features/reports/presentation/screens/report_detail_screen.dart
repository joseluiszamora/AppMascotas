import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_report_by_id.dart';
import '../utils/report_actions.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<ReportEntity> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<GetReportById>()(widget.reportId);
  }

  void _retry() {
    setState(() {
      _future = sl<GetReportById>()(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Detalle del reporte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          FutureBuilder<ReportEntity>(
            future: _future,
            builder: (context, snapshot) {
              final report = snapshot.data;
              return IconButton(
                onPressed: report == null
                    ? null
                    : () => shareReport(context, report),
                tooltip: 'Compartir reporte',
                icon: Icon(Icons.share_rounded),
                color: context.appColors.textPrimary,
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<ReportEntity>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _ReportDetailFeedback(
              icon: Icons.wifi_tethering_error_rounded,
              title: 'No pudimos cargar el reporte',
              message: 'Intenta nuevamente para ver la información completa.',
              actionLabel: 'Reintentar',
              onAction: _retry,
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return _ReportDetailFeedback(
              icon: Icons.search_off_rounded,
              title: 'Reporte no disponible',
              message: 'Este reporte ya no está disponible o fue removido.',
              actionLabel: 'Volver',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          final isLost = report.type == ReportType.lost;
          final badgeColor = isLost
              ? context.appColors.lostPet
              : context.appColors.foundPet;
          final badgeBg = isLost
              ? context.appColors.pastelPink
              : context.appColors.pastelGreen;
          final title = reportTitle(report);
          final dateLabel = DateFormat(
            'd MMM y, HH:mm',
            'es',
          ).format(report.occurredAt);

          return SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _ReportPhotoGallery(report: report),
                SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: isLost ? 'Perdida' : 'Encontrada',
                      bgColor: badgeBg,
                      textColor: badgeColor,
                    ),
                    _Badge(
                      label: reportStatusLabel(report.status),
                      bgColor: context.appColors.surface,
                      textColor: context.appColors.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                if (report.petBreed != null &&
                    report.petBreed!.trim().isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(
                    report.petBreed!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 16),
                _ReportDetailActions(report: report),
                SizedBox(height: 20),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación aproximada',
                      value: reportLocationLabel(report),
                    ),
                    _InfoRow(
                      icon: Icons.pin_drop_outlined,
                      label: 'Punto aproximado',
                      value: reportApproximateCoordinatesLabel(report),
                    ),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Fecha',
                      value: dateLabel,
                    ),
                    if (report.effectivePetType != null)
                      _InfoRow(
                        icon: Icons.pets_rounded,
                        label: 'Tipo',
                        value: _petTypeLabel(report.effectivePetType!),
                      ),
                    if (report.effectivePetColor != null &&
                        report.effectivePetColor!.trim().isNotEmpty)
                      _InfoRow(
                        icon: Icons.palette_outlined,
                        label: 'Color',
                        value: report.effectivePetColor!,
                      ),
                    if (report.effectivePetSize != null)
                      _InfoRow(
                        icon: Icons.straighten_rounded,
                        label: 'Tamaño',
                        value: _petSizeLabel(report.effectivePetSize!),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                _InfoCard(
                  title: 'Descripción',
                  children: [
                    Text(
                      reportDescriptionText(report),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportDetailFeedback extends StatelessWidget {
  const _ReportDetailFeedback({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: context.appColors.textHint),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDetailHeroPlaceholder extends StatelessWidget {
  const _ReportDetailHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.pastelYellow,
      alignment: Alignment.center,
      child: Icon(Icons.pets_rounded, size: 54, color: AppColors.primary),
    );
  }
}

class _ReportPhotoGallery extends StatelessWidget {
  const _ReportPhotoGallery({required this.report});

  final ReportEntity report;

  @override
  Widget build(BuildContext context) {
    final photos = report.photos;
    if (photos.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(height: 240, child: _ReportDetailHeroPlaceholder()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openPhotoViewer(context, photos, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Image.network(
                    photos.first.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _ReportDetailHeroPlaceholder(),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        if (photos.length > 1) ...[
                          SizedBox(width: 5),
                          Text(
                            '1/${photos.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (photos.length > 1) ...[
          SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (context, index) => SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return GestureDetector(
                  onTap: () => _openPhotoViewer(context, photos, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Image.network(
                        photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: context.appColors.border,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: context.appColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openPhotoViewer(
    BuildContext context,
    List<ReportPhotoEntity> photos,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) =>
            _ReportPhotoViewer(photos: photos, initialIndex: initialIndex),
      ),
    );
  }
}

class _ReportPhotoViewer extends StatefulWidget {
  const _ReportPhotoViewer({required this.photos, required this.initialIndex});

  final List<ReportPhotoEntity> photos;
  final int initialIndex;

  @override
  State<_ReportPhotoViewer> createState() => _ReportPhotoViewerState();
}

class _ReportPhotoViewerState extends State<_ReportPhotoViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1}/${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                photo.url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ReportDetailActions extends StatelessWidget {
  const _ReportDetailActions({required this.report});

  final ReportEntity report;

  @override
  Widget build(BuildContext context) {
    if (report.type == ReportType.lost) {
      return Column(
        children: [
          _DetailPrimaryAction(
            icon: Icons.visibility_rounded,
            label: 'La vi / tengo información',
            onPressed: () => _showActionMessage(
              context,
              'Gracias por ayudar. Pronto podrás registrar un avistamiento desde aquí.',
            ),
          ),
          SizedBox(height: 10),
          _DetailSecondaryAction(
            icon: Icons.share_rounded,
            label: 'Compartir',
            onPressed: () => shareReport(context, report),
          ),
          SizedBox(height: 10),
          _DetailSecondaryAction(
            icon: Icons.navigation_rounded,
            label: 'Ir a zona aproximada',
            onPressed: () => openReportNavigation(context, report),
          ),
        ],
      );
    }

    return Column(
      children: [
        _DetailPrimaryAction(
          icon: Icons.pets_rounded,
          label: 'Creo que es mi mascota',
          onPressed: () => _showActionMessage(
            context,
            report.showContact
                ? 'Pronto podrás contactar directamente a quien publicó este aviso.'
                : 'Quien publicó este aviso no habilitó datos de contacto visibles.',
          ),
        ),
        SizedBox(height: 10),
        _DetailSecondaryAction(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Contactar',
          onPressed: () => _showActionMessage(
            context,
            report.showContact
                ? 'El contacto directo estará disponible en el siguiente paso del flujo.'
                : 'El contacto directo no está disponible para este aviso.',
          ),
        ),
        SizedBox(height: 10),
        _DetailSecondaryAction(
          icon: Icons.share_rounded,
          label: 'Compartir',
          onPressed: () => shareReport(context, report),
        ),
      ],
    );
  }

  void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DetailPrimaryAction extends StatelessWidget {
  const _DetailPrimaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon),
        label: Text(label, style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _DetailSecondaryAction extends StatelessWidget {
  const _DetailSecondaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.appColors.textPrimary,
          side: BorderSide(color: context.appColors.border),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: context.appColors.surface,
        ),
        icon: Icon(icon),
        label: Text(label, style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.appColors.textHint),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textSecondary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appColors.textPrimary,
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

String _petTypeLabel(ReportPetType type) => switch (type) {
  ReportPetType.cat => 'Gato',
  ReportPetType.other => 'Otro',
  ReportPetType.dog => 'Perro',
};

String _petSizeLabel(ReportPetSize size) => switch (size) {
  ReportPetSize.small => 'Pequeño',
  ReportPetSize.medium => 'Mediano',
  ReportPetSize.large => 'Grande',
  ReportPetSize.extraLarge => 'Extra grande',
};
