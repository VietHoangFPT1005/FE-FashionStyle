import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';

class AdminProductFormScreen extends StatefulWidget {
  /// null = tạo mới, có giá trị = chỉnh sửa
  final Map<String, dynamic>? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loadingDetail = false;

  // controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _materialCtrl;
  late final TextEditingController _brandCtrl;

  String? _selectedGender;
  int? _selectedCategoryId;
  bool _isFeatured = false;
  bool _isActive = true;

  List<Map<String, dynamic>> _categories = [];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _slugCtrl = TextEditingController(text: p?['slug'] ?? '');
    _descCtrl = TextEditingController(text: p?['description'] ?? '');
    _priceCtrl = TextEditingController(text: p != null ? '${(p['price'] ?? p['basePrice'] ?? 0)}' : '');
    _salePriceCtrl = TextEditingController(text: p != null && p['salePrice'] != null ? '${p['salePrice']}' : '');
    _materialCtrl = TextEditingController(text: p?['material'] ?? '');
    _brandCtrl = TextEditingController(text: p?['brandName'] ?? '');
    _selectedGender = p?['gender'];
    _selectedCategoryId = p?['categoryId'] as int?;
    _isFeatured = p?['isFeatured'] == true;
    _isActive = p?['isActive'] != false;

    _loadCategories();
    if (_isEdit) _loadProductDetail();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _materialCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await sl.categoryService.getCategories();
      if (res.success && res.data != null) {
        // Deduplicate by categoryId để tránh lỗi "2 or more items with same value"
        final seen = <int>{};
        final unique = <Map<String, dynamic>>[];
        for (final c in res.data!) {
          if (seen.add(c.categoryId)) {
            unique.add({'id': c.categoryId, 'name': c.name});
          }
        }
        setState(() => _categories = unique);
      }
    } catch (_) {}
  }

  Future<void> _loadProductDetail() async {
    final id = widget.product!['productId'] ?? widget.product!['id'];
    if (id == null) return;
    setState(() => _loadingDetail = true);
    try {
      final res = await sl.adminService.getProductDetail(id as int);
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        setState(() {
          _nameCtrl.text = d['name'] ?? _nameCtrl.text;
          _slugCtrl.text = d['slug'] ?? _slugCtrl.text;
          _descCtrl.text = d['description'] ?? _descCtrl.text;
          _priceCtrl.text = '${d['price'] ?? d['basePrice'] ?? _priceCtrl.text}';
          if (d['salePrice'] != null) _salePriceCtrl.text = '${d['salePrice']}';
          _materialCtrl.text = d['material'] ?? _materialCtrl.text;
          _brandCtrl.text = d['brandName'] ?? _brandCtrl.text;
          _selectedGender = d['gender'] ?? _selectedGender;
          _selectedCategoryId = d['categoryId'] as int? ?? _selectedCategoryId;
          _isFeatured = d['isFeatured'] == true;
          _isActive = d['isActive'] != false;
        });
      }
    } catch (_) {}
    setState(() => _loadingDetail = false);
  }

  void _autoSlug(String name) {
    if (!_isEdit || _slugCtrl.text.isEmpty) {
      _slugCtrl.text = name
          .toLowerCase()
          .replaceAll(RegExp(r'[àáảãạăắặẳẵằâấậẩẫầ]'), 'a')
          .replaceAll(RegExp(r'[èéẻẽẹêếệểễề]'), 'e')
          .replaceAll(RegExp(r'[ìíỉĩị]'), 'i')
          .replaceAll(RegExp(r'[òóỏõọôốộổỗồơớợởỡờ]'), 'o')
          .replaceAll(RegExp(r'[ùúủũụưứựửữừ]'), 'u')
          .replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y')
          .replaceAll(RegExp(r'[đ]'), 'd')
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'slug': _slugCtrl.text.trim(),
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0,
      if (_salePriceCtrl.text.isNotEmpty) 'salePrice': double.tryParse(_salePriceCtrl.text.replaceAll(',', '')),
      if (_materialCtrl.text.isNotEmpty) 'material': _materialCtrl.text.trim(),
      if (_brandCtrl.text.isNotEmpty) 'brandName': _brandCtrl.text.trim(),
      if (_selectedGender != null) 'gender': _selectedGender,
      if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
      'isFeatured': _isFeatured,
      if (_isEdit) 'isActive': _isActive,
    };

    try {
      final res = _isEdit
          ? await sl.adminService.updateProduct(
              (widget.product!['productId'] ?? widget.product!['id']) as int, data)
          : await sl.adminService.createProduct(data);

      if (!mounted) return;
      if (res.success) {
        Helpers.showSnackBar(context, _isEdit ? 'Cập nhật thành công!' : 'Tạo sản phẩm thành công!');
        Navigator.pop(context, true);
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Có lỗi: $e', isError: true);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Chỉnh sửa sản phẩm' : 'Tạo sản phẩm'),
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _card([
                    _label('Thông tin cơ bản'),
                    _field(_nameCtrl, 'Tên sản phẩm *', onChanged: _autoSlug, validator: (v) => (v ?? '').isEmpty ? 'Bắt buộc' : null),
                    const SizedBox(height: 12),
                    _field(_slugCtrl, 'Slug *', validator: (v) => (v ?? '').isEmpty ? 'Bắt buộc' : null),
                    const SizedBox(height: 12),
                    _field(_descCtrl, 'Mô tả', maxLines: 3),
                  ]),

                  const SizedBox(height: 12),
                  _card([
                    _label('Giá'),
                    _field(_priceCtrl, 'Giá gốc (VNĐ) *',
                        keyboardType: TextInputType.number,
                        validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '')) ?? -1) < 0 ? 'Nhập giá hợp lệ' : null),
                    const SizedBox(height: 12),
                    _field(_salePriceCtrl, 'Giá khuyến mãi (VNĐ)', keyboardType: TextInputType.number),
                  ]),

                  const SizedBox(height: 12),
                  _card([
                    _label('Phân loại'),
                    _dropdownCategory(),
                    const SizedBox(height: 12),
                    _dropdownGender(),
                    const SizedBox(height: 12),
                    _field(_brandCtrl, 'Thương hiệu'),
                    const SizedBox(height: 12),
                    _field(_materialCtrl, 'Chất liệu'),
                  ]),

                  const SizedBox(height: 12),
                  _card([
                    _label('Cài đặt'),
                    SwitchListTile(
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      title: const Text('Nổi bật', style: TextStyle(fontSize: 14)),
                      dense: true,
                    ),
                    if (_isEdit)
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text('Đang hoạt động', style: TextStyle(fontSize: 14)),
                        dense: true,
                      ),
                  ]),

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit ? 'Cập nhật sản phẩm' : 'Tạo sản phẩm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
  );

  Widget _field(TextEditingController ctrl, String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _dropdownCategory() {
    // Đảm bảo value luôn tồn tại trong items — tránh assertion "no matching item"
    final validCategoryId = _categories.any((c) => c['id'] == _selectedCategoryId)
        ? _selectedCategoryId
        : null;

    return DropdownButtonFormField<int>(
      value: validCategoryId,
      decoration: InputDecoration(
        labelText: 'Danh mục',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('-- Không chọn --')),
        ..._categories.map((c) => DropdownMenuItem<int>(
          value: c['id'] as int,
          child: Text(c['name'] as String),
        )),
      ],
      onChanged: (v) => setState(() => _selectedCategoryId = v),
    );
  }

  Widget _dropdownGender() {
    const validGenders = ['Nam', 'Nữ', 'Unisex'];
    // Nếu BE trả về giá trị không nằm trong list (vd: 'MALE', 'male') → set null
    final validGender = validGenders.contains(_selectedGender) ? _selectedGender : null;

    return DropdownButtonFormField<String>(
      value: validGender,
      decoration: InputDecoration(
        labelText: 'Giới tính',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('-- Không chọn --')),
        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
        DropdownMenuItem(value: 'Unisex', child: Text('Unisex')),
      ],
      onChanged: (v) => setState(() => _selectedGender = v),
    );
  }
}
