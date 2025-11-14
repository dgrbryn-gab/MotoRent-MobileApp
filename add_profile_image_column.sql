-- Add profile_image_url column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- Add comment
COMMENT ON COLUMN public.users.profile_image_url IS 'URL to user profile picture stored in Supabase Storage';
