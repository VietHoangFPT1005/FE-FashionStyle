import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_routes.dart';
import '../../models/address/address.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? addressData;
  const AddressFormScreen({super.key, this.addressData});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressLineCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isDefault = false;
  bool _isSaving = false;

  bool get isEditing => widget.addressData != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final d = widget.addressData!;
      _nameCtrl.text = d['receiverName'] ?? '';
      _phoneCtrl.text = d['phone'] ?? '';
      _addressLineCtrl.text = d['addressLine'] ?? '';
      _wardCtrl.text = d['ward'] ?? '';
      _districtCtrl.text = d['district'] ?? '';
      _cityCtrl.text = d['city'] ?? '';
      _latitude = d['latitude'] as double?;
      _longitude = d['longitude'] as double?;
      _isDefault = d['isDefault'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressLineCtrl.dispose();
    _wardCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final request = CreateAddressRequest(
        receiverName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine: _addressLineCtrl.text.trim(),
        ward: _wardCtrl.text.trim().isNotEmpty ? _wardCtrl.text.trim() : null,
        district: _districtCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isDefault: _isDefault,
      );

      final res = isEditing
          ? await sl.addressService
              .updateAddress(widget.addressData!['addressId'], request)
          : await sl.addressService.createAddress(request);

      if (res.success) {
        if (mounted) {
          Helpers.showSnackBar(context,
              isEditing ? 'Đã cập nhật địa chỉ!' : 'Đã thêm địa chỉ mới!');
          Navigator.pop(context, true);
        }
      } else {
        if (mounted)
          Helpers.showSnackBar(context, res.message ?? 'Lưu thất bại',
              isError: true);
      }
    } catch (_) {
      if (mounted)
        Helpers.showSnackBar(context, 'Lưu địa chỉ thất bại. Vui lòng thử lại.',
            isError: true);
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('Tên người nhận *'),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _nameCtrl,
                hintText: 'Nguyễn Văn A',
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.required(v, 'Tên người nhận'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              _buildLabel('Số điện thoại *'),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _phoneCtrl,
                hintText: '0901234567',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              _buildLabel('Địa chỉ (số nhà, tên đường) *'),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _addressLineCtrl,
                hintText: '123 Đường Lê Lợi',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => Validators.required(v, 'Địa chỉ'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              _buildLabel('Phường/Xã'),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _wardCtrl,
                hintText: 'Phường Bến Nghé (không bắt buộc)',
                prefixIcon: Icons.holiday_village_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              _buildLabel('Quận/Huyện *'),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _districtCtrl,
                hintText: 'Quận 1',
                prefixIcon: Icons.map_outlined,
                validator: (v) => Validators.required(v, 'Quận/Huyện'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              _buildLabel('Tỉnh/Thành phố *'),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _cityCtrl,
                hintText: 'TP. Hồ Chí Minh',
                prefixIcon: Icons.location_city_outlined,
                validator: (v) => Validators.required(v, 'Tỉnh/Thành phố'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),

              // Map picker
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRoutes.addressPicker,
                    arguments: {
                      if (_latitude != null) 'latitude': _latitude,
                      if (_longitude != null) 'longitude': _longitude,
                    },
                  );
                  if (result is Map<String, dynamic>) {
                    setState(() {
                      _latitude = result['latitude'];
                      _longitude = result['longitude'];
                    });
                    if (result['address'] != null &&
                        _addressLineCtrl.text.isEmpty) {
                      _addressLineCtrl.text = result['address'] as String;
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _latitude != null
                          ? Colors.black
                          : Colors.grey.shade300,
                    ),
                    color: _latitude != null
                        ? Colors.black.withOpacity(0.02)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _latitude != null ? Icons.check_circle : Icons.map,
                        color: _latitude != null ? Colors.black : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _latitude != null
                              ? 'Vị trí đã chọn (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                              : 'Chọn vị trí trên bản đồ (tùy chọn)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _latitude != null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Colors.grey.shade400, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Default switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Đặt làm địa chỉ mặc định',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Địa chỉ này sẽ được chọn tự động khi thanh toán',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  value: _isDefault,
                  activeColor: Colors.black,
                  onChanged: (v) => setState(() => _isDefault = v),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: isEditing ? 'CẬP NHẬT ĐỊA CHỈ' : 'THÊM ĐỊA CHỈ',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
    );
  }
}
