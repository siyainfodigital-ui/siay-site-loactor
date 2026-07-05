import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  // ─── GPS ─────────────────────────────────────────────────
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  // ─── DISTANCE ────────────────────────────────────────────
  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  // ─── NAVIGATION DEEP LINKS (no API key) ─────────────────
  /// Opens Google Maps installed app directly via navigation intent
  static String googleMapsDeepLink(double lat, double lng) =>
      'google.navigation:q=$lat,$lng';

  /// HTTP fallback link for browsers or devices without Google Maps app
  static String googleMapsWebLink(double lat, double lng) =>
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';

  static Future<void> openNavigation(double lat, double lng) async {
    final intentUri = Uri.parse(googleMapsDeepLink(lat, lng));
    if (await canLaunchUrl(intentUri)) {
      await launchUrl(intentUri, mode: LaunchMode.externalNonBrowserApplication);
      return;
    }
    
    // Fallback to web link if scheme is not supported directly
    final webUri = Uri.parse(googleMapsWebLink(lat, lng));
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── LAT/LNG PARSING ─────────────────────────────────────
  /// Parse "21.12345, 74.56789" format typed/pasted by user
  static Map<String, double>? parseLatLng(String input) {
    final cleaned = input.trim();
    // Supports: "21.12345,74.56789" or "21.12345, 74.56789"
    final parts = cleaned.split(RegExp(r'[,\s]+'));
    if (parts.length >= 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          return {'lat': lat, 'lng': lng};
        }
      }
    }
    return null;
  }

  /// Parse Google Maps share link (no API key needed)
  static Map<String, double>? parseGoogleMapsLink(String url) {
    final patterns = [
      RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)'),
      RegExp(r'[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)'),
      RegExp(r'll=(-?\d+\.?\d*),(-?\d+\.?\d*)'),
      RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        final lat = double.tryParse(match.group(1)!);
        final lng = double.tryParse(match.group(2)!);
        if (lat != null && lng != null) return {'lat': lat, 'lng': lng};
      }
    }
    return null;
  }
}
