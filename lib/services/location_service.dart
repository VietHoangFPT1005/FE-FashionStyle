import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'shipper_service.dart';

class LocationService {
  final ShipperService _shipperService;
  StreamSubscription<Position>? _positionStream;
  int? _activeOrderId;

  LocationService(this._shipperService);

  /// Check & request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Get current GPS position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Start GPS tracking for shipper
  Future<bool> startTracking(int orderId) async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return false;

    _activeOrderId = orderId;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only update when moved > 10m
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _sendLocation(position);
    });

    return true;
  }

  /// Stop GPS tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _activeOrderId = null;
  }

  /// Send GPS to BE
  Future<void> _sendLocation(Position position) async {
    if (_activeOrderId == null) return;
    try {
      await _shipperService.updateLocation(
        orderId: _activeOrderId!,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed * 3.6, // m/s -> km/h
        heading: position.heading,
      );
    } catch (e) {
      debugPrint('Location send error: $e');
    }
  }

  bool get isTracking => _positionStream != null;

  // ========== Nominatim / OpenStreetMap ==========

  /// Reverse geocode: LatLng -> Address string
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = '${ApiConfig.osmBaseUrl}/reverse'
          '?format=json&lat=$lat&lon=$lng&accept-language=vi';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': ApiConfig.osmUserAgent},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'];
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return null;
  }

  /// Forward search: query -> list of places
  static Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final url = '${ApiConfig.osmBaseUrl}/search'
          '?format=json&q=$encoded&countrycodes=vn&limit=5&accept-language=vi';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': ApiConfig.osmUserAgent},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Search address error: $e');
    }
    return [];
  }
}
