import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/auth/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/helpers.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        if (mounted) Helpers.showSnackBar(context, 'Vui lòng đăng nhập lại', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      final res = await sl.authService.resendOtp(user.email, type: 'RESET_PASSWORD');
      if (res.success) {
        setState(() => _otpSent = true);
        if (mounted) Helpers.showSnackBar(context, 'OTP đã được gửi đến email của bạn');
      } else {
        if (mounted) Helpers.showSnackBar(context, res.message ?? 'Gửi OTP thất bại', isError: true);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Gửi OTP thất bại: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await sl.authService.changePassword(
        ChangePasswordRequest(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
          otpCode: _otpCtrl.text.trim(),
        ),
      );
      if (res.success) {
        if (mounted) {
          Helpers.showSnackBar(context, '✅ Đổi mật khẩu thành công!');
          Navigator.pop(context);
        }
      } else {
        // Dịch lỗi từ BE sang tiếng Việt cho dễ đọc
        final rawMsg = res.message ?? '';
        final String displayMsg;
        if (rawMsg.toLowerCase().contains('current password is incorrect')) {
          displayMsg = 'Mật khẩu hiện tại không đúng';
        } else if (rawMsg.toLowerCase().contains('invalid or expired')) {
          displayMsg = 'Mã OTP không hợp lệ hoặc đã hết hạn. Vui lòng gửi lại OTP';
        } else if (rawMsg.toLowerCase().contains('different')) {
          displayMsg = 'Mật khẩu mới phải khác mật khẩu hiện tại';
        } else if (rawMsg.isNotEmpty) {
          displayMsg = rawMsg;
        } else {
          displayMsg = 'Đổi mật khẩu thất bại. Vui lòng thử lại';
        }
        if (mounted) Helpers.showSnackBar(context, displayMsg, isError: true);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Lỗi kết nối: $e', isError: true);
    }
    setState(() => _isLoading = false);
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
          'Đổi mật khẩu',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              Row(
                children: [
                  _buildStep(1, 'Xác nhận', !_otpSent),
                  Expanded(
                    child: Divider(
                        color: _otpSent ? Colors.black : Colors.grey.shade300,
                        thickness: 1.5)),
                  _buildStep(2, 'Đổi mật khẩu', _otpSent),
                ],
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                // Step 1
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Để bảo mật tài khoản, chúng tôi sẽ gửi mã OTP đến email của bạn để xác nhận thay đổi mật khẩu.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'GỬI MÃ XÁC NHẬN',
                  isLoading: _isLoading,
                  onPressed: _sendOtp,
                ),
              ] else ...[
                // Step 2: OTP + new password
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Mã OTP đã được gửi tới email của bạn. Vui lòng kiểm tra hộp thư.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Mã OTP',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _otpCtrl,
                  hintText: 'Nhập mã 6 chữ số',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mã OTP' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                const Text('Mật khẩu hiện tại',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _currentPasswordCtrl,
                  hintText: 'Nhập mật khẩu hiện tại',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureCurrent,
                  validator: (v) => Validators.required(v, 'Mật khẩu hiện tại'),
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Mật khẩu mới',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _newPasswordCtrl,
                  hintText: 'Ít nhất 6 ký tự',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureNew,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Xác nhận mật khẩu mới',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _confirmPasswordCtrl,
                  hintText: 'Nhập lại mật khẩu mới',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  validator: (v) => Validators.confirmPassword(v, _newPasswordCtrl.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _changePassword(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'ĐỔI MẬT KHẨU',
                  isLoading: _isLoading,
                  onPressed: _changePassword,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: Text(
                      'Không nhận được mã? Gửi lại OTP',
                      style: TextStyle(
                        color: Colors.black, fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$number',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.black : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}
