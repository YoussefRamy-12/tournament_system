import 'dart:convert';
import 'dart:io';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

class ProjectorWindowService {
  /// Open the projector window
  static Future<void> openProjectorWindow() async {
    if (kIsWeb || (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS)) {
      return;
    }

    try {
      final window = await WindowController.create(
        WindowConfiguration(
          arguments: jsonEncode({
            'type': 'projector',
          }),
          hiddenAtLaunch: false,
        ),
      );

      await window.show();
    } catch (e) {
      debugPrint('Failed to open projector window: $e');
      rethrow;
    }
  }
}
