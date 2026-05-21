import 'package:flutter_test/flutter_test.dart';

import 'package:app_mascotas/core/constants/app_constants.dart';

void main() {
  test('define el nombre de la app', () {
    expect(AppConstants.appName, 'App Mascotas');
  });
}
