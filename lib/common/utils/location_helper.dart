import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Handles the complex flow of checking and requesting location permissions.
  /// Returns true if permissions are granted and services are enabled.
  static Future<bool> handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: Geolocator.openLocationSettings,
            ),
          ),
        );
      }
      return false;
    }

    // 2. Check current permission status.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return false;
      }
    }

    // 3. Handle permanently denied permissions.
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
      }
      return false;
    }

    // Permissions are granted.
    return true;
  }

  /// Gets the current position if permissions are granted.
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    final hasPermission = await handleLocationPermission(context);
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
}
