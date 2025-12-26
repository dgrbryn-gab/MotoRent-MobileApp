import 'package:flutter/foundation.dart';
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:moto_rent_dumaguete/models/message.dart';
import 'package:moto_rent_dumaguete/services/notification_service_supabase.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;
  final NotificationServiceSupabase _notificationService =
      NotificationServiceSupabase();

  ContactMessage? _currentMessage;
  List<ContactMessage> _userMessages = [];
  String? _error;
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel; // Track channel for cleanup

  ContactMessage? get currentMessage => _currentMessage;
  List<ContactMessage> get userMessages => _userMessages;
  String? get error => _error;
  bool get isLoading => _isLoading;

  /// Get user's existing contact messages - loads all conversations
  Future<ContactMessage?> getUserContactMessage(String userEmail) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load ALL messages for this user (all conversations)
      final allMessages = await _supabase.client
          .from('contact_messages')
          .select()
          .eq('email', userEmail)
          .order('created_at',
              ascending: true); // Oldest first for conversation

      _userMessages = (allMessages as List)
          .map((msg) => ContactMessage.fromJson(msg as Map<String, dynamic>))
          .toList();

      // Set the most recent message as current
      if (_userMessages.isNotEmpty) {
        _currentMessage = _userMessages.last;
      } else {
        _currentMessage = null;
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
      return _currentMessage;
    } catch (e) {
      _error = 'Failed to fetch messages: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load a specific contact message by ID and refresh all user messages
  Future<bool> loadContactMessage(String messageId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.client
          .from('contact_messages')
          .select()
          .eq('id', messageId)
          .single();

      _currentMessage = ContactMessage.fromJson(response);

      // Also reload all messages for this email to keep conversation history in sync
      if (_currentMessage != null) {
        final allMessages = await _supabase.client
            .from('contact_messages')
            .select()
            .eq('email', _currentMessage!.email)
            .order('created_at', ascending: true);

        _userMessages = (allMessages as List)
            .map((msg) => ContactMessage.fromJson(msg as Map<String, dynamic>))
            .toList();
      }

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to load message: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send a new contact message
  Future<String> sendContactMessage({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();

      await _supabase.client.from('contact_messages').insert({
        'id': messageId,
        'name': name,
        'email': email,
        'message': message,
        'created_at': now,
        'updated_at': now,
        // Don't set status - let database use default value
      });

      // Load the newly created message
      await loadContactMessage(messageId);
      return messageId;
    } catch (e) {
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
      return '';
    }
  }

  /// Load all contact messages (admin view)
  Future<List<ContactMessage>> loadAllContactMessages() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.client
          .from('contact_messages')
          .select()
          .order('created_at', ascending: false);

      final messages = (response as List)
          .map((msg) => ContactMessage.fromJson(msg as Map<String, dynamic>))
          .toList();

      _error = null;
      _isLoading = false;
      notifyListeners();
      return messages;
    } catch (e) {
      _error = 'Failed to load messages: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Update message status
  Future<bool> updateMessageStatus(String messageId, String status) async {
    try {
      await _supabase.client.from('contact_messages').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);

      // Reload the message
      await loadContactMessage(messageId);
      return true;
    } catch (e) {
      _error = 'Failed to update status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete a contact message
  Future<bool> deleteContactMessage(String messageId) async {
    try {
      await _supabase.client
          .from('contact_messages')
          .delete()
          .eq('id', messageId);

      _currentMessage = null;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete message: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Listen for real-time updates on a specific message
  /// Automatically refreshes the message when admin replies
  Future<void> listenForReplies(String messageId, String userId) async {
    try {
      // Cancel previous subscription if exists
      await stopListeningForReplies();

      print('DEBUG: Setting up realtime listener for message: $messageId');

      // Set up periodic check as fallback (every 5 seconds)
      // This ensures the message is refreshed even if realtime fails
      Future.microtask(() async {
        while (_realtimeChannel != null) {
          await Future.delayed(const Duration(seconds: 5));
          if (_realtimeChannel != null) {
            print('DEBUG: Periodic refresh check for message: $messageId');
            final success = await loadContactMessage(messageId);
            if (success) {
              notifyListeners();
              // If reply was found, we're done checking
              if (_currentMessage?.replyMessage != null) {
                print('DEBUG: Admin reply detected in periodic check!');
                break;
              }
            }
          }
        }
      });

      // Subscribe to real-time updates on contact_messages table
      _realtimeChannel = _supabase.client
          .channel('public:contact_messages')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'contact_messages',
            callback: (payload) async {
              try {
                print('DEBUG: Received realtime update');

                // Extract the updated record
                final newRecord = payload.newRecord;
                print('DEBUG: Update payload received, record: $newRecord');

                final updatedId = newRecord['id'];
                print(
                    'DEBUG: Updated message ID: $updatedId, Listening for: $messageId');

                // Only process if this is the message we're listening for
                if (updatedId != messageId) {
                  print('DEBUG: Ignoring update for different message ID');
                  return;
                }

                print('DEBUG: This is our message! Reloading...');

                // When this message is updated, reload it
                final success = await loadContactMessage(messageId);
                print('DEBUG: Message reload success: $success');

                if (success && _currentMessage != null) {
                  print(
                      'DEBUG: Loaded reply: ${_currentMessage?.replyMessage}');
                  print(
                      'DEBUG: Loaded repliedAt: ${_currentMessage?.repliedAt}');

                  // Always notify listeners when message is updated
                  notifyListeners();

                  // Check if admin just replied
                  if (_currentMessage!.replyMessage != null &&
                      _currentMessage!.repliedAt != null) {
                    print('DEBUG: Admin has replied! Creating notification...');

                    // Create a notification for the user
                    await _notificationService.createNotification(
                      userId: userId,
                      title: 'New Reply from Admin',
                      message: 'Check your message for the admin\'s response',
                      type: 'contact_message_reply',
                    );
                    print('DEBUG: Notification created successfully');
                  }
                }
              } catch (e, stackTrace) {
                print('ERROR processing realtime update: $e\n$stackTrace');
              }
            },
          )
          .subscribe();

      print('DEBUG: Realtime listener subscribed successfully');
    } catch (e, stackTrace) {
      _error = 'Failed to setup real-time listener: ${e.toString()}';
      print('DEBUG: Error setting up listener: $e\n$stackTrace');
      notifyListeners();
    }
  }

  /// Stop listening for real-time updates
  Future<void> stopListeningForReplies() async {
    try {
      if (_realtimeChannel != null) {
        print('DEBUG: Unsubscribing from realtime listener');
        await _supabase.client.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }
    } catch (e) {
      print('Error stopping real-time listener: $e');
    }
  }

  @override
  void dispose() {
    // Clean up real-time subscription when service is disposed
    if (_realtimeChannel != null) {
      _supabase.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
    super.dispose();
  }
}
