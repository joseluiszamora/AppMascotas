import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/profile_entity.dart';
import '../blocs/profile_cubit.dart';
import '../blocs/profile_state.dart';

/// Pantalla mostrada la primera vez que el usuario inicia sesión
/// y no tiene first_name configurado.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late PetPreference _petPreference;
  ProfileEntity? _profileSnapshot;

  @override
  void initState() {
    super.initState();
    // Leer el perfil del cubit global (ya fue cargado por _RouterNotifier)
    final profileState = context.read<ProfileCubit>().state;
    final profile = profileState is ProfileLoaded ? profileState.profile : null;
    _profileSnapshot = profile;
    _firstNameCtrl = TextEditingController(text: profile?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: profile?.lastName ?? '');
    _petPreference = profile?.petPreferences ?? PetPreference.both;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_profileSnapshot == null) return;
    final updated = _profileSnapshot!.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      petPreferences: _petPreference,
    );
    context.read<ProfileCubit>().updateProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          context.go(AppRoutes.home);
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final isSaving =
              state is ProfileUpdating || state is ProfileUpdateSuccess;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  children: [
                    // Ícono de bienvenida
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Bienvenido!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cuéntanos un poco sobre ti para personalizar tu experiencia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Nombre
                    _buildTextField(
                      controller: _firstNameCtrl,
                      label: 'Nombre *',
                      hint: 'Tu nombre',
                      enabled: !isSaving,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _lastNameCtrl,
                      label: 'Apellidos',
                      hint: 'Tus apellidos (opcional)',
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 28),

                    // Preferencias
                    const Text(
                      '¿Qué tipo de mascotas te interesan?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPetPreferenceSelector(isSaving),
                    const SizedBox(height: 36),

                    // Botón continuar
                    GestureDetector(
                      onTap: isSaving ? null : _submit,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: isSaving
                              ? AppColors.border
                              : AppColors.primary,
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
                                  'Continuar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
}
