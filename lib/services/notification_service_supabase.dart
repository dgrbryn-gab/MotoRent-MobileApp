import 'package:flutter/foundation.dart';
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moto_rent_dumaguete/config/supabase_config.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String
      type; // 'reservation_rejected', 'reservation_approved', 'payment_confirmed', etc.
  final bool isRead;
  final String? relatedId; // ID of related reservation, booking, etc.
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] ?? false,
      relatedId: json['related_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NotificationServiceSupabase extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  RealtimeChannel? _channel;

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => unreadCount > 0;
  String? get currentUserId => _currentUserId;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setCurrentUserId(String? userId) {
    // unsubscribe previous subscription if any
    if (_channel != null) {
      SupabaseService.instance.unsubscribe(_channel!);
      _channel = null;
    }

    _currentUserId = userId;

    if (userId != null) {
      // Load initial notifications and subscribe to realtime updates for this user
      loadNotifications(userId);

      _channel = SupabaseService.instance.subscribeToTable(
        SupabaseConfig.notificationsTable,
        (payload) => _handleRealtimePayload(payload),
      );
    } else {
      // clear local cache when signing out
      _notifications.clear();
      notifyListeners();
    }
  }

  void _handleRealtimePayload(dynamic payload) {
    try {
      // payload can be a PostgresChangePayload or a Map depending on implementation
      dynamic newRecord;
      dynamic oldRecord;
      String? event;

      // try common patterns
      if (payload is Map) {
        newRecord = payload['new'] ?? payload['record'];
        oldRecord = payload['old'];
        event = payload['eventType'] ?? payload['type'];
      } else {
        // PostgresChangePayload exposes .record, .newRecord, .oldRecord or .eventType in some versions
        try {
          newRecord = payload.newRecord ?? payload.record;
        } catch (_) {
          newRecord = null;
        }
        try {
          oldRecord = payload.oldRecord;
        } catch (_) {
          oldRecord = null;
        }
        try {
          event = payload.eventType;
        } catch (_) {
          event = null;
        }
      }

      // If the change is not for our current user, ignore
      final candidate = newRecord ?? oldRecord;
      if (candidate == null) return;
      final changedUserId = candidate['user_id'] ?? candidate['userId'];
      if (changedUserId == null || changedUserId != _currentUserId) return;

      // Convert to NotificationModel and update local cache accordingly
      if ((event != null &&
              event.toString().toUpperCase().contains('INSERT')) ||
          (newRecord != null && oldRecord == null)) {
        final notification =
            NotificationModel.fromJson(Map<String, dynamic>.from(newRecord));
        // avoid duplicates
        if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications.insert(0, notification);
          notifyListeners();
        }
      } else if (event != null &&
          event.toString().toUpperCase().contains('UPDATE')) {
        final updated =
            NotificationModel.fromJson(Map<String, dynamic>.from(newRecord));
        final idx = _notifications.indexWhere((n) => n.id == updated.id);
        if (idx != -1) {
          _notifications[idx] = updated;
          notifyListeners();
        } else {
          // If not present, insert
          _notifications.insert(0, updated);
          notifyListeners();
        }
      } else if (event != null &&
          event.toString().toUpperCase().contains('DELETE')) {
        final deletedId = candidate['id'];
        if (deletedId != null) {
          _notifications.removeWhere((n) => n.id == deletedId);
          notifyListeners();
        }
      }
    } catch (e) {
      // Non-fatal: just log
      print('Realtime notification handling error: ${e.toString()}');
    }
  }

  /// Load user notifications from Supabase
  Future<void> loadNotifications(String userId) async {
    _setLoading(true);
    _setError(null);
    _currentUserId = userId;

    try {
      final data = await _supabaseService.getAll(
        SupabaseConfig.notificationsTable,
      );

      _notifications = data
          .map((json) => NotificationModel.fromJson(json))
          .where((n) => n.userId == userId)
          .toList();

      // Sort by creation date (newest first)
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load notifications: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Create a new notification
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'related_id': relatedId,
      };

      final data = await _supabaseService.insert(
        SupabaseConfig.notificationsTable,
        notificationData,
      );

      final notification = NotificationModel.fromJson(data);

      // Add to local cache if it's for the current user
      if (userId == _currentUserId) {
        _notifications.insert(0, notification);
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Failed to create notification: ${e.toString()}');
      return false;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.update(
        SupabaseConfig.notificationsTable,
        notificationId,
        {'is_read': true},
      );

      // Update local cache
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          relatedId: _notifications[index].relatedId,
          createdAt: _notifications[index].createdAt,
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark notification as read: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    if (_currentUserId == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // Update all unread notifications in database
      final unreadIds = unreadNotifications.map((n) => n.id).toList();

      if (unreadIds.isEmpty) {
        _setLoading(false);
        return true;
      }

      // Batch update in database
      for (final id in unreadIds) {
        await _supabaseService.update(
          SupabaseConfig.notificationsTable,
          id,
          {'is_read': true},
        );
      }

      // Update local cache
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = NotificationModel(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            title: _notifications[i].title,
            message: _notifications[i].message,
            type: _notifications[i].type,
            isRead: true,
            relatedId: _notifications[i].relatedId,
            createdAt: _notifications[i].createdAt,
          );
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark all as read: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete all notifications for current user
  Future<bool> deleteAllNotifications() async {
    if (_currentUserId == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // Delete all notifications for this user from database
      await _supabaseService.client
          .from(SupabaseConfig.notificationsTable)
          .delete()
          .eq('user_id', _currentUserId!);

      // Clear local cache
      _notifications.clear();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete notifications: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
