import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PhotoSelectionThumbnail extends StatelessWidget {
  const PhotoSelectionThumbnail({
    super.key,
    required this.child,
    this.onRemove,
    this.size = 100,
    this.isCircular = false,
    this.overlayAction,
  });

  final Widget child;
  final VoidCallback? onRemove;
  final double size;
  final bool isCircular;
  final Widget? overlayAction;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(isCircular ? size / 2 : 16);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: borderRadius,
              border: Border.all(
                color: context.appColors.border,
                width: isCircular ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          if (overlayAction != null)
            Positioned(bottom: 0, right: 0, child: overlayAction!),
          if (onRemove != null)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withAlpha(150),
                shape: CircleBorder(),
                child: InkWell(
                  onTap: onRemove,
                  customBorder: CircleBorder(),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
