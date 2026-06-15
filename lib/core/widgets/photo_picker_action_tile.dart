import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PhotoPickerActionTile extends StatelessWidget {
  const PhotoPickerActionTile({
    super.key,
    required this.onTap,
    required this.accentColor,
    this.highlighted = false,
    this.enabled = true,
    this.hasPhotos = false,
  });

  final VoidCallback? onTap;
  final Color accentColor;
  final bool highlighted;
  final bool enabled;
  final bool hasPhotos;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = highlighted
        ? accentColor
        : context.appColors.textHint;
    final backgroundColor = highlighted
        ? accentColor.withAlpha(18)
        : context.appColors.surface;
    final borderColor = highlighted
        ? accentColor.withAlpha(80)
        : context.appColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: enabled
                ? backgroundColor
                : context.appColors.border.withAlpha(40),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled ? borderColor : context.appColors.border,
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                color: enabled ? foregroundColor : context.appColors.textHint,
                size: 28,
              ),
              SizedBox(height: 4),
              Text(
                hasPhotos ? 'Agregar otra' : 'Agregar foto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: enabled ? foregroundColor : context.appColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
