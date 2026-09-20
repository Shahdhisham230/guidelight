import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';

class LocationScreen extends StatefulWidget {
  final int familyMemberId;

  const LocationScreen({
    super.key,
    required this.familyMemberId,
  });

  @override
  State<LocationScreen> createState() =>
      _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();

  LatLng? _location;

  bool _isLoading = true;
  String? _error;

  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();

    _loadLocation();

    // Update the location every 30 seconds
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        _loadLocation();
      },
    );
  }

  Future<void> _loadLocation() async {
    try {
      final data = await ApiService.getLatestLocation(
        widget.familyMemberId,
      );

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _isLoading = false;
          _error =
              'No location available for this family member.';
        });
        return;
      }

      final latitude =
          double.parse(data['latitude'].toString());

      final longitude =
          double.parse(data['longitude'].toString());

      final newLocation =
          LatLng(latitude, longitude);

      setState(() {
        _location = newLocation;
        _isLoading = false;
        _error = null;
      });

      print(
        'Location updated: '
        '$latitude, $longitude',
      );

      // Wait until FlutterMap has been rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          _mapController.move(
            newLocation,
            16,
          );
        } catch (e) {
          print('Map controller error: $e');
        }
      });
    } catch (e) {
      if (!mounted) return;

      print('Error loading location: $e');

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _centerLocation() {
    if (_location == null) return;

    try {
      _mapController.move(
        _location!,
        16,
      );
    } catch (e) {
      print('Map controller error: $e');
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Location'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _location == null
                  ? const Center(
                      child: Text(
                        'Location not available.',
                      ),
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _location!,
                            initialZoom: 16,
                            minZoom: 3,
                            maxZoom: 19,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.guidelight.family',
                            ),

                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _location!,
                                  width: 70,
                                  height: 80,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.25),
                                              blurRadius: 6,
                                              offset:
                                                  const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.blue,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Center location button
                        Positioned(
                          right: 16,
                          bottom: 120,
                          child: FloatingActionButton(
                            onPressed: _centerLocation,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            child: const Icon(
                              Icons.my_location,
                            ),
                          ),
                        ),

                        // Current location information
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.12),
                                  blurRadius: 10,
                                  offset:
                                      const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.green
                                        .withOpacity(0.1),
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Location',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_location!.latitude.toStringAsFixed(6)}, '
                                        '${_location!.longitude.toStringAsFixed(6)}',
                                        style:
                                            const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}