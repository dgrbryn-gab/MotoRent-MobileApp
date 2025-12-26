import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/services/messaging_service.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MessagingScreen extends StatefulWidget {
  final String? messageId; // ID of existing contact message
  final String? userEmail; // Email if creating new message

  const MessagingScreen({
    super.key,
    this.messageId,
    this.userEmail,
  });

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessage();
      _setupRealtimeListener();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    // Stop listening for real-time updates when screen closes
    final messagingService =
        Provider.of<MessagingService>(context, listen: false);
    messagingService.stopListeningForReplies();
    super.dispose();
  }

  Future<void> _loadMessage() async {
    final messagingService =
        Provider.of<MessagingService>(context, listen: false);

    if (widget.messageId != null) {
      await messagingService.loadContactMessage(widget.messageId!);
    } else if (widget.userEmail != null) {
      await messagingService.getUserContactMessage(widget.userEmail!);
    }
  }

  Future<void> _setupRealtimeListener() async {
    final messagingService =
        Provider.of<MessagingService>(context, listen: false);
    final authService =
        Provider.of<AuthServiceSupabase>(context, listen: false);

    final userId = authService.currentUser?.id;
    if (userId == null) return;

    // If we have a message ID, listen for real-time updates
    if (widget.messageId != null) {
      await messagingService.listenForReplies(widget.messageId!, userId);
    } else if (messagingService.currentMessage != null) {
      // If we loaded a message by email, listen for updates
      await messagingService.listenForReplies(
          messagingService.currentMessage!.id, userId);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authService =
        Provider.of<AuthServiceSupabase>(context, listen: false);
    final messagingService =
        Provider.of<MessagingService>(context, listen: false);

    if (authService.currentUser == null) return;

    setState(() => _isSending = true);

    final messageId = await messagingService.sendContactMessage(
      name: authService.currentUser!.name,
      email: authService.currentUser!.email,
      message: _messageController.text.trim(),
    );

    if (messageId.isNotEmpty) {
      _messageController.clear();
      // Refresh the current message
      await _loadMessage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messagingService.error ?? 'Failed to send message'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.backgroundColor : AppTheme.lightBackgroundColor;
    final bgSecondary = isDark
        ? AppTheme.backgroundSecondary
        : AppTheme.lightBackgroundSecondary;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Admin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Refresh button to manually check for admin replies
          Consumer<MessagingService>(
            builder: (context, messagingService, _) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  if (messagingService.currentMessage != null) {
                    await messagingService.loadContactMessage(
                        messagingService.currentMessage!.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message refreshed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, bgSecondary],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Consumer<MessagingService>(
                builder: (context, messagingService, child) {
                  if (messagingService.isLoading &&
                      messagingService.currentMessage == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }

                  final message = messagingService.currentMessage;

                  if (message == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type your message below',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final timeFormat = DateFormat('MMM dd, hh:mm a');

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User's message
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.85,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message.message,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeFormat.format(message.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Admin's reply (if available)
                        if (message.replyMessage != null) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.85,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Reply',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message.replyMessage!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timeFormat.format(message.repliedAt!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Status badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(message.status)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(message.status),
                              ),
                            ),
                            child: Text(
                              message.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(message.status),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade400.withOpacity(0.3),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: textPrimary),
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: textSecondary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _isSending ? null : _sendMessage,
                      mini: true,
                      backgroundColor: AppTheme.primaryColor,
                      disabledElevation: 0,
                      child: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.orange;
      case 'replied':
        return Colors.green;
      case 'resolved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
