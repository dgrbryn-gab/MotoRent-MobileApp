# Email Verification Sync Between Web and Mobile

## Overview
This implementation ensures that when users sign up on the web application and verify their email there, they won't be asked to verify their email again when logging into the mobile app. Email verification is only enforced for mobile signups.

## How It Works

### 1. **Email Verification Status Sync**
When a user logs into the mobile app, the system checks:
- **Supabase Auth Status**: `emailConfirmedAt` field indicates if email was verified in Supabase
- **Database Status**: `email_verified` field in the users table
- **Combined Check**: Uses whichever shows verification is complete

```dart
// In _loadCurrentUser() - auth_service_supabase.dart
final isEmailVerifiedInAuth = user.emailConfirmedAt != null;
final emailVerified = userData['email_verified'] ?? isEmailVerifiedInAuth;
```

### 2. **Signup Source Tracking**
When a user signs up from the mobile app, the `signup_source` is tracked in Supabase Auth metadata:

```dart
// In signUp() - auth_service_supabase.dart
userData: {
  'name': name,
  'username': username,
  'phone': phone,
  'signup_source': 'mobile', // Track mobile signup
}
```

### 3. **Email Verification Decision Method**
`shouldRequireEmailVerificationOnMobile()` determines if a user needs to verify email:

```dart
bool shouldRequireEmailVerificationOnMobile() {
  if (_currentUser == null) return false;
  
  // If already verified, no need to verify again
  if (_currentUser!.emailVerified) return false;
  
  // Only require verification if signed up from mobile
  final signupSource = _supabase.currentUser?.userMetadata?['signup_source'];
  return signupSource == 'mobile';
}
```

### 4. **Flow Scenarios**

#### **Scenario A: Web Signup → Mobile Login**
1. User signs up on web app
2. Receives verification email
3. Clicks verification link and verifies email
4. Logs into mobile app
5. ✅ Email already shows as verified (`emailConfirmedAt` is set in Supabase)
6. ✅ No verification screen shown
7. ✅ Can immediately make bookings

#### **Scenario B: Mobile Signup**
1. User signs up on mobile app
2. Redirected to OTP verification screen
3. Completes OTP verification
4. ✅ Email marked as verified in database
5. ✅ Can make bookings
6. If user logs out and back in, email still shows verified

#### **Scenario C: Web Signup → Mobile Login (Not Verified)**
1. User signs up on web app but doesn't verify email
2. Logs into mobile app
3. ⚠️ Email not verified
4. ✅ Mobile app does NOT force verification (web never required it)
5. ✅ User can still browse but cannot make bookings

## Files Modified

### 1. **lib/services/auth_service_supabase.dart**
- ✅ Added email verification status sync from Supabase Auth
- ✅ Updated `signUp()` to track `signup_source: 'mobile'`
- ✅ Added `shouldRequireEmailVerificationOnMobile()` method
- ✅ Added comments explaining the logic

### 2. **lib/screens/auth/signup_screen.dart**
- ✅ Updated to pass `isMobileSignup: true` to OTP verification screen
- ✅ Comments clarifying this is a mobile signup

### 3. **lib/screens/auth/otp_verification_screen.dart**
- ✅ Added `isMobileSignup` parameter (defaults to true)
- ✅ Updated constructor to accept this parameter

### 4. **lib/screens/profile/profile_screen.dart**
- ✅ Updated email verification card condition
- ✅ Now checks `shouldRequireEmailVerificationOnMobile()` instead of just `!user.isVerified`
- ✅ Only shows verification prompt if user signed up from mobile

### 5. **lib/screens/motorcycle/motorcycle_detail_screen.dart**
- ✅ Updated booking button logic
- ✅ Allows booking if email is verified from any source
- ✅ Only blocks booking and shows "Verify Email" if user signed up from mobile
- ✅ Updated button text logic accordingly

## Benefits

✅ **Better User Experience**: Users who already verified on web won't be bothered
✅ **Flexible Verification**: Still enforces verification for mobile signups only
✅ **Synced Data**: Uses Supabase Auth as source of truth
✅ **Backward Compatible**: Web-signup users can still book without re-verification
✅ **Clear Source Tracking**: Knows exactly where each user signed up from

## Testing Checklist

- [ ] Web signup user logs into mobile: Email shows verified ✓
- [ ] Mobile signup: OTP verification required
- [ ] Mobile signup verified: Can immediately book
- [ ] Profile screen doesn't show verification card for web signups
- [ ] Booking page allows booking if email verified from web
- [ ] Booking page blocks booking if mobile signup not verified
- [ ] Sign out and sign back in: Verification status persists

## Database Schema Notes

The system works with:
- **auth.users** table: `emailConfirmedAt` timestamp (set by Supabase when email verified)
- **public.users** table: `email_verified` boolean flag (set after OTP verification)
- **User metadata**: `signup_source` field (tracks signup origin)

No database schema changes required - works with existing columns.
