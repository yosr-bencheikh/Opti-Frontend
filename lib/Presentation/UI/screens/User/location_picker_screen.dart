import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  Position? _currentPosition;
  GoogleMapController? _mapController;
  final _initialPosition =
      const LatLng(36.806389, 10.181667); // Paris coordinates

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          Get.snackbar(
            'Permission Required',
            'Location permissions are required to use this feature',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not get current location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (places.isNotEmpty) {
        final place = places.first;
        return [
          place.street,
          place.locality,
          place.postalCode,
        ].where((part) => part?.isNotEmpty ?? false).join(', ');
      }
      return 'Unknown address';
    } catch (e) {
      throw Exception('Failed to get address: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Address'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : _initialPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) => _mapController = controller,
        onTap: (LatLng position) {
          setState(() => _selectedLocation = position);
        },
        markers: _selectedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: _selectedLocation!,
                )
              }
            : {},
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () async {
          if (_selectedLocation == null) {
            Get.snackbar(
              'No Location Selected',
              'Please select a location on the map',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
            return;
          }

          try {
            final address = await _getAddressFromLatLng(_selectedLocation!);
            Get.closeCurrentSnackbar();
            Get.back(result: {
              'address': address,
              'lat': _selectedLocation!.latitude,
              'lng': _selectedLocation!.longitude
            });
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to get address for selected location',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
          }
        },
      ),
    );
  }
}
