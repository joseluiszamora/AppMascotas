import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../theme/app_colors.dart';

class AppImageCropper {
  static Future<File?> cropImage({
    required String sourcePath,
    String title = 'Recortar foto',
    CropAspectRatio? aspectRatio,
    CropAspectRatioPreset initAspectRatio = CropAspectRatioPreset.original,
    bool lockAspectRatio = false,
    int compressQuality = 90,
  }) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: aspectRatio,
      compressQuality: compressQuality,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: initAspectRatio,
          lockAspectRatio: lockAspectRatio,
          hideBottomControls: false,
          cropFrameColor: AppColors.primary,
          cropGridColor: AppColors.primaryLight,
          activeControlsWidgetColor: AppColors.primary,
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: lockAspectRatio,
          resetAspectRatioEnabled: !lockAspectRatio,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }

  static Future<File?> cropSquareImage({
    required String sourcePath,
    String title = 'Recortar foto',
    int compressQuality = 90,
  }) {
    return cropImage(
      sourcePath: sourcePath,
      title: title,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      initAspectRatio: CropAspectRatioPreset.square,
      lockAspectRatio: true,
      compressQuality: compressQuality,
    );
  }
}
