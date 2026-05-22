import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_image_cropper.dart';
import '../../../../core/widgets/photo_picker_action_tile.dart';
import '../../../../core/widgets/photo_selection_thumbnail.dart';
import '../../../auth/presentation/blocs/auth/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth/auth_state.dart';
import '../../../pets/domain/entities/pet_entity.dart';
import '../../../pets/presentation/blocs/pet_cubit.dart';
import '../blocs/report_form/report_form_cubit.dart';
import '../blocs/report_form/report_form_state.dart';
import '../widgets/report_location_picker_page.dart';

class LostReportFormScreen extends StatefulWidget {
  const LostReportFormScreen({super.key, this.initialPetId});

  final String? initialPetId;

  @override
  State<LostReportFormScreen> createState() => _LostReportFormScreenState();
}

class _LostReportFormScreenState extends State<LostReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _locationDescriptionCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<File> _photos = [];

  DateTime _occurredAt = DateTime.now();
  String? _selectedPetId;
  bool _showContact = false;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialPetId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<ReportFormCubit>().loadPets(authState.user.id);
      }
    });
  }

  @override
  void dispose() {
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _locationDescriptionCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickOccurredAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
    if (_selectedPetId == null) {
      _showMessage('Selecciona una mascota para crear el reporte.');
      return;
    }

    final latitude = double.tryParse(_latitudeCtrl.text.trim());
    final longitude = double.tryParse(_longitudeCtrl.text.trim());

    if (latitude == null || longitude == null) {
      _showMessage('Ingresa una ubicación válida.');
      return;
    }

    context.read<ReportFormCubit>().submitLostReport(
      petId: _selectedPetId!,
      latitude: latitude,
      longitude: longitude,
      locationDescription: _locationDescriptionCtrl.text.trim().isEmpty
          ? null
          : _locationDescriptionCtrl.text.trim(),
      occurredAt: _occurredAt,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      showContact: _showContact,
      photos: List<File>.from(_photos),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  PetEntity? _findSelectedPet(List<PetEntity> pets) {
    if (pets.isEmpty) return null;
    for (final pet in pets) {
      if (pet.id == _selectedPetId) return pet;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportFormCubit, ReportFormState>(
      listener: (context, state) {
        if (_selectedPetId == null && state.pets.isNotEmpty) {
          setState(() => _selectedPetId = state.pets.first.id);
        }

        if (state.errorMessage != null) {
          _showMessage(state.errorMessage!);
          context.read<ReportFormCubit>().clearFeedback();
          return;
        }

        if (state.createdReport != null) {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            context.read<PetCubit>().loadPets(authState.user.id);
          }
          context.read<ReportFormCubit>().clearFeedback();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final selectedPet = _findSelectedPet(state.pets);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Reportar perdida',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: state.isLoadingPets
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.pets.isEmpty
                ? _EmptyPetsState(
                    onAddPet: () => context.push(AppRoutes.petForm),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        _buildLabel('Mascota *'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedPetId),
                          initialValue: _selectedPetId,
                          items: state.pets
                              .map(
                                (pet) => DropdownMenuItem(
                                  value: pet.id,
                                  child: Text(pet.name),
                                ),
                              )
                              .toList(),
                          onChanged: state.isSubmitting
                              ? null
                              : (value) =>
                                    setState(() => _selectedPetId = value),
                          decoration: _inputDecoration('Selecciona tu mascota'),
                          validator: (value) =>
                              value == null ? 'Selecciona una mascota' : null,
                        ),
                        if (selectedPet != null) ...[
                          const SizedBox(height: 16),
                          _SelectedPetCard(pet: selectedPet),
                        ],
                        const SizedBox(height: 20),
                        _buildLabel('Fotos adicionales'),
                        const SizedBox(height: 8),
                        _buildPhotosSection(),
                        const SizedBox(height: 20),
                        _buildLabel('Ubicación aproximada *'),
                        const SizedBox(height: 8),
                        ReportLocationPickerCard(
                          latitude: _latitudeCtrl.text,
                          longitude: _longitudeCtrl.text,
                          disabled: state.isSubmitting,
                          onTap: _pickLocationOnMap,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationDescriptionCtrl,
                          decoration: _inputDecoration(
                            'Referencia del lugar (parque, barrio, avenida...)',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Fecha y hora aproximada *'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: state.isSubmitting ? null : _pickOccurredAt,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'd MMM y, HH:mm',
                                      'es',
                                    ).format(_occurredAt),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Descripción'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 4,
                          decoration: _inputDecoration(
                            'Cuéntanos qué pasó y cualquier detalle útil para encontrarla.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: SwitchListTile(
                            value: _showContact,
                            onChanged: state.isSubmitting
                                ? null
                                : (value) =>
                                      setState(() => _showContact = value),
                            title: const Text(
                              'Mostrar mis datos de contacto',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Si lo activas, se podrán mostrar tus datos según la configuración de tu perfil.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            activeThumbColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: state.isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.lostPet,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: state.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.campaign_rounded),
                            label: Text(
                              state.isSubmitting
                                  ? 'Publicando...'
                                  : 'Publicar reporte',
                              style: const TextStyle(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pastelPink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lostPet.withAlpha(40)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.lostPet),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este reporte usará las fotos ya registradas de la mascota. También puedes agregar fotos recientes del caso antes de publicarlo.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
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
              padding: const EdgeInsets.only(right: 10),
              child: PhotoSelectionThumbnail(
                onRemove: () => setState(() => _photos.remove(file)),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ),
          ),
          PhotoPickerActionTile(
            onTap: _pickPhoto,
            accentColor: AppColors.lostPet,
            highlighted: _photos.isEmpty,
            hasPhotos: _photos.isNotEmpty,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

class _SelectedPetCard extends StatelessWidget {
  const _SelectedPetCard({required this.pet});

  final PetEntity pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 72,
              height: 72,
              child: pet.primaryPhotoUrl != null
                  ? Image.network(
                      pet.primaryPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          _PlaceholderPhoto(pet: pet),
                    )
                  : _PlaceholderPhoto(pet: pet),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pet.breed ?? 'Sin raza especificada',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pet.photos.isEmpty
                      ? 'Esta mascota no tiene fotos registradas aún.'
                      : '${pet.photos.length} foto${pet.photos.length == 1 ? '' : 's'} disponibles para el reporte',
                  style: TextStyle(
                    fontSize: 12,
                    color: pet.photos.isEmpty
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _PlaceholderPhoto extends StatelessWidget {
  const _PlaceholderPhoto({required this.pet});

  final PetEntity pet;

  @override
  Widget build(BuildContext context) {
    final icon = switch (pet.type) {
      PetType.cat => '🐱',
      PetType.dog => '🐶',
      _ => '🐾',
    };

    return Container(
      color: AppColors.pastelYellow,
      alignment: Alignment.center,
      child: Text(icon, style: const TextStyle(fontSize: 28)),
    );
  }
}

class _EmptyPetsState extends StatelessWidget {
  const _EmptyPetsState({required this.onAddPet});

  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.pastelYellow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Necesitas registrar una mascota primero',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para reportar una pérdida, primero registra la mascota en tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAddPet,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Registrar mascota'),
            ),
          ],
        ),
      ),
    );
  }
}
