-- =============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================
-- These policies control who can access what data
-- Make sure to enable RLS first: ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 1. ENABLE RLS ON ALL TABLES
-- =============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motorcycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.penalties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 2. OTP CODES TABLE POLICIES
-- =============================================

-- Allow unauthenticated users to insert OTP during signup
CREATE POLICY "Allow inserting OTP during signup"
ON public.otp_codes
FOR INSERT
WITH CHECK (true);

-- Allow reading OTP records (needed during verification)
CREATE POLICY "Allow reading OTP by email"
ON public.otp_codes
FOR SELECT
USING (true);

-- Allow updating OTP records (to mark as used after verification)
CREATE POLICY "Allow updating OTP status"
ON public.otp_codes
FOR UPDATE
USING (true);

-- =============================================
-- 3. USERS TABLE POLICIES
-- =============================================

-- Allow users to read their own profile
CREATE POLICY "Users can view own profile"
ON public.users
FOR SELECT
USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON public.users
FOR UPDATE
USING (auth.uid() = id);

-- Allow admins to view all users
CREATE POLICY "Admins can view all users"
ON public.users
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Allow admins to update any user
CREATE POLICY "Admins can update any user"
ON public.users
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Allow new users to insert their profile (during signup)
CREATE POLICY "Allow user creation during signup"
ON public.users
FOR INSERT
WITH CHECK (auth.uid() = id);

-- =============================================
-- 3. MOTORCYCLES TABLE POLICIES
-- =============================================

-- Allow everyone (authenticated users) to view all motorcycles
CREATE POLICY "Anyone can view motorcycles"
ON public.motorcycles
FOR SELECT
USING (auth.role() = 'authenticated');

-- Only admins can insert motorcycles
CREATE POLICY "Only admins can insert motorcycles"
ON public.motorcycles
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Only admins can update motorcycles
CREATE POLICY "Only admins can update motorcycles"
ON public.motorcycles
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Only admins can delete motorcycles
CREATE POLICY "Only admins can delete motorcycles"
ON public.motorcycles
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- 4. BOOKINGS TABLE POLICIES
-- =============================================

-- Users can view their own bookings
CREATE POLICY "Users can view own bookings"
ON public.bookings
FOR SELECT
USING (auth.uid() = user_id);

-- Users can create their own bookings
CREATE POLICY "Users can create own bookings"
ON public.bookings
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own pending/waiting_approval bookings
CREATE POLICY "Users can update own pending bookings"
ON public.bookings
FOR UPDATE
USING (
    auth.uid() = user_id 
    AND status IN ('pending', 'waiting_approval')
);

-- Users can cancel their own bookings
CREATE POLICY "Users can cancel own bookings"
ON public.bookings
FOR UPDATE
USING (
    auth.uid() = user_id
    AND status NOT IN ('completed', 'cancelled')
);

-- Admins can view all bookings
CREATE POLICY "Admins can view all bookings"
ON public.bookings
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Admins can update any booking
CREATE POLICY "Admins can update any booking"
ON public.bookings
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Admins can delete any booking
CREATE POLICY "Admins can delete bookings"
ON public.bookings
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- 5. REVIEWS TABLE POLICIES
-- =============================================

-- Anyone can view reviews
CREATE POLICY "Anyone can view reviews"
ON public.reviews
FOR SELECT
USING (auth.role() = 'authenticated');

-- Users can create reviews for their completed bookings
CREATE POLICY "Users can create reviews for own bookings"
ON public.reviews
FOR INSERT
WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
        SELECT 1 FROM public.bookings
        WHERE id = booking_id
            AND user_id = auth.uid()
            AND status = 'completed'
    )
);

-- Users can update their own reviews
CREATE POLICY "Users can update own reviews"
ON public.reviews
FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete their own reviews
CREATE POLICY "Users can delete own reviews"
ON public.reviews
FOR DELETE
USING (auth.uid() = user_id);

-- Admins can delete any review
CREATE POLICY "Admins can delete any review"
ON public.reviews
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- 6. PENALTIES TABLE POLICIES
-- =============================================

-- Users can view their own penalties
CREATE POLICY "Users can view own penalties"
ON public.penalties
FOR SELECT
USING (auth.uid() = user_id);

-- Admins can view all penalties
CREATE POLICY "Admins can view all penalties"
ON public.penalties
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Only admins can create penalties
CREATE POLICY "Only admins can create penalties"
ON public.penalties
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Only admins can update penalties
CREATE POLICY "Only admins can update penalties"
ON public.penalties
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Only admins can delete penalties
CREATE POLICY "Only admins can delete penalties"
ON public.penalties
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- 7. STORAGE BUCKET POLICIES
-- =============================================

-- To create buckets, go to Supabase Dashboard > Storage
-- Then apply these policies:

-- Motorcycle Images Bucket Policies
-- 1. Allow public read access to motorcycle images
CREATE POLICY "Public Access to Motorcycle Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'motorcycle-images');

-- 2. Allow admins to upload motorcycle images
CREATE POLICY "Admins can upload motorcycle images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'motorcycle-images'
    AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- 3. Allow admins to delete motorcycle images
CREATE POLICY "Admins can delete motorcycle images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'motorcycle-images'
    AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- User Documents Bucket Policies (for licenses and IDs)
-- 1. Users can upload their own documents
CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'user-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Users can view their own documents
CREATE POLICY "Users can view own documents"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'user-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Admins can view all documents
CREATE POLICY "Admins can view all documents"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'user-documents'
    AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Profile Pictures Bucket Policies
-- 1. Allow public read access to profile pictures
CREATE POLICY "Public Access to Profile Pictures"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-pictures');

-- 2. Users can upload their own profile picture
CREATE POLICY "Users can upload own profile picture"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Users can update their own profile picture
CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Users can delete their own profile picture
CREATE POLICY "Users can delete own profile picture"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =============================================
-- 8. HELPER FUNCTIONS FOR AUTHORIZATION
-- =============================================

-- Check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user owns a booking
CREATE OR REPLACE FUNCTION public.owns_booking(booking_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.bookings
        WHERE id = booking_uuid AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- NOTES:
-- =============================================
-- 1. Run this script AFTER running supabase_schema.sql
-- 2. Make sure all tables are created before enabling RLS
-- 3. Test each policy thoroughly before deploying to production
-- 4. Storage policies need buckets to be created first in Supabase Dashboard
-- 5. Adjust policies based on your specific security requirements
-- 6. Consider adding more granular policies for specific use cases
-- 7. Always test with both admin and customer accounts
