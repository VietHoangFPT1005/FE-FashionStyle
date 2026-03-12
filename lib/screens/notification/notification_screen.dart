import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/notification_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  IconData _getNotifIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'ORDER':
        return Icons.shopping_bag_outlined;
      case 'PAYMENT':
        return Icons.payment_outlined;
      case 'SHIPPING':
        return Icons.local_shipping_outlined;
      case 'REFUND':
        return Icons.assignment_return_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotifColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'ORDER':
        return Colors.blue;
      case 'PAYMENT':
        return Colors.green;
      case 'SHIPPING':
        return Colors.orange;
      case 'REFUND':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Thông báo',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) => provider.unreadCount > 0
                ? TextButton(
                    onPressed: () => provider.markAllAsRead(),
                    child: Text(
                      'Đọc tất cả',
                      style: TextStyle(
                          color: Colors.black, fontSize: 13),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const LoadingWidget();
          if (provider.notifications.isEmpty) {
            return const EmptyWidget(
              message: 'Không có thông báo nào',
              icon: Icons.notifications_none,
            );
          }
          return RefreshIndicator(
            color: Colors.black,
            onRefresh: () => provider.loadNotifications(),
            child: ListView.separated(
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (_, i) {
                final n = provider.notifications[i];
                final color = _getNotifColor(n.type);
                return GestureDetector(
                  onTap: () => provider.markAsRead(n.notificationId),
                  child: Container(
                    color: n.isRead ? Colors.white : Colors.black.withOpacity(0.02),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getNotifIcon(n.type),
                              color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontWeight: n.isRead
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600),
                              ),
                              if (n.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(n.createdAt!, locale: 'vi'),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
