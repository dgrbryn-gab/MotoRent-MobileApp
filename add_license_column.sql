-- =============================================
-- ADD LICENSE_IMAGE_URL COLUMN TO RESERVATIONS
-- =============================================
-- Run this in your Supabase SQL Editor

-- Add the license_image_url column if it doesn't exist
ALTER TABLE public.reservations 
ADD COLUMN IF NOT EXISTS license_image_url TEXT;

-- Optional: Add an index for faster queries
CREATE INDEX IF NOT EXISTS idx_reservations_license ON public.reservations(license_image_url);
