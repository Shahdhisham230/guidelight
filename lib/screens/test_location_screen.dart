
import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/api_service.dart';

class TestLocationScreen extends StatefulWidget {
  const TestLocationScreen({super.key});

  @override
  State<TestLocationScreen> createState() =>
      _TestLocationScreenState();
}

class _TestLocationScreenState
    extends State<TestLocationScreen> {
  String location = 'No location yet';

  bool loading = false;

  Future<void> sendCurrentLocation() async {
    try {
      setState(() {
        loading = true;
        location = 'Getting location...';
      });

      // 1. Get GPS location from the device
      final position =
          await LocationService.getCurrentLocation();

      // 2. Get the user's family members
      final familyMembers =
          await ApiService.getFamilyMembers();

      if (familyMembers.isEmpty) {
        throw Exception(
          'No family member found.',
        );
      }

      // 3. Get the first family member
      final familyMember =
          familyMembers.first;

      final int familyMemberId =
          familyMember['id'];

      // 4. Send location to Django
      final result =
          await ApiService.sendLocation(
    
        position.latitude,
        position.longitude,
      );

      // 5. Show result
      setState(() {
        location =
            'Location sent successfully! ✅\n\n'
            'Latitude: ${result['latitude']}\n'
            'Longitude: ${result['longitude']}\n'
            'Family Member ID: ${result['family_member']}';

        loading = false;
      });
    } catch (e) {
      setState(() {
        location = 'Error:\n$e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Location'),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Text(
                location,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed:
                    loading
                        ? null
                        : sendCurrentLocation,

                icon: const Icon(
                  Icons.location_on,
                ),

                label: Text(
                  loading
                      ? 'Sending...'
                      : 'Send My Location',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

