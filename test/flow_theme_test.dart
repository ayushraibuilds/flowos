import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/core/theme/app_colors.dart';
import 'package:flowos/features/themes/models/flow_theme.dart';

void main() {
  group('FlowTheme & AppColors dynamic binding', () {
    test('updateTheme updates AppColors static fields correctly', () {
      // Update to Space theme
      AppColors.updateTheme(FlowThemes.space);

      expect(AppColors.background0, FlowThemes.space.background0);
      expect(AppColors.emerald, FlowThemes.space.accent);

      // Revert to Default Dark
      AppColors.updateTheme(FlowThemes.defaultDark);

      expect(AppColors.background0, FlowThemes.defaultDark.background0);
      expect(AppColors.emerald, FlowThemes.defaultDark.accent);
    });
  });
}
