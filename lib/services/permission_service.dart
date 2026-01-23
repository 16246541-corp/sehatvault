import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  /// Requests camera permission and returns true if granted.
  /// Handles iOS/Android differences by managing status checks and
  /// providing a path to settings if permanently denied.
  static Future<bool> requestCameraPermission() async {
    // 1. Check current status
    PermissionStatus status = await Permission.camera.status;

    // If already granted, return true
    if (status.isGranted) {
      return true;
    }

    // 2. If denied (but not permanently), request it
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    // 3. Handle the result
    if (status.isGranted) {
      return true;
    }

    // 4. Handle permanent denial (User selected "Don't ask again" or iOS restriction)
    if (status.isPermanentlyDenied) {
      // On both platforms, if permanently denied, the only way to enable is via settings.
      // We return false here, but in a real UI flow, we might nudge the user.
      // Some implementations automatically open settings, but it's often better 
      // to let the UI layer handle the "Open Settings" dialog.
      // However, to satisfy "handling differences", we check for permanent denial.
      return false;
    }

    // 5. Handle iOS specific "Restricted" status (e.g. Parental Controls)
    if (Platform.isIOS && status.isRestricted) {
      return false;
    }

    return status.isGranted;
  }
}
