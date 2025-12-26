# Messaging System Setup Guide

## Overview
A complete user-admin messaging system has been implemented in the MotoRent Dumaguete Flutter app. Users can now send messages to admins directly from the Contact Us page, and conversations are tracked in the Supabase database.

## Components Implemented

### 1. Database Schema
**File:** `add_messaging_tables.sql`

Two new tables have been created in Supabase:

#### `conversations` table
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to users)
- `user_name` (TEXT)
- `user_email` (TEXT)
- `last_message` (TEXT) - Latest message preview
- `last_message_time` (TIMESTAMP)
- `has_unread_messages` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `messages` table
- `id` (UUID, Primary Key)
- `conversation_id` (UUID, Foreign Key to conversations)
- `sender_id` (UUID)
- `sender_name` (TEXT)
- `message` (TEXT)
- `is_from_admin` (BOOLEAN) - Flag to identify message source
- `created_at` (TIMESTAMP)

**Triggers:**
- Auto-update `conversation.last_message` and `last_message_time` on new messages
- Auto-set `has_unread_messages` when admin sends messages

### 2. Data Models
**File:** `lib/models/message.dart`

#### `Message` class
Represents individual messages with serialization support:
- `id` - Unique message identifier
- `conversationId` - Reference to conversation
- `senderId` - Who sent the message
- `senderName` - Display name of sender
- `message` - Message content
- `createdAt` - Timestamp
- `isFromAdmin` - Whether sent by admin

#### `Conversation` class
Groups messages and tracks conversation metadata:
- `id` - Unique conversation identifier
- `userId` - User's ID
- `userName` - User's name
- `userEmail` - User's email
- `lastMessage` - Latest message preview
- `lastMessageTime` - When last message was sent
- `hasUnreadMessages` - Unread status

### 3. Messaging Service
**File:** `lib/services/messaging_service.dart`

A `ChangeNotifier` service that manages all messaging operations:

#### Key Methods

**`getAdminConversationId(userId, userName, userEmail)`**
- Gets existing conversation or creates new one for user
- Returns conversation ID for use in chat screen
- Called when user opens messaging

**`loadMessages(conversationId)`**
- Fetches all messages for a conversation
- Orders by creation time (oldest first)
- Updates internal state and notifies listeners

**`sendMessage(conversationId, senderId, senderName, message, isFromAdmin)`**
- Inserts new message into database
- Automatically updates conversation's last_message fields
- Notifies listeners of new message

**`loadConversations()`**
- Fetches all conversations (admin view)
- Lists all user conversations with latest message preview
- Useful for admin dashboard

**`markConversationAsRead(conversationId)`**
- Sets `has_unread_messages` to false
- Called when user/admin views conversation

**`deleteConversation(conversationId)`**
- Admin-only cascade delete
- Deletes conversation and all associated messages

### 4. Messaging UI Screen
**File:** `lib/screens/messaging/messaging_screen.dart`

A full-featured chat interface with:

**Features:**
- Displays all messages in chronological order
- Left-aligned messages from admin (labeled with sender name)
- Right-aligned messages from user
- Timestamps for each message
- Text input field with send button
- Auto-scroll to latest message
- Loading indicator while fetching messages
- Error handling with user feedback
- Theme-aware colors (light/dark mode support)

**Usage:**
```dart
MessagingScreen(conversationId: 'conversation-uuid')
```

### 5. Contact Page Integration
**File:** `lib/screens/profile/contact_screen.dart`

Updated to include messaging channel:

**Changes:**
- Added message button in contact methods section
- Displays "Message" option alongside Phone and Email
- Button labeled "Open Chat"
- Integrated with `_openMessaging()` method

**Flow:**
1. User clicks "Open Chat" button
2. App checks if user is authenticated
3. Gets or creates admin conversation ID
4. Navigates to MessagingScreen
5. Conversation loads and displays messages

### 6. Service Registration
**File:** `lib/main.dart`

MessagingService is registered as a provider:

```dart
ChangeNotifierProvider(create: (_) => MessagingService()),
```

This makes the service available throughout the app via:
```dart
Provider.of<MessagingService>(context)
```

## Implementation Steps Completed

✅ **Database Setup**
- SQL schema with conversations and messages tables
- Automatic triggers for updating conversation metadata
- Proper indexing for performance

✅ **Model Classes**
- Message and Conversation models with JSON serialization
- Full support for converting to/from Supabase data

✅ **Messaging Service**
- Complete CRUD operations for messages
- Conversation management
- Error handling with fallback states

✅ **UI Components**
- MessagingScreen with full chat functionality
- Theme-aware styling
- Message display with sender identification
- Input field and send button

✅ **Contact Page Integration**
- New messaging button added
- User authentication check
- Conversation initialization logic

✅ **State Management**
- Provider pattern for reactive updates
- Service registered in main.dart
- Proper disposal of resources

## Setup Instructions for Developers

### 1. Create Database Tables
Execute the SQL in `add_messaging_tables.sql` in Supabase:
- Go to Supabase Dashboard > SQL Editor
- Create new query
- Paste contents of `add_messaging_tables.sql`
- Run the query

### 2. Enable Row Level Security (Optional but Recommended)
```sql
-- In Supabase SQL Editor
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create policy for users to view their conversations
CREATE POLICY "Users can view own conversations"
ON public.conversations
FOR SELECT
USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

-- Create policy for users to insert messages
CREATE POLICY "Users can insert messages in their conversations"
ON public.messages
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.conversations
    WHERE id = conversation_id AND user_id = auth.uid()
  )
);
```

### 3. Build and Run
```bash
flutter pub get
flutter run
```

## Testing the Messaging System

### User Flow
1. Navigate to Profile > Contact Us
2. Scroll to "Message" section
3. Click "Open Chat" button
4. Type a message
5. Click send button
6. Message appears in chat history

### Admin Flow (Future Implementation)
1. Create admin messaging dashboard
2. Admin can view all conversations
3. Admin can open any conversation and reply
4. Users see admin replies with `is_from_admin: true`

## Key Features

**For Users:**
- Send direct messages to admin
- View message history
- Real-time conversation updates
- Clean, intuitive chat interface
- Light/dark mode support

**For Admins (Future):**
- View all user conversations
- See unread message indicators
- Reply to user messages
- Delete conversations (cascade delete)
- Message timestamps and user info

## Architecture Decisions

### Data Model
- **Conversations** table: Denormalizes user info and last message for quick access
- **Messages** table: Stores individual messages with admin flag for easy filtering

### Service Pattern
- Uses ChangeNotifier for reactive updates
- Separates database operations from UI logic
- Error handling with state management

### UI/UX
- Messages aligned left (admin) vs right (user) for clarity
- Sender names displayed for admin messages
- Auto-scroll on new messages
- Loading states for better UX

## Future Enhancements

1. **Admin Dashboard**
   - Create admin_messaging_screen.dart
   - Show all conversations with unread badges
   - Real-time conversation updates

2. **Real-time Updates**
   - Implement Supabase Realtime subscriptions
   - Messages update instantly without refresh
   - Typing indicators

3. **Message Features**
   - Edit/delete message functionality
   - Message read receipts
   - Emoji support
   - Image attachments

4. **Notifications**
   - Push notifications for new messages
   - In-app notification badge
   - Sound alerts (optional)

5. **Advanced Filtering**
   - Search conversations
   - Archive conversations
   - Pin important conversations

## File Locations Reference

| Component | File |
|-----------|------|
| Database Schema | `add_messaging_tables.sql` |
| Data Models | `lib/models/message.dart` |
| Service Logic | `lib/services/messaging_service.dart` |
| Chat UI | `lib/screens/messaging/messaging_screen.dart` |
| Contact Integration | `lib/screens/profile/contact_screen.dart` |
| Service Registration | `lib/main.dart` |

## Dependencies

The messaging system uses existing project dependencies:
- `provider` - State management
- `supabase_flutter` - Database access
- `uuid` - Unique ID generation
- `intl` - Date/time formatting

No additional packages needed!

## Notes

- Conversations are created on-demand when user sends first message
- Admin replies automatically set `has_unread_messages: true`
- All timestamps are stored in UTC
- Messages are immutable (no edit/delete in current version)
- Cascade delete removes all messages when conversation is deleted

## Support

For issues or questions about the messaging system:
1. Check database tables exist with correct schema
2. Verify MessagingService is in providers list
3. Check user is authenticated before opening chat
4. Ensure Supabase connection is active
5. Check device has internet connection
