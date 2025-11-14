# Notification System Setup Guide

## ✅ What Has Been Implemented

### 1. Motorcycle Image Display
All motorcycle images from the database are now visible on:
- ✅ **Home Screen** (`motorcycle_card.dart`) - Grid view with image loading/error states
- ✅ **Booking Screen** (`booking_screen.dart`) - Motorcycle card with ClipRRect image
- ✅ **Motorcycle Detail Screen** (`motorcycle_detail_screen.dart`) - Hero image with gradient overlay

### 2. Notification System
Complete notification system for admin-customer communication:
- ✅ **NotificationServiceSupabase** - Full CRUD operations for notifications
- ✅ **Auto-notifications** - When admin approves/rejects/completes reservations
- ✅ **Unread count** - Real-time badge on notification bell
- ✅ **Notifications Screen** - View all notifications with mark as read
- ✅ **Login integration** - Initializes notifications when user logs in

### 3. Booking Progress Tracking
- ✅ **Progress Bar** - LinearProgressIndicator at top of AppBar
- ✅ **4-Step Indicator** - Visual circles showing: Details → Documents → Review → Confirm
- ✅ **Document Upload** - ImagePicker with camera/gallery options

---

## 🗄️ Database Setup Required

You need to create the notifications table in your Supabase database. Run this SQL in your Supabase SQL Editor:

```sql
-- Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'reservation_approved',
        'reservation_rejected',
        'reservation_completed',
        'reservation_cancelled',
        'payment_received',
        'system_notification'
    )),
    is_read BOOLEAN DEFAULT FALSE,
    related_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at);

-- Trigger for updated_at
CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON public.notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications"
ON public.notifications FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins can view all notifications"
ON public.notifications FOR SELECT
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can create any notification"
ON public.notifications FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can delete any notification"
ON public.notifications FOR DELETE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
```

**OR** simply run the updated `COMPLETE_SETUP.sql` file which now includes the notifications table.

---

## 🔔 How Notifications Work

### Automatic Notifications
When an admin updates a reservation status, notifications are automatically created:

1. **Reservation Approved** (status: `confirmed` or `approved`)
   - Title: "Reservation Approved! 🎉"
   - Message: "Your reservation has been approved. Enjoy your ride!"
   - Type: `reservation_approved`

2. **Reservation Rejected** (status: `rejected` or `cancelled`)
   - Title: "Reservation Rejected"
   - Message: Admin notes or "Unfortunately, your reservation has been rejected."
   - Type: `reservation_rejected`

3. **Reservation Completed** (status: `completed`)
   - Title: "Reservation Completed"
   - Message: "Thank you for choosing us! Please share your experience."
   - Type: `reservation_completed`

### User Experience
1. **Login** - Notification service initializes with user ID
2. **Notification Bell** - Shows red badge with unread count
3. **Click Bell** - Opens Notifications Screen
4. **View Notification** - Automatically marks as read
5. **Mark All Read** - Button in top-right of Notifications Screen

---

## 📁 Files Modified/Created

### Created Files:
- `lib/services/notification_service_supabase.dart` (217 lines)
- `lib/screens/notifications/notifications_screen.dart` (281 lines)

### Modified Files:
- `lib/main.dart` - Added NotificationServiceSupabase to providers
- `lib/screens/main_navigation_screen.dart` - Updated notification bell with unread badge
- `lib/screens/auth/login_screen.dart` - Initialize notification service on login
- `lib/services/reservation_service_supabase.dart` - Added notification creation
- `lib/widgets/motorcycle_card.dart` - Display motorcycle images
- `lib/screens/booking/booking_screen.dart` - Images + progress + document upload
- `lib/screens/motorcycle/motorcycle_detail_screen.dart` - Hero image with gradient
- `COMPLETE_SETUP.sql` - Added notifications table schema

---

## 🧪 Testing the Notification System

### Test Flow:
1. **Run the SQL migration** in Supabase SQL Editor
2. **Customer creates reservation** (status: pending)
3. **Admin approves reservation** → Customer receives "Reservation Approved! 🎉" notification
4. **Check notification bell** → Shows red badge with "1"
5. **Open notifications screen** → See the notification
6. **Tap notification** → Marks as read, badge disappears

### Expected Behavior:
- ✅ Notification badge only shows when there are unread notifications
- ✅ Badge shows count (1, 2, 3... or 99+ if more than 99)
- ✅ Notification screen loads all notifications sorted by newest first
- ✅ Tapping a notification marks it as read
- ✅ "Mark all read" button grays out when no unread notifications
- ✅ Pull-to-refresh reloads notifications

---

## 🚀 Next Steps (Optional Enhancements)

1. **Real-time Notifications** - Add Supabase real-time subscription:
   ```dart
   _supabaseService.client
       .from(SupabaseConfig.notificationsTable)
       .stream(primaryKey: ['id'])
       .eq('user_id', userId)
       .listen((data) {
         // Update notifications in real-time
       });
   ```

2. **Push Notifications** - Integrate Firebase Cloud Messaging for notifications when app is closed

3. **Notification Preferences** - Let users choose which notifications to receive

4. **Notification Actions** - Add "View Reservation" button in notification

---

## 📝 Notes

- Notification service is automatically initialized when user logs in
- Notifications are only visible to the user they belong to (RLS enforced)
- Admins can see all notifications through RLS policy
- Notifications are ordered by creation date (newest first)
- The system supports multiple notification types for future expansion

---

## 🐛 Troubleshooting

### Notification bell doesn't show badge
- Check if notifications table exists in database
- Verify user is logged in (notification service initialized)
- Check Supabase RLS policies are enabled

### Notifications not created when admin updates status
- Verify reservation_service_supabase.dart has _createStatusNotification() method
- Check if NotificationServiceSupabase is in main.dart providers
- Ensure database table has correct columns and types

### App crashes on login
- Make sure you ran the SQL migration to create notifications table
- Check that all RLS policies are created
- Verify notification_service_supabase.dart import is correct

---

**All features are now ready! Just run the SQL migration and test the flow.** 🎉
