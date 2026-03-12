import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth/auth_models.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(RegisterRequest(
      username: _usernameCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
    ));
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Đăng ký thành công! Kiểm tra email để xác thực tài khoản.')),
      );
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.verifyEmail,
        arguments: _emailCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tạo tài khoản',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tham gia cùng Lumina Style ngay hôm nay',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Username
                      _buildLabel('Tên đăng nhập *'),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: _usernameCtrl,
                        hintText: 'Ví dụ: nguyenvan123',
                        prefixIcon: Icons.alternate_email,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Vui lòng nhập tên đăng nhập';
                          if (v.trim().length < 3)
                            return 'Tên đăng nhập ít nhất 3 ký tự';
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim()))
                            return 'Chỉ cho phép chữ cái, số và dấu gạch dưới';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Full name
                      _buildLabel('Họ và tên *'),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: _nameCtrl,
                        hintText: 'Nguyễn Văn A',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => Validators.required(v, 'Họ tên'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _buildLabel('Email *'),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: _emailCtrl,
                        hintText: 'email@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildLabel('Số điện thoại'),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: _phoneCtrl,
                        hintText: '0901234567 (tùy chọn)',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _buildLabel('Mật khẩu *'),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: _passwordCtrl,
                        hintText: 'Ít nhất 6 ký tự',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: Validators.password,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm password
                      _buildLabel('Xác nhận mật khẩu *'),
                      const SizedBox(height: 6),
                      CustomTextField(
                        controller: _confirmCtrl,
                        hintText: 'Nhập lại mật khẩu',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        validator: (v) =>
                            Validators.confirmPassword(v, _passwordCtrl.text),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _register(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Error
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) {
                          if (auth.errorMessage != null) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border:
                                    Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade600, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 16),

                      // Terms note
                      Text(
                        'Bằng cách đăng ký, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của chúng tôi.',
                        style:
                            TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Register button
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) => CustomButton(
                          text: 'ĐĂNG KÝ',
                          isLoading: auth.status == AuthStatus.loading,
                          onPressed: _register,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Đăng nhập',
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
                    ],
                  ),
                ),
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
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}
