import 'database_service.dart';

class NotificationService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Map<String, dynamic>>> getNotifications(String username) async {
    try {
      final notifications = await _databaseService.getNotifications(username);
      return notifications.map((notification) {
        return {
          'id': notification['id'],
          'fromUsername': notification['fromUsername'],
          'type': notification['type'],
          'title': notification['title'],
          'message': notification['message'],
          'data': notification['data'],
          'isRead': notification['isRead'] == 1,
          'date': _formatDate(notification['createdAt']),
          'createdAt': notification['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadNotificationsCount(String username) async {
    try {
      return await _databaseService.getUnreadNotificationsCount(username);
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      return await _databaseService.markNotificationAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(String username) async {
    try {
      return await _databaseService.markAllNotificationsAsRead(username);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Şimdi';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} dakika önce';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} saat önce';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} hafta önce';
      } else {
        return '${(difference.inDays / 30).floor()} ay önce';
      }
    } catch (e) {
      print('Error formatting date: $e');
      return 'Bilinmeyen tarih';
    }
  }
}
