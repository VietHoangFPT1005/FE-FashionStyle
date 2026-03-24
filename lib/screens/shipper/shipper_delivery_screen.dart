import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../config/api_config.dart';
import '../../config/app_constants.dart';
import '../../services/location_service.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';

class ShipperDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const ShipperDeliveryScreen({super.key, required this.orderData});

  @override
  State<ShipperDeliveryScreen> createState() => _ShipperDeliveryScreenState();
}

class _ShipperDeliveryScreenState extends State<ShipperDeliveryScreen> {
  final MapController _mapCtrl = MapController();
  bool _isTracking = false;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  double _currentSpeed = 0;
  double _distanceRemaining = 0;
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;

  double _destLat = AppConstants.defaultLat;
  double _destLng = AppConstants.defaultLng;
  bool _isGeocodingDest = false;
  late final String _destAddress;
  late final int _orderId;

  @override
  void initState() {
    super.initState();
    final shippingInfo = widget.orderData['shippingInfo'] as Map<String, dynamic>?;
    final rawLat = (shippingInfo?['latitude'] as num?)?.toDouble()
        ?? (widget.orderData['latitude'] as num?)?.toDouble();
    final rawLng = (shippingInfo?['longitude'] as num?)?.toDouble()
        ?? (widget.orderData['longitude'] as num?)?.toDouble();

    // Kiểm tra toạ độ hợp lệ trong lãnh thổ VN
    if (rawLat != null && rawLng != null && _isInVietnam(rawLat, rawLng)) {
      _destLat = rawLat;
      _destLng = rawLng;
    }

    _destAddress = (shippingInfo?['address']
        ?? widget.orderData['shippingAddress']
        ?? widget.orderData['address']
        ?? '').toString();
    _orderId = widget.orderData['orderId'] ?? widget.orderData['id'] ?? 0;

    _initCurrentLocation();

    // Nếu không có toạ độ hợp lệ thì geocode địa chỉ Customer qua Nominatim
    if (rawLat == null || rawLng == null || !_isInVietnam(rawLat, rawLng)) {
      _geocodeDestAddress();
    }
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  /// Kiểm tra tọa độ có nằm trong lãnh thổ Việt Nam không
  bool _isInVietnam(double lat, double lng) {
    return lat >= 8.0 && lat <= 24.0 && lng >= 102.0 && lng <= 110.0;
  }

  Future<void> _initCurrentLocation() async {
    final pos = await sl.locationService.getCurrentPosition();
    if (pos != null && mounted) {
      LatLng position;
      if (_isInVietnam(pos.latitude, pos.longitude)) {
        // GPS hợp lệ (real device)
        position = LatLng(pos.latitude, pos.longitude);
      } else {
        // Emulator / GPS ngoài VN → dùng vị trí mặc định của shipper
        position = LatLng(
          AppConstants.shipperDefaultLat,
          AppConstants.shipperDefaultLng,
        );
      }
      setState(() {
        _currentPosition = position;
        _calculateDistance();
      });
      _fetchRoute();
    }
  }

  /// Lấy tuyến đường thực tế từ OSRM
  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;
    setState(() => _isFetchingRoute = true);
    try {
      final dio = Dio();
      final String url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '$_destLng,$_destLat'
          '?overview=full&geometries=geojson';
      final response = await dio.get(url,
          options: Options(receiveTimeout: const Duration(seconds: 15)));
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List?;
          if (coords != null && mounted) {
            final points = coords
                .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
            setState(() => _routePoints = points);
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM route error: $e');
      // Fallback: giữ nguyên đường thẳng (routePoints rỗng)
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  void _calculateDistance() {
    if (_currentPosition == null) return;
    final distance = const Distance();
    _distanceRemaining = distance.as(
      LengthUnit.Meter,
      _currentPosition!,
      LatLng(_destLat, _destLng),
    );
  }

  /// Geocode địa chỉ Customer qua Nominatim khi DB không có toạ độ
  Future<void> _geocodeDestAddress() async {
    if (_destAddress.isEmpty) return;
    setState(() => _isGeocodingDest = true);
    try {
      final results = await LocationService.searchAddress(_destAddress);
      if (results.isNotEmpty && mounted) {
        final lat = double.tryParse(results.first['lat']?.toString() ?? '');
        final lng = double.tryParse(results.first['lon']?.toString() ?? '');
        if (lat != null && lng != null && _isInVietnam(lat, lng)) {
          setState(() {
            _destLat = lat;
            _destLng = lng;
            _calculateDistance();
          });
          // Di chuyển camera đến địa chỉ vừa tìm được
          _mapCtrl.move(LatLng(_destLat, _destLng), 14);
          _fetchRoute();
        }
      }
    } catch (e) {
      debugPrint('Geocode dest error: $e');
    } finally {
      if (mounted) setState(() => _isGeocodingDest = false);
    }
  }

  Future<void> _startTracking() async {
    final hasPermission = await sl.locationService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Cần cấp quyền truy cập vị trí', isError: true);
      }
      return;
    }

    final started = await sl.locationService.startTracking(_orderId);
    if (!started) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Không thể bắt đầu theo dõi vị trí', isError: true);
      }
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentSpeed = position.speed * 3.6; // m/s -> km/h
          _calculateDistance();
        });
        _mapCtrl.move(_currentPosition!, _mapCtrl.camera.zoom);
        // Cập nhật lộ trình mỗi khi di chuyển ~100m
        if (!_isFetchingRoute) _fetchRoute();
      }
    });

    setState(() => _isTracking = true);
    if (mounted) Helpers.showSnackBar(context, 'Bắt đầu gửi vị trí giao hàng');
  }

  void _stopTracking() {
    sl.locationService.stopTracking();
    _positionStream?.cancel();
    _positionStream = null;
    if (mounted) {
      setState(() => _isTracking = false);
    }
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
      Helpers.showSnackBar(context, 'Đã dừng gửi vị trí');
    } else {
      _startTracking();
    }
  }

  void _centerOnShipper() {
    if (_currentPosition != null) {
      _mapCtrl.move(_currentPosition!, 16);
    }
  }

  void _centerOnDestination() {
    _mapCtrl.move(LatLng(_destLat, _destLng), 16);
  }

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(_destLat, _destLng);
    final center = _currentPosition ?? dest;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đơn #${widget.orderData['orderCode'] ?? _orderId}',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.black),
              onPressed: _centerOnShipper,
              tooltip: 'Vị trí của tôi',
            ),
          IconButton(
            icon: const Icon(Icons.flag_rounded, color: Colors.black),
            onPressed: _centerOnDestination,
            tooltip: 'Điểm giao',
          ),
        ],
      ),
      body: Stack(children: [
        // Map
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(initialCenter: center, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: ApiConfig.osmTileUrl,
              userAgentPackageName: 'com.fashionstyle.app',
            ),
            // Polyline lộ trình thực tế (OSRM) hoặc đường thẳng dự phòng
            if (_currentPosition != null)
              PolylineLayer(polylines: [
                if (_routePoints.length >= 2)
                  Polyline(
                    points: _routePoints,
                    color: Colors.blue,
                    strokeWidth: 4,
                  )
                else
                  Polyline(
                    points: [_currentPosition!, dest],
                    color: Colors.blue.withAlpha(100),
                    strokeWidth: 2,
                    pattern: StrokePattern.dashed(segments: const [10, 6]),
                  ),
              ]),
            MarkerLayer(markers: [
              // Destination marker
              Marker(
                point: dest,
                width: 50,
                height: 50,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, color: Colors.red, size: 32),
                    const Text('Giao tại', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Shipper current location marker
              if (_currentPosition != null)
                Marker(
                  point: _currentPosition!,
                  width: 50,
                  height: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delivery_dining, color: _isTracking ? Colors.green : Colors.blue, size: 32),
                      const Text('Bạn', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ]),
          ],
        ),

        // Route loading indicator
        if (_isFetchingRoute)
          const Positioned(
            top: 12,
            right: 16,
            child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
            ),
          ),

        // Speed & distance info bar
        if (_isTracking && _currentPosition != null)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withAlpha(230),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(Icons.speed, '${_currentSpeed.toStringAsFixed(1)} km/h', 'Tốc độ'),
                    Container(width: 1, height: 30, color: Colors.grey.shade300),
                    _buildInfoItem(
                      Icons.straighten,
                      _distanceRemaining > 1000
                          ? '${(_distanceRemaining / 1000).toStringAsFixed(1)} km'
                          : '${_distanceRemaining.toInt()} m',
                      'Còn lại',
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom card - Address + tracking button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order info
                  Row(
                    children: [
                      _isGeocodingDest
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                          : const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _destAddress.isNotEmpty ? _destAddress : 'Địa chỉ giao hàng',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Builder(builder: (ctx) {
                    final si = widget.orderData['shippingInfo'] as Map<String, dynamic>?;
                    final name = si?['name'] ?? widget.orderData['customerName'] ?? widget.orderData['receiverName'];
                    final phone = si?['phone'] ?? widget.orderData['customerPhone'];
                    if (name == null && phone == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.person_outline, color: Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          Text('${name ?? ''} ${phone != null ? '· $phone' : ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ]),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  // Tracking toggle button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleTracking,
                      icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                      label: Text(_isTracking ? 'Dừng gửi vị trí' : 'Bắt đầu giao hàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}
