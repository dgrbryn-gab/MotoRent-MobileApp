-- =============================================
-- CONTACT MESSAGES TABLE USAGE GUIDE
-- =============================================
-- 
-- The mobile app now uses your existing contact_messages table
-- for user-admin messaging. No new tables need to be created!
--
-- Required columns in contact_messages table:
-- - id (UUID) - Primary key
-- - name (TEXT) - User's name
-- - email (TEXT) - User's email
-- - message (TEXT) - User's message
-- - status (TEXT) - 'pending', 'replied', 'resolved'
-- - created_at (TIMESTAMP) - When message was created
-- - updated_at (TIMESTAMP) - Last update time
-- - reply_message (TEXT, optional) - Admin's reply
-- - replied_at (TIMESTAMP, optional) - When admin replied
--
-- If your table is missing any fields, add them using the ALTER TABLE
-- commands below:
--

-- Add reply_message column if it doesn't exist
ALTER TABLE public.contact_messages 
ADD COLUMN IF NOT EXISTS reply_message TEXT;

-- Add replied_at column if it doesn't exist
ALTER TABLE public.contact_messages 
ADD COLUMN IF NOT EXISTS replied_at TIMESTAMP WITH TIME ZONE;

-- Add status column if it doesn't exist (with default value)
ALTER TABLE public.contact_messages 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'replied', 'resolved'));

-- Ensure email is unique per message (optional but recommended)
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_contact_messages_email_latest ON public.contact_messages(email, created_at DESC);

-- =============================================
-- MOBILE APP INTEGRATION
-- =============================================
--
-- The Flutter mobile app now integrates with contact_messages table:
--
-- 1. User sends a message from the Contact Us page
--    → Message is inserted into contact_messages table
--    → Status is set to 'pending'
--
-- 2. Admin replies via web application
--    → reply_message field is updated
--    → replied_at timestamp is set
--    → status is set to 'replied'
--
-- 3. User opens the message in mobile app
--    → Shows user's message and any admin reply
--    → Status badge displays current state
--    → User can send new message to the same email
--
-- =============================================
-- OPTIONAL: ROW LEVEL SECURITY (RLS)
-- =============================================
--
-- If you want to secure the table, enable RLS:
--

-- Enable RLS
ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view messages with their email
-- CREATE POLICY "Users can view own messages"
-- ON public.contact_messages
-- FOR SELECT
-- USING (email = auth.jwt() ->> 'email');

-- Policy: Users can insert their own messages
-- CREATE POLICY "Users can insert own messages"
-- ON public.contact_messages
-- FOR INSERT
-- WITH CHECK (email = auth.jwt() ->> 'email');

-- Policy: Admin can view all messages
-- CREATE POLICY "Admin can view all messages"
-- ON public.contact_messages
-- FOR SELECT
-- USING (auth.jwt() ->> 'role' = 'admin');

-- Policy: Admin can update messages
-- CREATE POLICY "Admin can update messages"
-- ON public.contact_messages
-- FOR UPDATE
-- USING (auth.jwt() ->> 'role' = 'admin');

-- =============================================
-- NOTES
-- =============================================
--
-- 1. No new tables need to be created - uses existing contact_messages
-- 2. Mobile app stores one message per email (latest one)
-- 3. Admin replies are tracked with reply_message and replied_at
-- 4. Status field tracks conversation state
-- 5. Both web and mobile apps now use the same table
-- 6. Timestamps are in UTC

