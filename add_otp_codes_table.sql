-- =============================================
-- CREATE OTP_CODES TABLE FOR EMAIL VERIFICATION
-- =============================================
-- This table stores OTP codes for user email verification during signup

-- Drop existing table if it exists (to start fresh)
DROP TABLE IF EXISTS public.otp_codes CASCADE;

-- Create the otp_codes table with minimal schema
CREATE TABLE public.otp_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX idx_otp_codes_email ON public.otp_codes(email);
CREATE INDEX idx_otp_codes_is_used ON public.otp_codes(is_used);
CREATE INDEX idx_otp_codes_expires_at ON public.otp_codes(expires_at);

-- Enable RLS on otp_codes table
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

-- =============================================
-- ROW LEVEL SECURITY POLICIES FOR OTP_CODES
-- =============================================

-- Allow unauthenticated users to insert OTP during signup
CREATE POLICY "Allow inserting OTP during signup"
ON public.otp_codes
FOR INSERT
WITH CHECK (true);

-- Allow unauthenticated users to read OTP records
CREATE POLICY "Allow reading OTP by email"
ON public.otp_codes
FOR SELECT
USING (true);

-- Allow updating OTP records (to mark as used)
CREATE POLICY "Allow updating OTP status"
ON public.otp_codes
FOR UPDATE
USING (true);
