import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  
  // Sample disposal bin locations in Singapore
  // Replace with your actual locations or fetch from Firestore
  final List<Map<String, dynamic>> _disposalBins = [
    {
      'name': 'Toa Payoh Community Center',
      'lat': 1.3340,
      'lng': 103.8500,
      'address': 'Toa Payoh Central, Singapore 319194',
      'type': 'Cigarette & Vape Disposal',
    },
    {
      'name': 'Ang Mo Kio Community Center',
      'lat': 1.3691,
      'lng': 103.8454,
      'address': 'Ang Mo Kio Avenue 4, Singapore 569628',
      'type': 'Cigarette & Vape Disposal',
    },
    {
      'name': 'Bishan Community Center',
      'lat': 1.3526,
      'lng': 103.8352,
      'address': 'Bishan Street 13, Singapore 579799',
      'type': 'Cigarette & Vape Disposal',
    },
    {
      'name': 'Bedok Community Center',
      'lat': 1.3236,
      'lng': 103.9273,
      'address': 'Bedok North Street 1, Singapore 469662',
      'type': 'Cigarette & Vape Disposal',
    },
    {
      'name': 'Jurong East Community Center',
      'lat': 1.3329,
      'lng': 103.7436,
      'address': 'Jurong East Street 13, Singapore 609655',
      'type': 'Cigarette & Vape Disposal',
    },
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      await _getCurrentLocation();
    } else if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to show nearby bins'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Location Permission Required',
            style: TextStyle(color: Color(0xFF303870)),
          ),
          content: const Text(
            'Please enable location permission in settings to find nearby disposal bins.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF303870)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Color(0xFFFABA5C)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _addMarkers();
      _animateToCurrentLocation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMarkers() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      );
    }

    // Add disposal bin markers
    for (int i = 0; i < _disposalBins.length; i++) {
      final bin = _disposalBins[i];
      markers.add(
        Marker(
          markerId: MarkerId('bin_$i'),
          position: LatLng(bin['lat'], bin['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: bin['name'],
            snippet: 'Tap for details',
          ),
          onTap: () => _showBinDetails(bin),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showBinDetails(Map<String, dynamic> bin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        double? distance;
        if (_currentPosition != null) {
          distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            bin['lat'],
            bin['lng'],
          ) / 1000; // Convert to km
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFABA5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bin['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF303870),
                          ),
                        ),
                        if (distance != null)
                          Text(
                            '${distance.toStringAsFixed(2)} km away',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF303870).withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFFABA5C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bin['address'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF303870),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFABA5C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bin['type'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF303870),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening directions...'),
                        backgroundColor: Color(0xFFFABA5C),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFABA5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _animateToCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 13,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303870),
        title: const Text('Nearest Bin', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _animateToCurrentLocation,
            tooltip: 'My Location',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFABA5C),
              ),
            )
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Text(
                        'Find the Nearest Bin',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF303870),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Dispose of your cigarettes responsibly',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF303870).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: _currentPosition == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_off,
                                  size: 64,
                                  color: Color(0xFF303870),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Location not available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF303870),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Please enable location services to find nearby disposal bins',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF303870).withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _requestLocationPermission,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFABA5C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 15,
                                    ),
                                  ),
                                  child: const Text('Enable Location'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 13,
                          ),
                          markers: _markers,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          compassEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                ),
              ],
            ),
    );
  }
}