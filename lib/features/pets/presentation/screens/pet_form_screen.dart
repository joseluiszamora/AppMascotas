import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_image_cropper.dart';
import '../../../../core/widgets/photo_picker_action_tile.dart';
import '../../../../core/widgets/photo_selection_thumbnail.dart';
import '../../../auth/presentation/blocs/auth/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth/auth_state.dart';
import '../../domain/entities/pet_entity.dart';
import '../blocs/pet_cubit.dart';
import '../blocs/pet_state.dart';

/// Pantalla para crear o editar una mascota.
/// Si [pet] es null, se crea una nueva.
class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, this.pet});

  final PetEntity? pet;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Controladores de texto
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _featuresCtrl;
  late final TextEditingController _chipCtrl;
  late final TextEditingController _ageYearsCtrl;
  late final TextEditingController _ageMonthsCtrl;

  // Valores de selección
  late PetType _type;
  late PetSex _sex;
  late PetSize _size;
  late PetStatus _status;
  late bool _isVaccinated;
  late bool _isSterilized;

  // Fotos locales pendientes de subir (solo al crear)
  final List<File> _pendingPhotos = [];

  bool get _isEditing => widget.pet != null;

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

  PetEntity? _currentEditingPet(PetState state) {
    final initialPet = widget.pet;
    if (initialPet == null) return null;

    final pets = switch (state) {
      PetLoaded(:final pets) => pets,
      PetOperationInProgress(:final pets) => pets,
      PetOperationSuccess(:final pets) => pets,
      PetError(:final pets) => pets,
      _ => <PetEntity>[],
    };

    for (final pet in pets) {
      if (pet.id == initialPet.id) return pet;
    }

    return initialPet;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _breedCtrl = TextEditingController(text: p?.breed ?? '');
    _colorCtrl = TextEditingController(text: p?.dominantColor ?? '');
    _featuresCtrl = TextEditingController(text: p?.distinctiveFeatures ?? '');
    _chipCtrl = TextEditingController(text: p?.chipNumber ?? '');
    _ageYearsCtrl = TextEditingController(
      text: p?.ageYears != null ? '${p!.ageYears}' : '',
    );
    _ageMonthsCtrl = TextEditingController(
      text: p?.ageMonths != null ? '${p!.ageMonths}' : '',
    );
    _type = p?.type ?? PetType.dog;
    _sex = p?.sex ?? PetSex.unknown;
    _size = p?.size ?? PetSize.medium;
    _status = p?.status ?? PetStatus.normal;
    _isVaccinated = p?.isVaccinated ?? false;
    _isSterilized = p?.isSterilized ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _colorCtrl.dispose();
    _featuresCtrl.dispose();
    _chipCtrl.dispose();
    _ageYearsCtrl.dispose();
    _ageMonthsCtrl.dispose();
    super.dispose();
  }

  // ── Foto ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;

    final cropped = await AppImageCropper.cropSquareImage(
      sourcePath: picked.path,
      title: 'Recortar foto de mascota',
      compressQuality: 90,
    );
    if (cropped == null || !mounted) return;

    if (_isEditing) {
      // Subir inmediatamente en modo edición
      await _uploadPhotoToExisting(cropped);
    } else {
      setState(() => _pendingPhotos.add(cropped));
    }
  }

  Future<void> _uploadPhotoToExisting(File file) async {
    final petCubit = context.read<PetCubit>();
    final pet = _currentEditingPet(petCubit.state) ?? widget.pet!;
    final uploaded = await petCubit.uploadPhoto(
      petId: pet.id,
      file: file,
      isPrimary: pet.photos.isEmpty,
    );
    if (!mounted) return;
    if (uploaded == null) {
      final state = petCubit.state;
      if (state is PetError) {
        _showMessage(state.message);
      }
    }
  }

  Future<void> _removeExistingPhoto(PetPhotoEntity photo) async {
    await context.read<PetCubit>().deletePhoto(
      photo.id,
      photo.url,
      widget.pet!.id,
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authState = context.read<AuthBloc>().state;
    final petCubit = context.read<PetCubit>();
    if (authState is! AuthAuthenticated) return;

    final ageYears = int.tryParse(_ageYearsCtrl.text.trim());
    final ageMonths = int.tryParse(_ageMonthsCtrl.text.trim());

    if (_isEditing) {
      final updated = widget.pet!.copyWith(
        name: _nameCtrl.text.trim(),
        type: _type,
        breed: _breedCtrl.text.trim().isEmpty ? null : _breedCtrl.text.trim(),
        sex: _sex,
        ageYears: ageYears,
        ageMonths: ageMonths,
        dominantColor: _colorCtrl.text.trim().isEmpty
            ? null
            : _colorCtrl.text.trim(),
        size: _size,
        distinctiveFeatures: _featuresCtrl.text.trim().isEmpty
            ? null
            : _featuresCtrl.text.trim(),
        isVaccinated: _isVaccinated,
        isSterilized: _isSterilized,
        chipNumber: _chipCtrl.text.trim().isEmpty
            ? null
            : _chipCtrl.text.trim(),
        status: _status,
      );
      await petCubit.updatePet(updated);
    } else {
      final now = DateTime.now();
      final newPet = PetEntity(
        id: '',
        ownerId: authState.user.id,
        name: _nameCtrl.text.trim(),
        type: _type,
        breed: _breedCtrl.text.trim().isEmpty ? null : _breedCtrl.text.trim(),
        sex: _sex,
        ageYears: ageYears,
        ageMonths: ageMonths,
        dominantColor: _colorCtrl.text.trim().isEmpty
            ? null
            : _colorCtrl.text.trim(),
        size: _size,
        distinctiveFeatures: _featuresCtrl.text.trim().isEmpty
            ? null
            : _featuresCtrl.text.trim(),
        isVaccinated: _isVaccinated,
        isSterilized: _isSterilized,
        chipNumber: _chipCtrl.text.trim().isEmpty
            ? null
            : _chipCtrl.text.trim(),
        status: _status,
        createdAt: now,
        updatedAt: now,
      );
      final created = await petCubit.createPet(newPet);
      if (created != null && _pendingPhotos.isNotEmpty && mounted) {
        for (var i = 0; i < _pendingPhotos.length; i++) {
          final uploaded = await petCubit.uploadPhoto(
            petId: created.id,
            file: _pendingPhotos[i],
            isPrimary: i == 0,
          );
          if (!mounted) return;
          if (uploaded == null) {
            final state = petCubit.state;
            if (state is PetError) {
              _showMessage(state.message);
            }
            return;
          }
        }
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final isSaving = state is PetOperationInProgress;

        return Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: context.appColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              _isEditing ? 'Editar mascota' : 'Nueva mascota',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              if (isSaving)
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _submit,
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                // ── Fotos ──
                _buildPhotosSection(state),
                SizedBox(height: 24),

                // ── Nombre ──
                _buildLabel('Nombre *'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _nameCtrl,
                  hint: 'Nombre de tu mascota',
                  enabled: !isSaving,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el nombre'
                      : null,
                ),
                SizedBox(height: 20),

                // ── Tipo ──
                _buildLabel('Tipo *'),
                SizedBox(height: 8),
                _buildTypeSelector(isSaving),
                SizedBox(height: 20),

                // ── Raza ──
                _buildLabel('Raza'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _breedCtrl,
                  hint: 'Ej. Labrador, Siamés... (opcional)',
                  enabled: !isSaving,
                ),
                SizedBox(height: 20),

                // ── Sexo ──
                _buildLabel('Sexo'),
                SizedBox(height: 8),
                _buildSexSelector(isSaving),
                SizedBox(height: 20),

                // ── Edad ──
                _buildLabel('Edad (aproximada)'),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _ageYearsCtrl,
                        hint: 'Años',
                        keyboardType: TextInputType.number,
                        enabled: !isSaving,
                        validator: _validateAge,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _ageMonthsCtrl,
                        hint: 'Meses',
                        keyboardType: TextInputType.number,
                        enabled: !isSaving,
                        validator: _validateMonths,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // ── Color ──
                _buildLabel('Color predominante'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _colorCtrl,
                  hint: 'Ej. Negro, Atigrado, Blanco y marrón...',
                  enabled: !isSaving,
                ),
                SizedBox(height: 20),

                // ── Tamaño ──
                _buildLabel('Tamaño'),
                SizedBox(height: 8),
                _buildSizeSelector(isSaving),
                SizedBox(height: 20),

                // ── Características distintivas ──
                _buildLabel('Características distintivas'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _featuresCtrl,
                  hint: 'Collar rojo, mancha en el ojo derecho...',
                  enabled: !isSaving,
                  maxLines: 3,
                ),
                SizedBox(height: 20),

                // ── Estado ──
                _buildLabel('Estado'),
                SizedBox(height: 8),
                _buildStatusSelector(isSaving),
                SizedBox(height: 20),

                // ── Toggles médicos ──
                _buildMedicalCard(isSaving),
                SizedBox(height: 20),

                // ── Chip ──
                _buildLabel('Número de microchip'),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _chipCtrl,
                  hint: 'Opcional',
                  enabled: !isSaving,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Secciones ─────────────────────────────────────────────────────────────

  Widget _buildPhotosSection(PetState state) {
    final existingPhotos = _currentEditingPet(state)?.photos ?? [];
    final hasPhotos = existingPhotos.isNotEmpty || _pendingPhotos.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Fotos'),
        SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Fotos existentes
              ...existingPhotos.map(
                (photo) => Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: PhotoSelectionThumbnail(
                    onRemove: () => _removeExistingPhoto(photo),
                    child: Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Container(
                        color: context.appColors.border,
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: context.appColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Fotos locales pendientes (solo al crear)
              ..._pendingPhotos.map(
                (file) => Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: PhotoSelectionThumbnail(
                    onRemove: () => setState(() => _pendingPhotos.remove(file)),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                ),
              ),
              PhotoPickerActionTile(
                onTap: _pickImage,
                accentColor: AppColors.primary,
                highlighted: !hasPhotos,
                hasPhotos: hasPhotos,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(bool disabled) {
    final options = [
      (PetType.dog, 'Perro', '🐶'),
      (PetType.cat, 'Gato', '🐱'),
      (PetType.other, 'Otro', '🐾'),
    ];
    return Row(
      children: options.map((opt) {
        final (type, label, emoji) = opt;
        final selected = _type == type;
        return Expanded(
          child: GestureDetector(
            onTap: disabled ? null : () => setState(() => _type = type),
            child: Container(
              margin: EdgeInsets.only(right: opt.$1 != PetType.other ? 8 : 0),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : context.appColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
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

  Widget _buildSexSelector(bool disabled) {
    final options = [
      (PetSex.male, 'Macho'),
      (PetSex.female, 'Hembra'),
      (PetSex.unknown, 'Desconocido'),
    ];
    return _buildChipRow(
      options: options.map((o) => (o.$1, o.$2)).toList(),
      selected: _sex,
      onSelect: disabled ? null : (v) => setState(() => _sex = v as PetSex),
    );
  }

  Widget _buildSizeSelector(bool disabled) {
    final options = [
      (PetSize.small, 'Pequeño'),
      (PetSize.medium, 'Mediano'),
      (PetSize.large, 'Grande'),
      (PetSize.extraLarge, 'Extra grande'),
    ];
    return _buildChipRow(
      options: options.map((o) => (o.$1, o.$2)).toList(),
      selected: _size,
      onSelect: disabled ? null : (v) => setState(() => _size = v as PetSize),
    );
  }

  Widget _buildStatusSelector(bool disabled) {
    final options = [
      (PetStatus.normal, 'Normal'),
      (PetStatus.lost, 'Perdida'),
      (PetStatus.found, 'Encontrada'),
    ];

    Color chipColor(PetStatus s) => switch (s) {
      PetStatus.lost => context.appColors.lostPet,
      PetStatus.found => context.appColors.foundPet,
      _ => AppColors.primary,
    };

    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final (status, label) = opt;
        final selected = _status == status;
        final color = chipColor(status);
        return GestureDetector(
          onTap: disabled ? null : () => setState(() => _status = status),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withAlpha(25) : context.appColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? color : context.appColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : context.appColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipRow({
    required List<(dynamic, String)> options,
    required dynamic selected,
    required void Function(dynamic)? onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: onSelect != null ? () => onSelect(value) : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : context.appColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : context.appColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : context.appColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicalCard(bool disabled) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _isVaccinated,
            onChanged: disabled
                ? null
                : (v) => setState(() => _isVaccinated = v),
            title: Text(
              'Vacunado/a',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Tiene sus vacunas al día',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
            ),
            activeThumbColor: AppColors.primary,
          ),
          Divider(height: 1, color: context.appColors.border),
          SwitchListTile(
            value: _isSterilized,
            onChanged: disabled
                ? null
                : (v) => setState(() => _isSterilized = v),
            title: Text(
              'Esterilizado/a',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Ha sido esterilizado/a',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
            ),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 15, color: context.appColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.appColors.textHint, fontSize: 14),
        filled: true,
        fillColor: context.appColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.appColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.appColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.appColors.error),
        ),
      ),
    );
  }

  String? _validateAge(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null) return 'Solo números';
    if (n < 0 || n > 30) return '0-30';
    return null;
  }

  String? _validateMonths(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null) return 'Solo números';
    if (n < 0 || n > 11) return '0-11';
    return null;
  }
}
