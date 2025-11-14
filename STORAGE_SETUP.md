-- =============================================
-- VERIFY SUPABASE STORAGE BUCKET SETUP
-- =============================================
-- Make sure you have the 'user-documents' bucket created in Supabase Storage

-- To create the bucket (if it doesn't exist):
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "New Bucket"
-- 3. Name: user-documents
-- 4. Public bucket: YES (or set policies below)

-- =============================================
-- STORAGE POLICIES (If bucket is private)
-- =============================================

-- Policy 1: Allow authenticated users to upload their own documents
CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'user-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Allow users to view their own documents
CREATE POLICY "Users can view own documents"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'user-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Allow admins to view all documents
CREATE POLICY "Admins can view all documents"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'user-documents'
    AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Policy 4: Allow users to delete their own documents
CREATE POLICY "Users can delete own documents"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'user-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =============================================
-- NOTES
-- =============================================
-- 1. Make sure the bucket 'user-documents' exists in your Supabase project
-- 2. If the bucket is PUBLIC, you don't need the policies above
-- 3. If the bucket is PRIVATE, run the policies above
-- 4. Files will be uploaded to: user-documents/{userId}/license_{timestamp}.jpg
-- 5. The public URL will be stored in the reservations.license_image_url column
