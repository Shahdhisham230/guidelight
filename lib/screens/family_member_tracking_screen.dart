import 'package:flutter/material.dart';

import '../services/location_tracking_service.dart';

class FamilyMemberTrackingScreen extends StatefulWidget {
  const FamilyMemberTrackingScreen({super.key});

  @override
  State<FamilyMemberTrackingScreen> createState() =>
      _FamilyMemberTrackingScreenState();
}

class _FamilyMemberTrackingScreenState
    extends State<FamilyMemberTrackingScreen> {
  bool tracking = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

 Future<void> _startTracking() async {
  await LocationTrackingService.startTracking();

  if (!mounted) return;

  setState(() {
    tracking = LocationTrackingService.isTracking;
  });
}

  Future<void> _stopTracking() async {
  await LocationTrackingService.stopTracking();

  if (!mounted) return;

  setState(() {
    tracking = false;
  });
}

  // ملاحظة مهمة: مش بنوقف التتبع في dispose عشان يفضل شغال في الخلفية
  @override
  @override
void dispose() {
  LocationTrackingService.stopTracking();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tracking ? Icons.location_on : Icons.location_off,
                size: 80,
                color: tracking ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                tracking
                    ? 'Location tracking is active'
                    : 'Location tracking is stopped',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tracking
                    ? 'Your location is being sent even in background.'
                    : 'Location tracking has been stopped.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: tracking ? _stopTracking : _startTracking,
                icon: Icon(
                  tracking ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(
                  tracking ? 'Stop Tracking' : 'Start Tracking',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}