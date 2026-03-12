import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user/user.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender;
  DateTime? _dateOfBirth;
  bool _isLoading = true;
  bool _isSaving = false;

  // Body profile
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();



  @override
  void initState() {
    super.initState();
    // services from sl
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profileRes = await sl.userService.getProfile();
      if (profileRes.success && profileRes.data != null) {
        final p = profileRes.data!;
        _nameCtrl.text = p.fullName;
        _phoneCtrl.text = p.phone ?? '';
        _gender = p.gender;
        _dateOfBirth = p.dateOfBirth;
      }
      final bodyRes = await sl.userService.getBodyProfile();
      if (bodyRes.success && bodyRes.data != null) {
        final b = bodyRes.data!;
        _heightCtrl.text = b.height?.toString() ?? '';
        _weightCtrl.text = b.weight?.toString() ?? '';
        _chestCtrl.text = b.chest?.toString() ?? '';
        _waistCtrl.text = b.waist?.toString() ?? '';
        _hipsCtrl.text = b.hips?.toString() ?? '';
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final profileReq = UpdateProfileRequest(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        gender: _gender,
        dateOfBirth: _dateOfBirth?.toIso8601String().substring(0, 10),
      );
      await sl.userService.updateProfile(profileReq);

      final bodyReq = BodyProfile(
        height: double.tryParse(_heightCtrl.text),
        weight: double.tryParse(_weightCtrl.text),
        chest: double.tryParse(_chestCtrl.text),
        waist: double.tryParse(_waistCtrl.text),
        hips: double.tryParse(_hipsCtrl.text),
      );
      await sl.userService.updateBodyProfile(bodyReq);

      if (mounted) {
        Helpers.showSnackBar(context, 'Cập nhật thành công!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Cập nhật thất bại', isError: true);
    }
    setState(() => _isSaving = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0,
          title: Text('Chỉnh sửa thông tin',
            style: GoogleFonts.cormorantGaramond(
                color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        body: const LoadingWidget(),
      );
    }

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
          'Chỉnh sửa thông tin',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic info section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      const Text('Thông tin cá nhân',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Họ và tên *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _nameCtrl,
                      hintText: 'Nguyễn Văn A',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => Validators.required(v, 'Họ và tên'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const Text('Số điện thoại',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _phoneCtrl,
                      hintText: '0901234567',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const Text('Giới tính',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        hintText: 'Chọn giới tính',
                        prefixIcon: const Icon(Icons.wc, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Colors.black)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        filled: true, fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                        DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ngày sinh',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(children: [
                          Icon(Icons.cake_outlined, size: 20,
                              color: Colors.grey.shade500),
                          const SizedBox(width: 12),
                          Text(
                            _dateOfBirth != null
                                ? Helpers.formatDate(_dateOfBirth!)
                                : 'Chọn ngày sinh',
                            style: TextStyle(
                              fontSize: 14,
                              color: _dateOfBirth != null
                                  ? Colors.black87 : Colors.grey.shade400),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              color: Colors.grey.shade400, size: 18),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Body profile section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.accessibility_new_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text('Số đo cơ thể',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text('Để nhận gợi ý size phù hợp',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildBodyField(_heightCtrl, 'Chiều cao (cm)')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBodyField(_weightCtrl, 'Cân nặng (kg)')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildBodyField(_chestCtrl, 'Vòng ngực (cm)')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBodyField(_waistCtrl, 'Vòng eo (cm)')),
                    ]),
                    const SizedBox(height: 12),
                    _buildBodyField(_hipsCtrl, 'Vòng mông (cm)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'LƯU THAY ĐỔI',
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.black)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true, fillColor: Colors.white,
      ),
    );
  }

  // fix: also update _save to use proper Vietnamese
  // Override: replace all Vietnamese text with diacritics (done inline above)
}
