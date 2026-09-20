import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check and request location permission
  static Future<bool> checkAndRequestPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print('Location services are disabled.');
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    print('Initial permission: $permission');

    // First permission request
    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();

      print(
        'Permission after request: $permission',
      );
    }

    if (permission == LocationPermission.denied) {
      print('Location permission was denied.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      print(
        'Location permission was permanently denied.',
      );

      await Geolocator.openAppSettings();

      return false;
    }

    if (permission == LocationPermission.always) {
      print(
        'Location permission: ALWAYS ✅',
      );

      return true;
    }

    if (permission ==
        LocationPermission.whileInUse) {
      print(
        'Location permission: WHILE USING ⚠️',
      );

      // This is still enough for foreground GPS.
      // iOS may require the user to change
      // this to Always from Settings.

      return true;
    }

    return false;
  }

  static Future<Position> getCurrentLocation() async {
    final hasPermission =
        await checkAndRequestPermission();

    if (!hasPermission) {
      throw Exception(
        'Location permission not granted.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}