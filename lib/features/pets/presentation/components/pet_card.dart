import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet_entity.dart';

class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
    this.onDelete,
  });

  final PetEntity pet;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: SizedBox(
                width: 96,
                height: 96,
                child: pet.primaryPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: pet.primaryPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _PhotoPlaceholder(pet.type),
                        errorWidget: (_, __, ___) =>
                            _PhotoPlaceholder(pet.type),
                      )
                    : _PhotoPlaceholder(pet.type),
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusChip(pet.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TypeBadge(pet.type),
                        if (pet.breed != null && pet.breed!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pet.breed!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (pet.ageYears != null || pet.ageMonths != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _ageLabel(pet),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Ícono de flecha
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ageLabel(PetEntity pet) {
    final parts = <String>[];
    if (pet.ageYears != null && pet.ageYears! > 0) {
      parts.add('${pet.ageYears} ${pet.ageYears == 1 ? 'año' : 'años'}');
    }
    if (pet.ageMonths != null && pet.ageMonths! > 0) {
      parts.add('${pet.ageMonths} ${pet.ageMonths == 1 ? 'mes' : 'meses'}');
    }
    return parts.join(', ');
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder(this.type);
  final PetType type;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      PetType.dog => (AppColors.pastelYellow, Icons.pets_rounded),
      PetType.cat => (AppColors.pastelPink, '🐱'),
      PetType.other => (AppColors.pastelBlue, Icons.cruelty_free_rounded),
    };
    return Container(
      color: color,
      child: Center(
        child: icon is IconData
            ? Icon(icon, size: 36, color: AppColors.primary)
            : Text(icon as String, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type);
  final PetType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      PetType.dog => ('Perro', AppColors.pastelYellow),
      PetType.cat => ('Gato', AppColors.pastelPink),
      PetType.other => ('Otro', AppColors.pastelBlue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final PetStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == PetStatus.normal) return const SizedBox.shrink();

    final (label, color) = switch (status) {
      PetStatus.lost => ('Perdida', AppColors.lostPet),
      PetStatus.found => ('Encontrada', AppColors.foundPet),
      PetStatus.normal => ('', Colors.transparent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
