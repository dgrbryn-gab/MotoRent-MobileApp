# Supabase Email Verification Setup Guide

Complete guide to setting up email verification for user authentication using Supabase's native email system.

---

## 📋 Overview

This app uses **Supabase Auth's built-in email verification** system. No external email service (like Resend) is required.

**How it works:**
1. User signs up with email and password
2. Supabase Auth automatically sends a confirmation email
3. User clicks the verification link
4. Email is confirmed and user can log in

---

## ⚙️ Setup Steps

### Step 1: Configure Supabase Auth

Go to your **Supabase Dashboard** → **Authentication** → **Providers** → **Email**

Ensure the following settings:

```
✅ Enable Email Auth: ON
✅ Confirm Email: REQUIRED
✅ Double Confirm Changes: OFF (optional)
```

### Step 2: Set Redirect URLs

Navigate to **Authentication** → **URL Configuration**

Add your app's redirect URLs for email confirmations:

**For Mobile (Android/iOS):**
```
io.supabase.motorentdumaguete://auth/callback
```

**For Web:**
```
http://localhost:3000/auth/callback
https://yourdomain.com/auth/callback
```

### Step 3: Customize Email Template (Optional)

Go to **Authentication** → **Email Templates**

You can customize:
- Email subject
- Email body content
- Sender name and email

Default template is pre-configured and ready to use.

### Step 4: Verify Configuration

Test the email verification flow:

1. Launch the app:
   ```bash
   flutter run
   ```

2. Sign up with a test email address

3. Check your email inbox (or spam folder) for the verification email

4. Click the verification link

5. You should be redirected to the app and logged in

---

## 🧪 Testing Email Verification

### With Real Email:
1. Use your actual email or a test email service
2. Follow the standard sign-up flow
3. Check inbox for verification email

### With Test Emails:
Use email variations to test multiple accounts:
- `test+1@gmail.com`
- `test+2@gmail.com`
- `test+3@gmail.com`

All variations go to the same inbox but create separate auth accounts.

---

## 📧 How It Works

### Sign Up Flow:
1. User enters email, password, name, phone, username
2. Account created in `auth.users` table
3. User profile created in `public.users` table with `email_verified = false`
4. Supabase Auth sends confirmation email automatically

### Email Verification:
1. User receives email with subject: "Confirm your email"
2. Email contains a verification link
3. Clicking link marks email as confirmed in `auth.users`
4. `email_confirmed_at` timestamp is set
5. User can now fully use the app

### Login:
1. User logs in with email/username and password
2. App checks if account is created
3. User gains full access

---

## 🔐 Security Features

- ✅ **Email confirmation required**: Prevents fake/spam emails
- ✅ **Time-limited links**: Default 24-hour expiration
- ✅ **One-click verification**: User-friendly experience
- ✅ **Built-in Supabase security**: Industry-standard encryption
- ✅ **HTTPS only**: All communications encrypted

---

## 🛠️ Troubleshooting

### Email Not Received

**Check:**
1. Spam/Junk folder
2. Email configuration in Supabase Dashboard
3. Redirect URL is correctly set
4. Email template is enabled

**Solution:**
- Wait a few minutes (can take up to 5 minutes)
- Try signing up with different email
- Check Supabase function logs for errors

### Verification Link Expired

**Issue:** User receives email but link is expired

**Solution:**
- Default expiration is 24 hours
- User must click link within this time
- Can request new verification email in app

### Redirect Loop

**Issue:** User gets stuck in redirect loop after clicking verification link

**Check:**
1. Verify redirect URL matches exactly in Supabase Dashboard
2. App is properly configured to handle auth callbacks
3. Deep linking is set up correctly (for mobile)

### Can't Log In After Verification

**Issue:** Email verified but can't log in

**Check:**
1. User account exists in `public.users` table
2. Email matches in both `auth.users` and `public.users`
3. Password is entered correctly
4. No database constraints preventing login

---

## 📊 Email Verification Status

**Check verification status:**

```dart
// In auth_service_supabase.dart
bool get isEmailVerified => _currentUser?.emailVerified ?? false;

// Check in your app
if (authService.isEmailVerified) {
  // User email is verified
} else {
  // User needs to verify email
}
```

---

## 🚀 Production Checklist

Before deploying to production:

- [ ] Supabase Auth is enabled
- [ ] Email confirmation is required
- [ ] Redirect URLs are configured
- [ ] Email template is customized (optional)
- [ ] Test email verification flow works
- [ ] Users in different regions receive emails
- [ ] Links don't expire too quickly (24 hours is standard)
- [ ] Error messages are user-friendly
- [ ] Support email is configured for bounces

---

## 🔗 Useful Links

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Verification](https://supabase.com/docs/guides/auth/managing-user-sessions#email-verification)
- [Email Templates](https://supabase.com/docs/guides/auth/emails)
- [URL Configuration](https://supabase.com/docs/guides/auth/redirect-urls)

---

## ❓ FAQ

### Q: Can I customize the verification email?
**A:** Yes! Go to **Auth → Email Templates → Confirm signup** and edit the HTML.

### Q: How long is the verification link valid?
**A:** Default is 24 hours. You can adjust in **Auth → Email → Email Change**.

### Q: Can I resend the verification email?
**A:** Yes, implement a "Resend Email" button that calls:
```dart
await authService.client.auth.resendPasswordResetEmail(email);
```

### Q: What if the user never verifies their email?
**A:** You can:
- Prevent login until verified
- Show a reminder to verify
- Auto-delete unverified accounts after X days

### Q: Does it work with custom domains?
**A:** Yes! Use your own domain email in the template instead of Supabase's default.

### Q: How do I monitor email delivery?
**A:** 
1. Check Supabase Auth logs
2. Monitor email bounce rates
3. Set up alerts for delivery failures

---

**Status:** ✅ Supabase Email Verification
**Date:** December 1, 2025
**External Services:** None required
**Cost:** Free (included with Supabase)
