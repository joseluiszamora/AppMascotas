import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_image_cropper.dart';
import '../../../../core/widgets/photo_selection_thumbnail.dart';
import '../../domain/entities/profile_entity.dart';
import '../blocs/profile_cubit.dart';
import '../blocs/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late PetPreference _petPreference;
  late bool _phoneVisible;
  late bool _notificationsEnabled;
  late int _radiusKm;
  File? _selectedAvatarFile;
  bool _removeAvatar = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstNameCtrl = TextEditingController(text: p.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: p.lastName ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _petPreference = p.petPreferences;
    _phoneVisible = p.phoneVisible;
    _notificationsEnabled = p.notificationsEnabled;
    _radiusKm = p.notificationRadiusKm;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.profile.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      phoneVisible: _phoneVisible,
      petPreferences: _petPreference,
      notificationsEnabled: _notificationsEnabled,
      notificationRadiusKm: _radiusKm,
    );
    context.read<ProfileCubit>().updateProfile(
      updated,
      avatarFile: _selectedAvatarFile,
      removeAvatar: _removeAvatar,
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;

    final cropped = await AppImageCropper.cropSquareImage(
      sourcePath: picked.path,
      title: 'Recortar foto',
      compressQuality: 90,
    );
    if (cropped == null || !mounted) return;

    setState(() {
      _selectedAvatarFile = cropped;
      _removeAvatar = false;
    });
  }

  void _clearAvatarSelection() {
    setState(() {
      _selectedAvatarFile = null;
      _removeAvatar = true;
    });
  }

  String? get _currentAvatarUrl {
    if (_removeAvatar) return null;
    return widget.profile.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: AppColors.foundPet,
            ),
          );
          Navigator.of(context).pop(state.profile);
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state is ProfileUpdating;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Editar perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : GestureDetector(
                        onTap: _submit,
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _buildAvatarSection(isSaving),
                const SizedBox(height: 28),

                // Datos personales
                _buildSectionTitle('Datos personales'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _firstNameCtrl,
                  label: 'Nombre',
                  hint: 'Tu nombre',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu nombre'
                      : null,
                  enabled: !isSaving,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _lastNameCtrl,
                  label: 'Apellidos',
                  hint: 'Tus apellidos',
                  icon: Icons.person_outline_rounded,
                  enabled: !isSaving,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneCtrl,
                  label: 'Teléfono',
                  hint: 'Opcional',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !isSaving,
                ),
                const SizedBox(height: 4),
                _buildPhoneVisibleToggle(isSaving),
                const SizedBox(height: 28),

                // Preferencias de mascotas
                _buildSectionTitle('Preferencias de mascotas'),
                const SizedBox(height: 12),
                _buildPetPreferenceSelector(isSaving),
                const SizedBox(height: 28),

                // Notificaciones
                _buildSectionTitle('Notificaciones'),
                const SizedBox(height: 12),
                _buildNotificationsCard(isSaving),
                const SizedBox(height: 32),

                // Botón guardar
                _buildSaveButton(isSaving),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(bool isSaving) {
    final hasAvatar = _currentAvatarUrl != null || _selectedAvatarFile != null;

    return Center(
      child: Column(
        children: [
          PhotoSelectionThumbnail(
            size: 104,
            isCircular: true,
            overlayAction: Material(
              color: isSaving ? AppColors.border : AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isSaving ? null : _pickAvatar,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            child: _selectedAvatarFile != null
                ? Image.file(_selectedAvatarFile!, fit: BoxFit.cover)
                : _currentAvatarUrl != null
                ? Image.network(
                    _currentAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.primaryLight,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: isSaving ? null : _pickAvatar,
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: Text(hasAvatar ? 'Cambiar foto' : 'Agregar foto'),
              ),
              if (hasAvatar)
                TextButton.icon(
                  onPressed: isSaving ? null : _clearAvatarSelection,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Quitar'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
            ],
          ),
          const Text(
            'Usa una foto clara para que la comunidad te identifique mejor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPhoneVisibleToggle(bool disabled) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Switch.adaptive(
          value: _phoneVisible,
          onChanged: disabled ? null : (v) => setState(() => _phoneVisible = v),
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primaryLight,
        ),
        const SizedBox(width: 8),
        const Text(
          'Mostrar teléfono a otros usuarios',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPetPreferenceSelector(bool disabled) {
    const options = [
      (value: PetPreference.dogs, label: 'Perros', icon: '🐶'),
      (value: PetPreference.cats, label: 'Gatos', icon: '🐱'),
      (value: PetPreference.both, label: 'Ambos', icon: '🐾'),
      (value: PetPreference.others, label: 'Otros', icon: '🐾'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = _petPreference == opt.value;
        return GestureDetector(
          onTap: disabled
              ? null
              : () => setState(() => _petPreference = opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(opt.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationsCard(bool disabled) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: const Text(
              'Recibir notificaciones',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Alertas de mascotas en tu zona',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: _notificationsEnabled,
            onChanged: disabled
                ? null
                : (v) => setState(() => _notificationsEnabled = v),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
          if (_notificationsEnabled) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Radio de alertas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$_radiusKm km',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider.adaptive(
                    value: _radiusKm.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    onChanged: disabled
                        ? null
                        : (v) => setState(() => _radiusKm = v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '1 km',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        '50 km',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isSaving) {
    return GestureDetector(
      onTap: isSaving ? null : _submit,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: isSaving ? AppColors.border : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSaving
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: isSaving
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : const Center(
                child: Text(
                  'Guardar cambios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }
}
