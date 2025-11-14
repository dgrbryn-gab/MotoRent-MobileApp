-- Create OTP codes table for email verification
-- Run this SQL in your Supabase SQL Editor

-- Create otp_codes table
CREATE TABLE IF NOT EXISTS public.otp_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_otp_codes_email ON public.otp_codes(email);
CREATE INDEX IF NOT EXISTS idx_otp_codes_user_id ON public.otp_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires_at ON public.otp_codes(expires_at);

-- Add email_verified column to users table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'email_verified'
    ) THEN
        ALTER TABLE public.users ADD COLUMN email_verified BOOLEAN DEFAULT false;
    END IF;
END $$;

-- Temporarily disable Row Level Security for testing
-- This allows the app to insert OTP codes without authentication issues
-- Re-enable with proper policies once OTP flow is working
ALTER TABLE public.otp_codes DISABLE ROW LEVEL SECURITY;

-- Note: To re-enable RLS later, run:
-- ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for otp_codes table (drop existing policies first)
DROP POLICY IF EXISTS "Users can read own OTP codes" ON public.otp_codes;
DROP POLICY IF EXISTS "Service role can insert OTP codes" ON public.otp_codes;
DROP POLICY IF EXISTS "Service role can update OTP codes" ON public.otp_codes;
DROP POLICY IF EXISTS "Users can insert own OTP codes" ON public.otp_codes;

-- Users can read their own OTP codes
CREATE POLICY "Users can read own OTP codes"
ON public.otp_codes
FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own OTP codes during signup
CREATE POLICY "Users can insert own OTP codes"
ON public.otp_codes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own OTP codes (mark as used)
CREATE POLICY "Service role can update OTP codes"
ON public.otp_codes
FOR UPDATE
USING (auth.uid() = user_id);

-- Create function to automatically delete expired OTPs (optional cleanup)
CREATE OR REPLACE FUNCTION delete_expired_otps()
RETURNS void AS $$
BEGIN
    DELETE FROM public.otp_codes
    WHERE expires_at < NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a scheduled job to clean up expired OTPs (run daily)
-- Note: You can set this up in Supabase Dashboard > Database > Cron Jobs
-- SELECT cron.schedule('delete-expired-otps', '0 2 * * *', 'SELECT delete_expired_otps();');

COMMENT ON TABLE public.otp_codes IS 'Stores OTP codes for email verification';
COMMENT ON COLUMN public.otp_codes.otp_code IS '6-digit OTP code sent to user email';
COMMENT ON COLUMN public.otp_codes.is_used IS 'Whether the OTP has been used for verification';
COMMENT ON COLUMN public.otp_codes.expires_at IS 'OTP expiration timestamp (typically 10 minutes from creation)';
