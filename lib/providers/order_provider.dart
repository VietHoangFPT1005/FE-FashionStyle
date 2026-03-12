import 'package:flutter/foundation.dart';
import '../models/order/order.dart';
import '../models/order/order_detail.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;

  List<OrderSummary> _orders = [];
  OrderDetail? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = ''; // empty = all

  OrderProvider(this._orderService);

  List<OrderSummary> get orders => _orders;
  OrderDetail? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentFilter = status ?? '';
    notifyListeners();

    try {
      final response = await _orderService.getOrders(status: status);
      if (response.success && response.data != null) {
        _orders = response.data!;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load orders';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOrderDetail(int orderId) async {
    _isLoading = true;
    _currentOrder = null;
    notifyListeners();

    try {
      final response = await _orderService.getOrderDetail(orderId);
      if (response.success && response.data != null) {
        _currentOrder = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load order details';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> cancelOrder(int orderId, {String? reason}) async {
    try {
      final response = await _orderService.cancelOrder(orderId, reason: reason);
      if (response.success) {
        await loadOrders(status: _currentFilter.isNotEmpty ? _currentFilter : null);
        return true;
      }
      _errorMessage = response.message;
      notifyListeners();
      return false;
    } catch (e) {
      return false;
    }
  }
}
