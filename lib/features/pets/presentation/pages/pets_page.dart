import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/blocs/auth/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth/auth_state.dart';
import '../../domain/entities/pet_entity.dart';
import '../blocs/pet_cubit.dart';
import '../blocs/pet_state.dart';
import '../components/pet_card.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPetsIfNeeded(context.read<AuthBloc>().state);
    });
  }

  void _loadPetsIfNeeded(AuthState authState) {
    if (authState is! AuthAuthenticated) return;

    final cubitState = context.read<PetCubit>().state;
    if (cubitState is PetInitial) {
      context.read<PetCubit>().loadPets(authState.user.id);
    }
  }

  Future<void> _refresh() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      await context.read<PetCubit>().loadPets(authState.user.id);
    }
  }

  Future<void> _openForm({PetEntity? pet}) async {
    final result = await context.push<bool>(AppRoutes.petForm, extra: pet);
    // Si se guardó algo, refrescar la lista
    if (result == true && mounted) {
      _refresh();
    }
  }

  Future<void> _confirmDelete(PetEntity pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar mascota'),
        content: Text(
          '¿Eliminar a ${pet.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: context.appColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<PetCubit>().deletePet(pet.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) => current is AuthAuthenticated,
      listener: (context, authState) => _loadPetsIfNeeded(authState),
      child: BlocConsumer<PetCubit, PetState>(
        listener: (context, state) {
          if (state is PetOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.appColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else if (state is PetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.appColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final pets = switch (state) {
            PetLoaded(:final pets) => pets,
            PetOperationInProgress(:final pets) => pets,
            PetOperationSuccess(:final pets) => pets,
            PetError(:final pets) => pets,
            _ => null,
          };

          final isLoading =
              state is PetLoading || state is PetOperationInProgress;

          return Scaffold(
            backgroundColor: context.appColors.background,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mis mascotas',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: context.appColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (pets != null)
                                Text(
                                  pets.isEmpty
                                      ? 'Aún no tienes mascotas registradas'
                                      : '${pets.length} ${pets.length == 1 ? 'mascota registrada' : 'mascotas registradas'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Botón agregar
                        GestureDetector(
                          onTap: () => _openForm(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(60),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Contenido
                  Expanded(
                    child: _buildContent(
                      state: state,
                      pets: pets,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required PetState state,
    required List<PetEntity>? pets,
    required bool isLoading,
  }) {
    // Estado inicial o cargando por primera vez
    if (state is PetInitial || (state is PetLoading && pets == null)) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Error sin datos previos
    if (state is PetError && pets!.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: context.appColors.textHint,
              ),
              SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 20),
              TextButton(onPressed: _refresh, child: Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    // Lista vacía
    if (pets != null && pets.isEmpty) {
      return _EmptyPetsState(onAdd: () => _openForm());
    }

    // Lista con mascotas
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: Stack(
        children: [
          ListView.separated(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 100),
            itemCount: pets!.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pet = pets[index];
              return PetCard(
                pet: pet,
                onTap: () => _openForm(pet: pet),
                onDelete: () => _confirmDelete(pet),
              );
            },
          ),
          if (isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: context.appColors.border,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────

class _EmptyPetsState extends StatelessWidget {
  const _EmptyPetsState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.appColors.pastelYellow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(child: Text('🐾', style: TextStyle(fontSize: 48))),
            ),
            SizedBox(height: 24),
            Text(
              'Aún no tienes mascotas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Registra a tus mascotas para poder reportarlas si se pierden o ayudar a otras personas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 28),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Agregar mascota',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
