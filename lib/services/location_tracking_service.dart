import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';

class LocationTrackingService {
  static StreamSubscription<Position>? _positionSubscription;
  static bool _isSending = false;
  static bool isTracking = false;

  static Future<void> startTracking() async {
    if (isTracking) {
      print('Tracking is already running');
      return;
    }

    await stopTracking();

    print('=================================');
    print('BACKGROUND GPS TRACKING STARTED');
    print('=================================');

    final hasPermission =
        await LocationService.checkAndRequestPermission();

    if (!hasPermission) {
      print('Cannot start tracking - no permission');
      return;
    }

    // إعدادات خاصة بالـ Background
    late LocationSettings locationSettings;

    if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        print('GPS UPDATE → Lat: ${position.latitude}, Lng: ${position.longitude}');
        await _sendLocation(position);
      },
      onError: (error) {
        print('GPS STREAM ERROR: $error');
      },
    );

    isTracking = true;
  }

  static Future<void> stopTracking() async {
    if (_positionSubscription != null) {
      print('GPS TRACKING STOPPED');
    }

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    isTracking = false;
  }

  static Future<void> _sendLocation(Position position) async {
    if (_isSending) return;

    _isSending = true;

    try {
      await ApiService.sendLocation(
        position.latitude,
        position.longitude,
      );

      print('LOCATION SENT SUCCESSFULLY ✅');
    } catch (e) {
      print('LOCATION SENDING ERROR: $e');
    } finally {
      _isSending = false;
    }
  }
}