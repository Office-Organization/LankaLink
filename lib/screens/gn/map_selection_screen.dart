import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io'; // For Platform
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // Default location (e.g., Colombo, Sri Lanka)
  static const LatLng _initialPosition = LatLng(6.9271, 79.8612);
  
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;

  // Check if the current platform supports Google Maps
  bool get _isMapSupported {
    if (kIsWeb) return true;
    if (Platform.isAndroid || Platform.isIOS) return true;
    return false;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  void _confirmSelection() {
    if (_pickedLocation != null) {
      // Format the coordinate string nicely
      final String formattedCoordinates = 
          '${_pickedLocation!.latitude.toStringAsFixed(4)}° N, ${_pickedLocation!.longitude.toStringAsFixed(4)}° E';
      
      Navigator.pop(context, formattedCoordinates);
    } else if (!_isMapSupported) {
      // Return a fake coordinate for testing on Windows
      Navigator.pop(context, '6.9271° N, 79.8612° E (Windows Test)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('සිතියමෙන් තෝරන්න'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black, 
          fontSize: 18, 
          fontWeight: FontWeight.bold,
          fontFamily: 'UNSamantha'
        ),
        actions: [
          // Show checkmark if location picked OR if we are forcing a bypass on Windows
          if (_pickedLocation != null || !_isMapSupported)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _confirmSelection,
            )
        ],
      ),
      body: _isMapSupported 
          ? _buildGoogleMap() 
          : _buildUnsupportedPlatformMock(),
    );
  }

  // --- Real Map for Android / iOS ---
  Widget _buildGoogleMap() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: const CameraPosition(
            target: _initialPosition,
            zoom: 14.0,
          ),
          onTap: _selectLocation,
          markers: _pickedLocation == null
              ? {}
              : {
                  Marker(
                    markerId: const MarkerId('m1'),
                    position: _pickedLocation!,
                  ),
                },
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'අවශ්‍ය ස්ථානය සිතියම මත click කර ලකුණු කරන්න.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (_pickedLocation != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'තහවුරු කරන්න', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Mock Screen for Windows Testing ---
  Widget _buildUnsupportedPlatformMock() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'සිතියම් පහසුකම Windows සඳහා සහය නොදක්වයි.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'සිතියම බැලීම සඳහා Android හෝ iOS උපාංගයක් (Device / Emulator) භාවිතා කරන්න. පරීක්ෂණ කටයුතු සඳහා පහත බොත්තම ඔබා ඉදිරියට යන්න.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'ස්ථානය ලකුණු කළා යැයි සිතා ඉදිරියට යන්න',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}