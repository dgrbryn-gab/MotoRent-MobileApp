# Password Reset - Quick Setup Checklist

## ✅ Completed (Already Done)
- [x] Created ResetPasswordScreen UI
- [x] Added updatePassword() method to auth service
- [x] Updated splash screen to handle password recovery
- [x] Configured redirect URL in reset password request
- [x] Added deep link configuration to AndroidManifest.xml

## 🔧 Required Steps (You Need to Do)

### 1. Configure Supabase Dashboard (5 minutes)
Go to your Supabase project and add the redirect URL:

**URL:** https://supabase.com/dashboard/project/hceylmoutuzldbywawtm/auth/url-configuration

**Add this redirect URL:**
```
io.supabase.motorentdumaguete://reset-password
```

**Steps:**
1. Click the link above
2. Scroll to "Redirect URLs" section
3. Add the URL: `io.supabase.motorentdumaguete://reset-password`
4. Click "Save"

### 2. Restart the App
**Important:** Hot reload won't work for deep link changes!

```powershell
# Stop the app
# Then run:
flutter run
```

Or simply:
- Close the app on your device
- Rebuild and run from VS Code/Android Studio

## 🧪 Test the Feature

1. Open the app
2. Click "Login / Sign Up"
3. Click "Forgot Password?"
4. Enter email: `dgrbryn@gmail.com`
5. Click "Send Reset Link"
6. Check your email (check spam if not in inbox)
7. Click the reset link in the email
8. App should open to Reset Password screen
9. Enter new password (minimum 6 characters)
10. Confirm password
11. Click "Reset Password"
12. Success! Now you can log in with the new password

## 🎯 Expected Behavior

✅ **Email arrives** - Within 1-2 minutes
✅ **Link opens app** - Not browser
✅ **Shows Reset Password screen** - Clean UI with password fields
✅ **Password updates** - Successfully saved in Supabase
✅ **Can login** - With new password immediately

## 🐛 Troubleshooting

**Link opens browser instead of app?**
- Make sure you restarted the app (not just hot reload)
- Try uninstalling and reinstalling the app

**Email not received?**
- Check spam/junk folder
- Verify email is registered in the app
- Wait a few minutes (can take up to 5 minutes)

**"Failed to reset password" error?**
- Check internet connection
- Make sure redirect URL is added in Supabase Dashboard
- Verify password is at least 6 characters

## 📋 Summary

The password reset feature is now **fully functional**! Once you add the redirect URL in Supabase Dashboard and restart the app, users will be able to reset their passwords through email.

**Total setup time:** ~5 minutes
**User experience:** Seamless and professional
**Security:** Industry-standard with Supabase Auth
