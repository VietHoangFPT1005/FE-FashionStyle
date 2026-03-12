import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../config/app_constants.dart';
import '../../models/order/tracking.dart';
import '../../services/service_locator.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  TrackingResponse? _tracking;
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTracking();
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConstants.trackingPollInterval),
      (_) => _fetchTracking(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTracking() async {
    try {
      final response = await sl.orderService.getOrderTracking(widget.orderId);
      if (response.success && response.data != null && mounted) {
        setState(() {
          _tracking = response.data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Theo dõi đơn hàng',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _tracking == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Không thể tải thông tin theo dõi',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(flex: 6, child: _buildMap()),
                    _buildInfo(),
                  ],
                ),
    );
  }

  Widget _buildMap() {
    final shipper = _tracking?.currentLocation;
    final dest = _tracking?.destination;
    final center = shipper != null
        ? LatLng(shipper.latitude, shipper.longitude)
        : dest?.latitude != null
            ? LatLng(dest!.latitude!, dest.longitude!)
            : LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: ApiConfig.osmTileUrl,
          userAgentPackageName: 'com.fashionstyle.app',
        ),
        MarkerLayer(markers: [
          if (shipper != null)
            Marker(
              point: LatLng(shipper.latitude, shipper.longitude),
              width: 60, height: 60,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.delivery_dining,
                      color: Colors.white, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Shipper',
                      style: TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          if (dest?.latitude != null)
            Marker(
              point: LatLng(dest!.latitude!, dest.longitude!),
              width: 60, height: 60,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Giao tại',
                      style: TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
        ]),
        if (shipper != null && dest?.latitude != null)
          PolylineLayer(polylines: [
            Polyline(
              points: [
                LatLng(shipper.latitude, shipper.longitude),
                LatLng(dest!.latitude!, dest.longitude!),
              ],
              color: Colors.blue.withAlpha(150),
              strokeWidth: 4,
            ),
          ]),
      ],
    );
  }

  Widget _buildInfo() {
    final s = _tracking!.shipper;
    final loc = _tracking!.currentLocation;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8,
            offset: Offset(0, -2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đơn hàng: ${_tracking!.orderCode}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.green.shade100,
                child: Text(_tracking!.status,
                  style: TextStyle(
                      color: Colors.green.shade700, fontSize: 12,
                      fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.fullName ?? 'Shipper',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(s.phone ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              if (s.phone != null && s.phone!.isNotEmpty)
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:${s.phone}')),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.phone, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
          if (loc != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.speed_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('Tốc độ: ${loc.speed?.toStringAsFixed(1) ?? '0'} km/h',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.refresh_outlined, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('Tự động cập nhật mỗi 15 giây',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ]),
          ],
        ],
      ),
    );
  }
}
