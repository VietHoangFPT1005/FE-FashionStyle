import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../config/api_config.dart';
import '../../config/app_constants.dart';
import '../../services/location_service.dart';

class AddressPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const AddressPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  LatLng _selectedPos = LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
  String _address = 'Dang tai...';
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPos = LatLng(widget.initialLat!, widget.initialLng!);
      _reverseGeocode(_selectedPos);
    } else {
      _goToCurrentLocation();
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedPos = latLng);
      _mapController.move(latLng, 16);
      _reverseGeocode(latLng);
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    final addr = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
    if (mounted) setState(() => _address = addr ?? 'Không xác định');
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.length < 3) { setState(() => _searchResults = []); return; }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await LocationService.searchAddress(q);
      if (mounted) setState(() => _searchResults = results);
    });
  }

  void _selectResult(Map<String, dynamic> r) {
    final pos = LatLng(double.parse(r['lat']), double.parse(r['lon']));
    setState(() {
      _selectedPos = pos;
      _address = r['display_name'];
      _searchResults = [];
      _searchCtrl.clear();
    });
    _mapController.move(pos, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chọn vị trí',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedPos, initialZoom: 15,
            onTap: (_, latLng) {
              setState(() => _selectedPos = latLng);
              _reverseGeocode(latLng);
            },
          ),
          children: [
            TileLayer(
                urlTemplate: ApiConfig.osmTileUrl,
                userAgentPackageName: 'com.fashionstyle.app'),
            MarkerLayer(markers: [
              Marker(
                point: _selectedPos, width: 48, height: 48,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 48),
              ),
            ]),
          ],
        ),

        // Search bar
        Positioned(
          top: 10, left: 10, right: 10,
          child: Column(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa chỉ...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                ),
                onChanged: _onSearch,
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length.clamp(0, 5),
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    leading: Icon(Icons.place, size: 18, color: Colors.grey.shade600),
                    title: Text(_searchResults[i]['display_name'],
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                    onTap: () => _selectResult(_searchResults[i]),
                  ),
                ),
              ),
          ]),
        ),

        // My location FAB
        Positioned(
          bottom: 130, right: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 4,
            onPressed: _goToCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Bottom confirm panel
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_address,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: () => Navigator.pop(context, {
                        'latitude': _selectedPos.latitude,
                        'longitude': _selectedPos.longitude,
                        'address': _address,
                      }),
                      child: const Text('XÁC NHẬN VỊ TRÍ',
                          style: TextStyle(fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
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
}
