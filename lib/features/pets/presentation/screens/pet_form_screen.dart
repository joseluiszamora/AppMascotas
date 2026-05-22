import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
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
        backgroundColor: isError ? AppColors.error : AppColors.success,
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
      _ => const <PetEntity>[],
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
    if (picked == null) return;
    if (_isEditing) {
      // Subir inmediatamente en modo edición
      await _uploadPhotoToExisting(File(picked.path));
    } else {
      setState(() => _pendingPhotos.add(File(picked.path)));
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              _isEditing ? 'Editar mascota' : 'Nueva mascota',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              if (isSaving)
                const Padding(
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
                  child: const Text(
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                // ── Fotos ──
                _buildPhotosSection(state),
                const SizedBox(height: 24),

                // ── Nombre ──
                _buildLabel('Nombre *'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameCtrl,
                  hint: 'Nombre de tu mascota',
                  enabled: !isSaving,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el nombre'
                      : null,
                ),
                const SizedBox(height: 20),

                // ── Tipo ──
                _buildLabel('Tipo *'),
                const SizedBox(height: 8),
                _buildTypeSelector(isSaving),
                const SizedBox(height: 20),

                // ── Raza ──
                _buildLabel('Raza'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _breedCtrl,
                  hint: 'Ej. Labrador, Siamés... (opcional)',
                  enabled: !isSaving,
                ),
                const SizedBox(height: 20),

                // ── Sexo ──
                _buildLabel('Sexo'),
                const SizedBox(height: 8),
                _buildSexSelector(isSaving),
                const SizedBox(height: 20),

                // ── Edad ──
                _buildLabel('Edad (aproximada)'),
                const SizedBox(height: 8),
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
                    const SizedBox(width: 12),
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
                const SizedBox(height: 20),

                // ── Color ──
                _buildLabel('Color predominante'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _colorCtrl,
                  hint: 'Ej. Negro, Atigrado, Blanco y marrón...',
                  enabled: !isSaving,
                ),
                const SizedBox(height: 20),

                // ── Tamaño ──
                _buildLabel('Tamaño'),
                const SizedBox(height: 8),
                _buildSizeSelector(isSaving),
                const SizedBox(height: 20),

                // ── Características distintivas ──
                _buildLabel('Características distintivas'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _featuresCtrl,
                  hint: 'Collar rojo, mancha en el ojo derecho...',
                  enabled: !isSaving,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // ── Estado ──
                _buildLabel('Estado'),
                const SizedBox(height: 8),
                _buildStatusSelector(isSaving),
                const SizedBox(height: 20),

                // ── Toggles médicos ──
                _buildMedicalCard(isSaving),
                const SizedBox(height: 20),

                // ── Chip ──
                _buildLabel('Número de microchip'),
                const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Fotos existentes
              ...existingPhotos.map(
                (photo) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          photo.url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: AppColors.border,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeExistingPhoto(photo),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Fotos locales pendientes (solo al crear)
              ..._pendingPhotos.map(
                (file) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          file,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _pendingPhotos.remove(file)),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botón agregar foto
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: hasPhotos
                        ? AppColors.surface
                        : AppColors.pastelYellow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasPhotos
                          ? AppColors.border
                          : AppColors.primary.withAlpha(80),
                      width: hasPhotos ? 1 : 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: hasPhotos
                            ? AppColors.textHint
                            : AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasPhotos
                              ? AppColors.textHint
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
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
      PetStatus.lost => AppColors.lostPet,
      PetStatus.found => AppColors.foundPet,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withAlpha(25) : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textSecondary,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _isVaccinated,
            onChanged: disabled
                ? null
                : (v) => setState(() => _isVaccinated = v),
            title: const Text(
              'Vacunado/a',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Tiene sus vacunas al día',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            activeThumbColor: AppColors.primary,
          ),
          Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            value: _isSterilized,
            onChanged: disabled
                ? null
                : (v) => setState(() => _isSterilized = v),
            title: const Text(
              'Esterilizado/a',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Ha sido esterilizado/a',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
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
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
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
