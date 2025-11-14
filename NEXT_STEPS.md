# 🎉 OTP Email Verification - Next Steps

## ✅ Completed
- [x] Edge Function deployed to Supabase
- [x] Flutter auth service updated to call Edge Function
- [x] OTP verification screen created
- [x] Database schema SQL ready

---

## 📋 Remaining Steps

### 1. Set Up Email Service (5 minutes)

**Option A: Resend (Recommended - Free)**

1. Sign up at https://resend.com
2. Verify your email
3. Go to API Keys: https://resend.com/api-keys
4. Click "Create API Key"
5. Name it: `MotoRent OTP`
6. Copy the API key (starts with `re_`)

**Set the secret in Supabase:**
```powershell
supabase secrets set RESEND_API_KEY=re_your_api_key_here --project-ref hceylmoutuzldbywawtm
```

### 2. Update Email "From" Address

Edit `supabase/functions/send-otp-email/index.ts` line 48:

```typescript
// For testing (Resend test domain):
from: 'MotoRent Dumaguete <onboarding@resend.dev>',

// For production (your verified domain):
from: 'MotoRent Dumaguete <noreply@motorent-dumaguete.com>',
```

After changing, redeploy:
```powershell
supabase functions deploy send-otp-email --project-ref hceylmoutuzldbywawtm --no-verify-jwt
```

### 3. Run Database Migration

1. Open Supabase Dashboard: https://supabase.com/dashboard/project/hceylmoutuzldbywawtm/sql
2. Click "New Query"
3. Copy contents of `otp_verification_setup.sql`
4. Paste and click "Run"

**Verify migration:**
- Go to Database → Tables
- Check for `otp_codes` table
- Check `users` table has `email_verified` column

### 4. Test the Full Flow

```powershell
flutter run
```

1. Click "Sign Up" on login screen
2. Fill registration form
3. Submit → should navigate to OTP screen
4. **Check your email** for OTP code (or console if email not set up yet)
5. Enter the 6-digit code
6. Should verify and navigate to main app

---

## 🔍 Troubleshooting

### Email not received?
1. Check spam folder
2. Verify RESEND_API_KEY is set:
   ```powershell
   supabase secrets list --project-ref hceylmoutuzldbywawtm
   ```
3. Check function logs:
   ```powershell
   supabase functions logs send-otp-email --project-ref hceylmoutuzldbywawtm
   ```

### "Invalid OTP" error?
- OTP expires in 10 minutes
- Check if database migration was run
- Verify `otp_codes` table exists

### Function errors?
View logs in real-time:
```powershell
supabase functions logs send-otp-email --project-ref hceylmoutuzldbywawtm --follow
```

---

## 📧 Email Service Alternatives

### SendGrid (if not using Resend)
1. Sign up at https://sendgrid.com
2. Get API key from Settings → API Keys
3. Update Edge Function to use SendGrid API (see SUPABASE_EMAIL_SETUP.md)
4. Set secret:
   ```powershell
   supabase secrets set SENDGRID_API_KEY=SG.your_api_key --project-ref hceylmoutuzldbywawtm
   ```

---

## 🎨 Customization

### Change OTP expiry time
Edit `lib/services/auth_service_supabase.dart` line 266:
```dart
final expiresAt = DateTime.now().add(const Duration(minutes: 10)); // Change here
```

### Change OTP code length
Currently 6 digits. To change, edit `_generateOTP()` method:
```dart
final otp = (now % 1000000).toString().padLeft(6, '0'); // Change 1000000 for different length
```

### Change resend countdown
Edit `lib/screens/auth/otp_verification_screen.dart` line 33:
```dart
int _resendCountdown = 60; // Change to desired seconds
```

---

## ✅ Quick Command Reference

```powershell
# Set email API key
supabase secrets set RESEND_API_KEY=your_key --project-ref hceylmoutuzldbywawtm

# List all secrets
supabase secrets list --project-ref hceylmoutuzldbywawtm

# Deploy function
supabase functions deploy send-otp-email --project-ref hceylmoutuzldbywawtm --no-verify-jwt

# View function logs
supabase functions logs send-otp-email --project-ref hceylmoutuzldbywawtm --follow

# Run Flutter app
flutter run
```

---

## 🚀 Production Checklist

Before going live:

- [ ] Sign up for Resend (or email service)
- [ ] Set RESEND_API_KEY secret
- [ ] Run database migration in production
- [ ] Update "from" email to your domain
- [ ] Test signup → OTP → login flow
- [ ] Test OTP expiration (wait 10+ minutes)
- [ ] Test resend OTP functionality
- [ ] Remove console print statements
- [ ] Set verify_jwt = true in config.toml (optional, for security)
- [ ] Monitor function invocations in Supabase Dashboard

---

**Current Status:**
- ✅ Edge Function: Deployed
- ⏳ Email API Key: Needs to be set
- ⏳ Database Migration: Needs to be run
- ⏳ Testing: Ready after above steps

**Your function URL:**
`https://hceylmoutuzldbywawtm.supabase.co/functions/v1/send-otp-email`
