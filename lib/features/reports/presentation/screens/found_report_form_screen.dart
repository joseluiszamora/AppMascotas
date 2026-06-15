import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_image_cropper.dart';
import '../../../../core/widgets/photo_picker_action_tile.dart';
import '../../../../core/widgets/photo_selection_thumbnail.dart';
import '../blocs/report_form/report_form_cubit.dart';
import '../blocs/report_form/report_form_state.dart';
import '../../domain/entities/report_entity.dart';
import '../widgets/report_location_picker_page.dart';

class FoundReportFormScreen extends StatefulWidget {
  const FoundReportFormScreen({super.key});

  @override
  State<FoundReportFormScreen> createState() => _FoundReportFormScreenState();
}

class _FoundReportFormScreenState extends State<FoundReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _locationDescriptionCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _visibleDescriptionCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final List<File> _photos = [];

  DateTime _occurredAt = DateTime.now();
  ReportPetType _petType = ReportPetType.dog;
  ReportPetSize? _petSize = ReportPetSize.medium;
  bool _showContact = false;

  @override
  void dispose() {
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _locationDescriptionCtrl.dispose();
    _colorCtrl.dispose();
    _visibleDescriptionCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null || !mounted) return;

    final cropped = await AppImageCropper.cropSquareImage(
      sourcePath: picked.path,
      title: 'Recortar foto del reporte',
      compressQuality: 90,
    );
    if (cropped == null || !mounted) return;

    setState(() => _photos.add(cropped));
  }

  Future<void> _pickOccurredAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickLocationOnMap() async {
    final initialLatitude = double.tryParse(_latitudeCtrl.text.trim());
    final initialLongitude = double.tryParse(_longitudeCtrl.text.trim());

    final result = await pickReportLocation(
      context,
      initialLatitude: initialLatitude,
      initialLongitude: initialLongitude,
    );
    if (result == null || !mounted) return;

    setState(() {
      _latitudeCtrl.text = result.latitude.toStringAsFixed(6);
      _longitudeCtrl.text = result.longitude.toStringAsFixed(6);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      _showMessage('Agrega al menos una foto para publicar el reporte.');
      return;
    }

    final latitude = double.tryParse(_latitudeCtrl.text.trim());
    final longitude = double.tryParse(_longitudeCtrl.text.trim());
    if (latitude == null || longitude == null) {
      _showMessage('Ingresa una ubicación válida.');
      return;
    }

    context.read<ReportFormCubit>().submitFoundReport(
      latitude: latitude,
      longitude: longitude,
      locationDescription: _locationDescriptionCtrl.text.trim().isEmpty
          ? null
          : _locationDescriptionCtrl.text.trim(),
      occurredAt: _occurredAt,
      description: _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim(),
      showContact: _showContact,
      foundPetType: _petType,
      foundPetColor: _colorCtrl.text.trim().isEmpty
          ? null
          : _colorCtrl.text.trim(),
      foundPetSize: _petSize,
      foundPetDescription: _visibleDescriptionCtrl.text.trim().isEmpty
          ? null
          : _visibleDescriptionCtrl.text.trim(),
      photos: List<File>.from(_photos),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? context.appColors.error
            : context.appColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportFormCubit, ReportFormState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showMessage(state.errorMessage!);
          context.read<ReportFormCubit>().clearFeedback();
          return;
        }

        if (state.createdReport != null) {
          context.read<ReportFormCubit>().clearFeedback();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Reportar encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 40),
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 20),
                  _buildLabel('Fotos *'),
                  SizedBox(height: 8),
                  _buildPhotosSection(),
                  SizedBox(height: 20),
                  _buildLabel('Tipo de mascota *'),
                  SizedBox(height: 8),
                  _buildTypeSelector(state.isSubmitting),
                  SizedBox(height: 20),
                  _buildLabel('Ubicación aproximada *'),
                  SizedBox(height: 8),
                  ReportLocationPickerCard(
                    latitude: _latitudeCtrl.text,
                    longitude: _longitudeCtrl.text,
                    disabled: state.isSubmitting,
                    onTap: _pickLocationOnMap,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _locationDescriptionCtrl,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      'Referencia del lugar (parque, calle, tienda...)',
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildLabel('Fecha y hora *'),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: state.isSubmitting ? null : _pickOccurredAt,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'd MMM y, HH:mm',
                                'es',
                              ).format(_occurredAt),
                              style: TextStyle(
                                fontSize: 15,
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
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
                  SizedBox(height: 20),
                  _buildLabel('Color visible'),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _colorCtrl,
                    decoration: _inputDecoration('Ej. blanco, negro, café...'),
                  ),
                  SizedBox(height: 20),
                  _buildLabel('Tamaño'),
                  SizedBox(height: 8),
                  _buildSizeSelector(state.isSubmitting),
                  SizedBox(height: 20),
                  _buildLabel('Características visibles'),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _visibleDescriptionCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      'Collar, manchas, condición, comportamiento, etc.',
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildLabel('Comentario opcional'),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _commentCtrl,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      'Detalles adicionales sobre el hallazgo.',
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: context.appColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.appColors.border),
                    ),
                    child: SwitchListTile(
                      value: _showContact,
                      onChanged: state.isSubmitting
                          ? null
                          : (value) => setState(() => _showContact = value),
                      title: Text(
                        'Permitir contacto',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Actívalo si quieres que puedan contactarte directamente.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: state.isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appColors.foundPet,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: state.isSubmitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.favorite_rounded),
                      label: Text(
                        state.isSubmitting
                            ? 'Publicando...'
                            : 'Publicar reporte',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.pastelGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.foundPet.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: context.appColors.foundPet),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Publica una foto y los rasgos visibles para ayudar a encontrar al dueño.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._photos.map(
            (file) => Padding(
              padding: EdgeInsets.only(right: 10),
              child: PhotoSelectionThumbnail(
                onRemove: () => setState(() => _photos.remove(file)),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ),
          ),
          PhotoPickerActionTile(
            onTap: _pickPhoto,
            accentColor: context.appColors.foundPet,
            highlighted: _photos.isEmpty,
            hasPhotos: _photos.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool disabled) {
    final options = [
      (ReportPetType.dog, 'Perro', '🐶'),
      (ReportPetType.cat, 'Gato', '🐱'),
      (ReportPetType.other, 'Otro', '🐾'),
    ];

    return Row(
      children: options.map((opt) {
        final (type, label, emoji) = opt;
        final selected = _petType == type;
        return Expanded(
          child: GestureDetector(
            onTap: disabled ? null : () => setState(() => _petType = type),
            child: Container(
              margin: EdgeInsets.only(
                right: type != ReportPetType.other ? 8 : 0,
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? context.appColors.foundPet
                    : context.appColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? context.appColors.foundPet
                      : context.appColors.border,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: TextStyle(fontSize: 22)),
                  SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector(bool disabled) {
    final options = [
      (ReportPetSize.small, 'Pequeño'),
      (ReportPetSize.medium, 'Mediano'),
      (ReportPetSize.large, 'Grande'),
      (ReportPetSize.extraLarge, 'Extra grande'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (size, label) = opt;
        final selected = _petSize == size;
        return GestureDetector(
          onTap: disabled ? null : () => setState(() => _petSize = size),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? context.appColors.foundPet
                  : context.appColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? context.appColors.foundPet
                    : context.appColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : context.appColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.appColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: context.appColors.textHint),
      filled: true,
      fillColor: context.appColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appColors.error, width: 1.5),
      ),
    );
  }
}
