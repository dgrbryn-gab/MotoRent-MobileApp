-- Add license fields to users table
-- Run this in Supabase SQL Editor

-- Add license_number column
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS license_number TEXT;

-- Add license_image_url column
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS license_image_url TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.users.license_number IS 'Driver''s license number';
COMMENT ON COLUMN public.users.license_image_url IS 'URL to uploaded license image in Supabase Storage';
