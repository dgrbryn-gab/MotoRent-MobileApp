# OTP Email Verification - Setup Guide

## 🎯 Overview

This implementation adds OTP (One-Time Password) email verification to the signup process. Users will receive a 6-digit code via email that they must enter to verify their account.

---

## 📋 Setup Steps

### 1. Database Setup

Run the SQL migration to create the OTP codes table:

```bash
# In Supabase SQL Editor, run:
# See: otp_verification_setup.sql
```

Key changes:
- Created `otp_codes` table to store OTP codes
- Added `email_verified` column to `users` table
- Configured Row Level Security (RLS) policies
- Added cleanup function for expired OTPs

### 2. Email Sending (Choose One Option)

#### Option A: Supabase Edge Function (Recommended for Production)

Create a Supabase Edge Function to send OTP emails:

**File: `supabase/functions/send-otp-email/index.ts`**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') // or use SendGrid, etc.

serve(async (req) => {
  try {
    const { email, otp } = await req.json()

    // Send email using Resend API (or your preferred email service)
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'MotoRent Dumaguete <noreply@motorent-dumaguete.com>',
        to: email,
        subject: 'Verify Your Email - MotoRent Dumaguete',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #00C6FF;">Email Verification</h2>
            <p>Thank you for signing up with MotoRent Dumaguete!</p>
            <p>Your verification code is:</p>
            <div style="background-color: #f4f4f4; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 10px; color: #00C6FF;">
              ${otp}
            </div>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
            <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
            <p style="font-size: 12px; color: #666;">MotoRent Dumaguete - Motorcycle Rental Service</p>
          </div>
        `
      })
    })

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

Deploy the function:
```bash
supabase functions deploy send-otp-email
```

Set environment variables:
```bash
supabase secrets set RESEND_API_KEY=your_api_key_here
```

#### Option B: Third-Party Email Service

Integrate directly with email services like:
- **Resend** (recommended, easy to use): https://resend.com
- **SendGrid**: https://sendgrid.com
- **Mailgun**: https://mailgun.com
- **AWS SES**: https://aws.amazon.com/ses/

#### Option C: Development/Testing Only

For testing, the OTP is printed to console. Check your terminal/logs:
```dart
print('OTP Code for $email: $otp'); // Visible in debug console
```

### 3. Update Auth Service

Uncomment the Edge Function call in `lib/services/auth_service_supabase.dart`:

```dart
// In sendOTP method, replace TODO with:
await _supabase.client.functions.invoke('send-otp-email', body: {
  'email': email,
  'otp': otp,
});
```

### 4. Test the Flow

1. **Sign Up**: Create a new account
2. **Check Email**: Receive 6-digit OTP code
3. **Verify**: Enter code in OTP verification screen
4. **Complete**: Access full app after verification

---

## 🎨 Features Implemented

### OTP Verification Screen
- ✅ Clean, modern UI with gradient background
- ✅ 6 individual digit input fields
- ✅ Auto-focus to next field on entry
- ✅ Backspace moves to previous field
- ✅ Real-time validation
- ✅ Error handling with visual feedback
- ✅ Resend OTP functionality with 60s countdown
- ✅ OTP expiration (10 minutes)

### Auth Service Updates
- ✅ `sendOTP()` - Generate and send OTP to email
- ✅ `verifyOTP()` - Validate OTP code
- ✅ `resendOTP()` - Send new OTP code
- ✅ OTP generation (6-digit random code)
- ✅ Expiration handling
- ✅ One-time use validation

### Security Features
- ✅ OTP expires after 10 minutes
- ✅ OTP can only be used once
- ✅ Previous OTPs invalidated on resend
- ✅ Row Level Security policies
- ✅ Rate limiting via countdown timer

---

## 🔐 Security Best Practices

1. **Never store OTP in plaintext** (consider hashing in production)
2. **Limit OTP attempts** (add rate limiting)
3. **Use HTTPS only** for all API calls
4. **Set short expiration times** (10 minutes is good)
5. **Invalidate old OTPs** when new ones are generated
6. **Log failed attempts** for security monitoring
7. **Add CAPTCHA** for repeated failed attempts

---

## 🧪 Testing Checklist

- [ ] User receives OTP email on signup
- [ ] OTP code is 6 digits
- [ ] Correct OTP allows verification
- [ ] Incorrect OTP shows error
- [ ] Expired OTP shows error message
- [ ] Resend OTP works after 60s
- [ ] Previous OTP invalidated on resend
- [ ] User cannot verify with used OTP
- [ ] Email field shows correct email
- [ ] Navigation works after verification
- [ ] User marked as verified in database

---

## 📝 Database Schema

### `otp_codes` Table
```sql
Column          Type            Description
-----------     -----------     ---------------------------
id              UUID            Primary key
user_id         UUID            Foreign key to auth.users
email           TEXT            User's email address
otp_code        TEXT            6-digit OTP code
is_used         BOOLEAN         Whether OTP was used
expires_at      TIMESTAMPTZ     Expiration timestamp
created_at      TIMESTAMPTZ     Creation timestamp
updated_at      TIMESTAMPTZ     Last update timestamp
```

### `users` Table (Updated)
```sql
New Column          Type            Description
--------------      -----------     ---------------------------
email_verified      BOOLEAN         Email verification status
```

---

## 🎯 Future Enhancements

1. **SMS OTP**: Add phone number verification
2. **2FA**: Optional two-factor authentication
3. **Rate Limiting**: Prevent OTP spam
4. **Custom Email Templates**: Branded HTML emails
5. **Analytics**: Track verification completion rate
6. **A/B Testing**: Test different OTP lengths
7. **Localization**: Multi-language support for emails

---

## 🐛 Troubleshooting

### OTP email not received
- Check spam/junk folder
- Verify email service is configured
- Check Supabase function logs
- Ensure SMTP settings are correct

### "Invalid OTP" error
- OTP may have expired (10 min)
- Check if OTP was already used
- Verify OTP code is correct (case-sensitive)

### Can't resend OTP
- Wait for 60-second countdown
- Check network connection
- Verify user exists in database

### Edge Function errors
- Check function logs in Supabase dashboard
- Verify environment variables are set
- Test function independently

---

## 📞 Support

For issues or questions:
- Check Supabase logs: Dashboard > Edge Functions > Logs
- Review database queries: Dashboard > SQL Editor
- Email: dev@motorent-dumaguete.com

---

## ✅ Deployment Checklist

Before going to production:

- [ ] Run `otp_verification_setup.sql` in production DB
- [ ] Deploy `send-otp-email` Edge Function
- [ ] Set email service API keys
- [ ] Test full signup → OTP → login flow
- [ ] Remove debug `print()` statements
- [ ] Configure email templates
- [ ] Set up monitoring/alerts
- [ ] Add rate limiting
- [ ] Test on multiple devices
- [ ] Update privacy policy (mention email verification)

---

## 📄 Files Modified/Created

**Created:**
- `lib/screens/auth/otp_verification_screen.dart` - OTP verification UI
- `otp_verification_setup.sql` - Database migration
- `OTP_VERIFICATION_GUIDE.md` - This guide

**Modified:**
- `lib/services/auth_service_supabase.dart` - Added OTP methods
- `lib/screens/auth/signup_screen.dart` - Navigate to OTP screen
