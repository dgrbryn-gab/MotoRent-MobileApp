# Password Reset Setup Guide

## Overview
The password reset feature is now fully functional. When users click "Forgot Password", they receive an email with a reset link that opens the app and allows them to set a new password.

## How It Works

### User Flow:
1. User clicks "Forgot Password?" on login screen
2. User enters their email address
3. Supabase sends password reset email
4. User clicks the reset link in the email
5. App opens to Reset Password screen
6. User enters and confirms new password
7. Password is updated
8. User can log in with new password

### Technical Flow:
- **ForgotPasswordScreen**: Collects email and sends reset request
- **Supabase**: Sends email with magic link
- **Deep Link Handler**: Catches the link and opens the app
- **ResetPasswordScreen**: Allows user to set new password
- **Auth Service**: Updates password in Supabase

## Files Modified/Created

### New Files:
- `lib/screens/auth/reset_password_screen.dart` - Password reset UI

### Modified Files:
- `lib/screens/splash_screen.dart` - Added auth state listener for password recovery
- `lib/services/auth_service_supabase.dart` - Added `updatePassword()` method
- `lib/services/supabase_service.dart` - Added redirect URL to reset password email

## Supabase Dashboard Configuration

### Step 1: Configure Redirect URLs
1. Go to: https://supabase.com/dashboard/project/hceylmoutuzldbywawtm/auth/url-configuration
2. Under "Redirect URLs", add:
   ```
   io.supabase.motorentdumaguete://reset-password
   ```
3. Click "Save"

### Step 2: Configure Email Template (Optional)
1. Go to: https://supabase.com/dashboard/project/hceylmoutuzldbywawtm/auth/templates
2. Click on "Reset Password" template
3. The default template should work, but you can customize it
4. Make sure the link includes: `{{ .ConfirmationURL }}`

## Android Configuration (AndroidManifest.xml)

Add the following inside the `<activity>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.motorentdumaguete"
        android:host="reset-password" />
</intent-filter>
```

## Testing the Feature

### Test Steps:
1. **Restart the app** (hot reload won't work for deep link changes)
2. Go to Login screen
3. Click "Forgot Password?"
4. Enter your email (must be registered): `dgrbryn@gmail.com`
5. Click "Send Reset Link"
6. Check your email inbox
7. Click the reset password link
8. App should open to Reset Password screen
9. Enter new password (at least 6 characters)
10. Confirm password
11. Click "Reset Password"
12. Success dialog appears
13. Click "Go to Login"
14. Log in with new password

### Troubleshooting:

**Email not received:**
- Check spam folder
- Verify email is registered in the app
- Check Supabase email logs: https://supabase.com/dashboard/project/hceylmoutuzldbywawtm/logs/explorer

**Link opens browser instead of app:**
- Make sure you added the intent-filter to AndroidManifest.xml
- Restart the app completely (not hot reload)
- Uninstall and reinstall the app

**Link doesn't work:**
- Verify redirect URL is added in Supabase Dashboard
- Check that the URL scheme matches: `io.supabase.motorentdumaguete://reset-password`
- Make sure Supabase project is not paused

**Password reset fails:**
- Check internet connection
- Verify new password is at least 6 characters
- Check Supabase logs for errors

## Features

### Security:
- ✅ Reset link expires after use
- ✅ Reset link expires after 24 hours (Supabase default)
- ✅ Password must be at least 6 characters
- ✅ Password confirmation validation
- ✅ Secure token-based authentication

### UI/UX:
- ✅ Clean, modern interface
- ✅ Password visibility toggle
- ✅ Password requirements display
- ✅ Success confirmation dialog
- ✅ Error handling with clear messages
- ✅ Loading states
- ✅ Scrollable form (no overflow errors)

## Future Enhancements (Optional)

- Add password strength meter
- Add "Resend email" timer (prevent spam)
- Add password history check (don't allow reusing old passwords)
- Add 2FA support
- Add email templates customization
- Add SMS password reset option
