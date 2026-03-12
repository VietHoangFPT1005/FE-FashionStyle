import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_routes.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/helpers.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otp.trim();
    if (otp.length < 6) {
      Helpers.showSnackBar(context, 'Vui lòng nhập đủ 6 chữ số OTP',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response =
          await sl.authService.verifyEmail(widget.email, otp);
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.success) {
          Helpers.showSnackBar(
              context, 'Xác thực email thành công! Vui lòng đăng nhập.');
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (r) => false);
        } else {
          Helpers.showSnackBar(
              context, response.message ?? 'Mã OTP không đúng. Vui lòng thử lại.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showSnackBar(context, 'Đã xảy ra lỗi. Vui lòng thử lại.',
            isError: true);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final response =
          await sl.authService.resendOtp(widget.email, type: 'VERIFY_EMAIL');
      if (mounted) {
        setState(() => _isResending = false);
        Helpers.showSnackBar(
          context,
          response.success
              ? 'Đã gửi lại mã OTP mới tới email của bạn.'
              : (response.message ?? 'Không thể gửi lại OTP.'),
          isError: !response.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        Helpers.showSnackBar(context, 'Đã xảy ra lỗi khi gửi lại OTP.',
            isError: true);
      }
    }
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 28),

              Text(
                'Xác thực Email',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chúng tôi đã gửi mã OTP gồm 6 chữ số tới:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 36),

              // OTP input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildOtpBox(i)),
              ),
              const SizedBox(height: 36),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'XÁC THỰC',
                  isLoading: _isLoading,
                  onPressed: _verifyOtp,
                ),
              ),
              const SizedBox(height: 24),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Không nhận được mã? ',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : GestureDetector(
                          onTap: _resendOtp,
                          child: const Text(
                            'Gửi lại',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Mã OTP có hiệu lực trong 10 phút.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && val.isNotEmpty && _otp.length == 6) {
            _verifyOtp();
          }
        },
      ),
    );
  }
}
