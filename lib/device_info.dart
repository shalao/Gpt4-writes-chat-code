import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String?> getDeviceIdentifier() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    final iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.identifierForVendor;
  }
  // Add code for Android if needed
  throw UnsupportedError('Platform not supported');
}