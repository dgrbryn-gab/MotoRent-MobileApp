# OTP Storage Table Fix - Critical Issue

## Problem Summary

The OTP (One-Time Password) signup verification was failing because the code attempted to store OTPs in a Supabase database table called `otp_codes` that **did not exist in the database**. This caused all signup OTP requests to fail silently.

## Root Cause

1. The `OtpService` was updated to use database storage instead of in-memory storage
2. However, the SQL migration to create the `otp_codes` table was never run in the Supabase database
3. The code assumes the table exists but it doesn't
4. Result: OTP storage fails, users cannot complete signup

## What Was Affected

- **Signup Flow**: Failed to store OTP in database after email signup
- **OTP Verification**: Users could not verify their email
- **All new user registrations**: Completely broken

## Solution Implemented

Created the missing `otp_codes` table with proper:
- Schema (UUID, email, otp_code, is_used, expires_at)
- Indexes for performance
- Row Level Security (RLS) policies for unauthenticated access
- Trigger for updated_at timestamp

## Files Modified

### 1. **add_otp_codes_table.sql** (NEW)
Standalone migration file that creates the OTP table with all necessary configuration.

### 2. **COMPLETE_SETUP.sql** (UPDATED)
Added the OTP codes table creation and RLS policies to the main setup script so future deployments include it automatically.

### 3. **supabase_schema.sql** (UPDATED)
Added OTP table definition to the schema documentation.

### 4. **supabase_policies.sql** (UPDATED)
Added OTP RLS policies to the policies file.

## How to Fix Your Database

### Option 1: Use the Standalone Migration (Fastest)

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Create a new query
4. Copy the contents of `add_otp_codes_table.sql`
5. Execute the query
6. Done! The table is now created with all necessary policies

### Option 2: Use COMPLETE_SETUP.sql (Full Reinitialization)

If you want to rebuild your entire database schema from scratch:

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Create a new query
4. Copy the contents of `COMPLETE_SETUP.sql`
5. Execute the entire script
6. Your database is now fully configured

## Testing the Fix

After running the migration:

1. Open the mobile app
2. Go to Sign Up
3. Enter a new email address
4. Click Sign Up
5. Check that the OTP email is received
6. Enter the OTP code
7. Verify that signup completes successfully

## SQL Changes Summary

### Table Created: `otp_codes`

```sql
CREATE TABLE public.otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Indexes Created:
- `idx_otp_codes_email` - For fast email lookups
- `idx_otp_codes_user_id` - For user tracking
- `idx_otp_codes_is_used` - For filtering unused OTPs
- `idx_otp_codes_expires_at` - For expiration queries

### RLS Policies:
- "Allow inserting OTP during signup" - Unauthenticated insert
- "Allow reading OTP by email" - Public read (needed during verification)
- "Allow updating OTP status" - Public update (mark as used)

## Code Verification

The code in `lib/services/otp_service.dart` is correctly implemented to use this table:

✅ `storeOtp()` - Inserts OTP into the table  
✅ `verifyOtp()` - Queries table to verify code  
✅ `getRemainingTime()` - Gets expiration from table  
✅ `resendOtp()` - Updates the database  

## Important Notes

- **This is a critical fix** - Without this table, users cannot sign up
- **No code changes needed** - The app code already expects this table
- **RLS is configured correctly** - Allows unauthenticated access during signup (necessary)
- **Automatic expiration** - OTPs expire after 10 minutes as defined in OtpService
- **One-time use** - OTP is marked as used after verification

## Future Recommendations

1. Add rate limiting on OTP generation to prevent abuse
2. Log IP addresses for security auditing
3. Add metrics for OTP success/failure rates
4. Consider SMS OTP as a fallback
5. Monitor database for old expired OTP records and clean them up

---

**Status**: ✅ Fixed  
**Severity**: 🔴 Critical  
**Testing**: Required  
**Deployment**: Execute SQL migration in Supabase dashboard
