import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  bool _isSendingHelp = false;
  bool _isSendingLocation = false;

  // =========================
  // SEND HELP
  // =========================

  Future<void> _sendHelp() async {
    if (_isSendingHelp) return;

    setState(() {
      _isSendingHelp = true;
    });

    try {
      await ApiService.sendHelp();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Help request sent successfully ✅',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingHelp = false;
        });
      }
    }
  }

  // =========================
  // SEND LOCATION
  // =========================

  Future<void> _sendLocation() async {
    if (_isSendingLocation) return;

    setState(() {
      _isSendingLocation = true;
    });

    try {
      // 1. Check if location service is enabled
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. '
          'Please turn on Location Services.',
        );
      }

      // 2. Check current permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      // 3. Ask for permission if not granted
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 4. User denied permission
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }

      // 5. User permanently denied permission
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Please enable it from Settings.',
        );
      }

      // 6. Get current GPS location
      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print('=================================');
      print('📍 GPS LOCATION');
      print('Latitude: ${position.latitude}');
      print('Longitude: ${position.longitude}');
      print('Accuracy: ${position.accuracy}');
      print('=================================');

      // 7. Send location to Django backend
      await ApiService.sendLocation(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      // 8. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location sent successfully 📍\n'
            'Lat: ${position.latitude.toStringAsFixed(6)}\n'
            'Lng: ${position.longitude.toStringAsFixed(6)}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLocation = false;
        });
      }
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> _logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => const LoginScreen(),
  ),
);
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guidelight'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [
                const SizedBox(height: 30),

                // =========================
                // ICON
                // =========================

                const Icon(
                  Icons.family_restroom,
                  size: 80,
                ),

                const SizedBox(height: 24),

                // =========================
                // TITLE
                // =========================

                const Text(
                  'Hello 👋',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your safety is our priority',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 50),

                // =========================
                // SEND HELP
                // =========================

                SizedBox(
                  height: 150,

                  child: ElevatedButton(
                    onPressed:
                        _isSendingHelp
                            ? null
                            : _sendHelp,

                    style:
                        ElevatedButton.styleFrom(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),

                    child: _isSendingHelp
                        ? const SizedBox(
                            width: 35,
                            height: 35,
                            child:
                                CircularProgressIndicator(),
                          )
                        : const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [
                              Icon(
                                Icons.sos_outlined,
                                size: 55,
                              ),

                              SizedBox(height: 10),

                              Text(
                                'SEND HELP',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // =========================
                // SEND LOCATION
                // =========================

                SizedBox(
                  height: 150,

                  child: OutlinedButton(
                    onPressed:
                        _isSendingLocation
                            ? null
                            : _sendLocation,

                    style:
                        OutlinedButton.styleFrom(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),

                    child: _isSendingLocation
                        ? const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [
                              SizedBox(
                                width: 35,
                                height: 35,
                                child:
                                    CircularProgressIndicator(),
                              ),

                              SizedBox(height: 12),

                              Text(
                                'Getting location...',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [
                              Icon(
                                Icons
                                    .location_on_outlined,
                                size: 55,
                              ),

                              SizedBox(height: 10),

                              Text(
                                'SEND LOCATION',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // =========================
                // DESCRIPTION
                // =========================

                const Text(
                  'Use Send Help when you need assistance.\n'
                  'Use Send Location to share your current location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}