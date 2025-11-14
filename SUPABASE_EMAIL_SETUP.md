# Supabase Edge Function Email Setup Guide

Complete guide to setting up email sending for OTP verification using Supabase Edge Functions.

---

## 📋 Prerequisites

1. Supabase project created
2. Supabase CLI installed
3. Email service account (Resend recommended)

---

## 🚀 Step-by-Step Setup

### Step 1: Install Supabase CLI

```powershell
# Using npm
npm install -g supabase

# Or using Scoop (Windows)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

Verify installation:
```powershell
supabase --version
```

### Step 2: Login to Supabase

```powershell
supabase login
```

This will open a browser window to authenticate. Follow the prompts and paste the access token back into your terminal.

### Step 3: Link Your Project

```powershell
# Navigate to your Flutter project directory
cd "c:\Users\ACER\Desktop\Flutter"

# Link to your Supabase project
supabase link --project-ref your-project-ref
```

To get your project ref:
- Go to Supabase Dashboard
- Click on your project
- Go to Settings > General
- Copy the "Reference ID"

### Step 4: Choose Email Service

#### Option A: Resend (Recommended - Easy Setup)

**Why Resend?**
- ✅ Simple API
- ✅ 100 emails/day free tier
- ✅ 3,000 emails/month on free plan
- ✅ Great deliverability
- ✅ No credit card required for free tier

**Sign up:**
1. Go to https://resend.com
2. Sign up for free account
3. Verify your email
4. Add your domain (or use their test domain for development)

**Get API Key:**
1. Go to https://resend.com/api-keys
2. Click "Create API Key"
3. Name it: "MotoRent OTP"
4. Copy the API key (starts with `re_`)

#### Option B: SendGrid

1. Sign up at https://sendgrid.com
2. Get API key from Settings > API Keys
3. Update the Edge Function to use SendGrid API

```typescript
// Replace Resend code with SendGrid:
const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${SENDGRID_API_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    personalizations: [{
      to: [{ email }]
    }],
    from: { email: 'noreply@yourdomain.com' },
    subject: 'Verify Your Email - MotoRent Dumaguete',
    content: [{
      type: 'text/html',
      value: htmlContent
    }]
  })
})
```

#### Option C: Mailgun

1. Sign up at https://mailgun.com
2. Get API key from Settings > API Security
3. Update Edge Function for Mailgun API

### Step 5: Set Environment Variables

Set your email API key as a secret:

```powershell
# For Resend
supabase secrets set RESEND_API_KEY=re_your_api_key_here

# For SendGrid
supabase secrets set SENDGRID_API_KEY=SG.your_api_key_here

# For Mailgun
supabase secrets set MAILGUN_API_KEY=your_api_key_here
supabase secrets set MAILGUN_DOMAIN=mg.yourdomain.com
```

Verify secrets:
```powershell
supabase secrets list
```

### Step 6: Update Email "From" Address

Edit `supabase/functions/send-otp-email/index.ts`:

```typescript
// Change this line:
from: 'MotoRent Dumaguete <noreply@yourdomain.com>',

// To your verified domain or Resend test domain:
from: 'MotoRent Dumaguete <onboarding@resend.dev>', // For testing
// OR
from: 'MotoRent Dumaguete <noreply@motorent-dumaguete.com>', // Production
```

### Step 7: Deploy the Edge Function

```powershell
# Deploy the function
supabase functions deploy send-otp-email

# Verify deployment
supabase functions list
```

You should see:
```
┌──────────────────┬────────────┬─────────────────────┐
│ Name             │ Status     │ Version             │
├──────────────────┼────────────┼─────────────────────┤
│ send-otp-email   │ ACTIVE     │ 1                   │
└──────────────────┴────────────┴─────────────────────┘
```

### Step 8: Test the Function

Test using curl:

```powershell
# Get your function URL and anon key from Supabase Dashboard
$FUNCTION_URL = "https://your-project-ref.supabase.co/functions/v1/send-otp-email"
$ANON_KEY = "your-anon-key"

# Test the function
curl -X POST $FUNCTION_URL `
  -H "Authorization: Bearer $ANON_KEY" `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com","otp":"123456"}'
```

Expected response:
```json
{"success":true,"data":{"id":"some-email-id"}}
```

### Step 9: Update Flutter Auth Service

Now update your auth service to call the Edge Function instead of printing to console.

Open `lib/services/auth_service_supabase.dart` and find the `sendOTP` method:

```dart
// Replace this line:
print('OTP Code for $email: $otp');

// With this:
try {
  await _supabase.client.functions.invoke(
    'send-otp-email',
    body: {
      'email': email,
      'otp': otp,
    },
  );
  print('OTP sent to $email successfully');
} catch (e) {
  print('Error sending OTP email: $e');
  throw Exception('Failed to send OTP email');
}
```

### Step 10: Test End-to-End

1. Run your Flutter app:
```powershell
flutter run
```

2. Sign up with a real email address
3. Check your email inbox for the OTP
4. Enter the OTP in the verification screen
5. Verify successful login

---

## 🔍 Troubleshooting

### Function not deploying?

```powershell
# Check function logs
supabase functions logs send-otp-email

# Test locally first
supabase functions serve send-otp-email
```

### Email not received?

1. **Check spam folder** - First place to look
2. **Verify API key** - Make sure secret is set correctly
3. **Check function logs** - Look for errors in Supabase Dashboard
4. **Domain verification** - Some services require domain verification
5. **Rate limits** - Check if you've hit API limits

### View function logs:

```powershell
# Real-time logs
supabase functions logs send-otp-email --follow

# Or in Supabase Dashboard:
# Edge Functions > send-otp-email > Logs
```

### Common errors:

**"RESEND_API_KEY is not defined"**
- Run: `supabase secrets set RESEND_API_KEY=your_key`

**"Email sending failed"**
- Check API key is valid
- Verify "from" email is allowed
- Check Resend dashboard for errors

**"Function not found"**
- Redeploy: `supabase functions deploy send-otp-email`
- Check project is linked: `supabase link --project-ref your-ref`

---

## 📊 Monitoring

### Check email delivery:

**Resend Dashboard:**
- Go to https://resend.com/emails
- View all sent emails, opens, clicks
- Check bounce and complaint rates

**Supabase Dashboard:**
- Functions > send-otp-email > Invocations
- Monitor function calls and errors

### Set up alerts:

1. Go to Supabase Dashboard > Reports
2. Set up alerts for function failures
3. Monitor email delivery rates in Resend

---

## 💰 Pricing (Free Tiers)

### Resend (Recommended)
- ✅ 100 emails/day
- ✅ 3,000 emails/month
- ✅ No credit card required

### SendGrid
- ✅ 100 emails/day
- ❌ Requires credit card

### Mailgun
- ✅ 5,000 emails/month (3 months)
- ❌ Requires credit card

### Supabase Edge Functions
- ✅ 500,000 invocations/month
- ✅ 2GB bandwidth/month

---

## 🎨 Customizing the Email Template

Edit `supabase/functions/send-otp-email/index.ts`:

1. **Change colors:** Modify hex values in the HTML
2. **Add logo:** Include `<img>` tag with your logo URL
3. **Update text:** Change wording, add branding
4. **Add social links:** Include footer with social media icons

Example logo addition:

```html
<!-- Add after header opening -->
<tr>
  <td align="center" style="padding: 20px 0;">
    <img src="https://yourdomain.com/logo.png" 
         alt="MotoRent Logo" 
         width="120" 
         style="display: block;">
  </td>
</tr>
```

---

## 🔐 Security Best Practices

1. **Never expose API keys** - Always use environment variables
2. **Validate JWT** - Set `verify_jwt = true` in production
3. **Rate limiting** - Implement in Edge Function
4. **Email validation** - Verify email format before sending
5. **Monitor usage** - Watch for abuse patterns
6. **HTTPS only** - Supabase enforces this automatically

---

## 🚀 Production Checklist

- [ ] Domain verified with email service
- [ ] Production API keys set
- [ ] "From" email updated to your domain
- [ ] Edge Function deployed to production
- [ ] Secrets set in production project
- [ ] Email template tested with real addresses
- [ ] Monitoring and alerts configured
- [ ] Rate limiting implemented
- [ ] Error handling tested
- [ ] Privacy policy updated (mention email verification)

---

## 📚 Additional Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Resend Documentation](https://resend.com/docs)
- [Resend with Supabase Guide](https://resend.com/docs/send-with-supabase-edge-functions)
- [SendGrid API Docs](https://docs.sendgrid.com/api-reference)

---

## 💡 Next Steps

After email is working:

1. **Add analytics** - Track verification completion rate
2. **A/B test** - Try different email designs
3. **Localization** - Support multiple languages
4. **SMS backup** - Add phone verification option
5. **Branding** - Customize email template with your brand

---

## 🆘 Need Help?

If you encounter issues:

1. Check function logs: `supabase functions logs send-otp-email`
2. Test locally: `supabase functions serve send-otp-email`
3. Review Resend dashboard for delivery issues
4. Check Supabase Discord community
5. Review this guide's troubleshooting section

---

## ✅ Quick Command Reference

```powershell
# Setup
supabase login
supabase link --project-ref your-ref

# Deploy
supabase functions deploy send-otp-email

# Manage secrets
supabase secrets set RESEND_API_KEY=your_key
supabase secrets list

# Monitor
supabase functions logs send-otp-email --follow
supabase functions list

# Test locally
supabase functions serve send-otp-email
```

---

**You're all set! 🎉** Your OTP email verification system is now ready for production use.
