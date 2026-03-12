import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/auth/auth_models.dart';
import '../../services/service_locator.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res =
          await sl.authService.forgotPassword(_emailCtrl.text.trim());
      if (res.success) {
        setState(() => _otpSent = true);
        if (mounted)
          Helpers.showSnackBar(
              context, 'Mã OTP đã được gửi đến email của bạn');
      } else {
        if (mounted)
          Helpers.showSnackBar(context, res.message ?? 'Gửi OTP thất bại',
              isError: true);
      }
    } catch (_) {
      if (mounted)
        Helpers.showSnackBar(context, 'Gửi OTP thất bại. Vui lòng thử lại.',
            isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await sl.authService.resetPassword(
        ResetPasswordRequest(
          email: _emailCtrl.text.trim(),
          otp: _otpCtrl.text.trim(),
          newPassword: _newPasswordCtrl.text,
          confirmPassword: _confirmPasswordCtrl.text,
        ),
      );
      if (res.success) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.');
          Navigator.pop(context);
        }
      } else {
        if (mounted)
          Helpers.showSnackBar(
              context, res.message ?? 'Đổi mật khẩu thất bại',
              isError: true);
      }
    } catch (_) {
      if (mounted)
        Helpers.showSnackBar(context, 'Đổi mật khẩu thất bại. Vui lòng thử lại.',
            isError: true);
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
          'Quên mật khẩu',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Step indicator
              Row(
                children: [
                  _buildStep(1, 'Email', !_otpSent),
                  Expanded(
                      child: Divider(
                          color: _otpSent ? Colors.black : Colors.grey.shade300,
                          thickness: 1.5)),
                  _buildStep(2, 'Đặt lại', _otpSent),
                ],
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                // Step 1: Enter email
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nhập địa chỉ email đã đăng ký để nhận mã OTP khôi phục mật khẩu.',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Địa chỉ Email',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _emailCtrl,
                  hintText: 'email@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendOtp(),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'GỬI MÃ OTP',
                  isLoading: _isLoading,
                  onPressed: _sendOtp,
                ),
              ] else ...[
                // Step 2: Enter OTP and new password
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mã OTP đã được gửi tới ${_emailCtrl.text}. Vui lòng kiểm tra hộp thư.',
                          style: TextStyle(
                              color: Colors.green.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Mã OTP',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _otpCtrl,
                  hintText: 'Nhập mã 6 chữ số',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Vui lòng nhập mã OTP';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                Text('Mật khẩu mới',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _newPasswordCtrl,
                  hintText: 'Ít nhất 6 ký tự',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureNew,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Xác nhận mật khẩu mới',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _confirmPasswordCtrl,
                  hintText: 'Nhập lại mật khẩu mới',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  validator: (v) =>
                      Validators.confirmPassword(v, _newPasswordCtrl.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _resetPassword(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'ĐẶT LẠI MẬT KHẨU',
                  isLoading: _isLoading,
                  onPressed: _resetPassword,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: Text(
                      'Không nhận được mã? Gửi lại OTP',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.black : Colors.grey.shade500,
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
