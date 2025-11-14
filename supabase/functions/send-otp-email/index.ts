// Supabase Edge Function to send OTP emails
// Deploy with: supabase functions deploy send-otp-email

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!

interface OTPRequest {
  email: string
  otp: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    const { email, otp }: OTPRequest = await req.json()

    // Validate input
    if (!email || !otp) {
      return new Response(
        JSON.stringify({ error: 'Email and OTP are required' }),
        { 
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // Send email using Resend API
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'MotoRent Dumaguete <onboarding@resend.dev>',
        to: email,
        subject: 'Verify Your Email - MotoRent Dumaguete',
        html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Verification</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0a0e27;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #0a0e27; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #1a1f3a 0%, #0a0e27 100%); border-radius: 16px; overflow: hidden; box-shadow: 0 8px 32px rgba(0, 198, 255, 0.2);">
          
          <!-- Header -->
          <tr>
            <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #00C6FF 0%, #0072FF 100%);">
              <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">
                🏍️ MotoRent Dumaguete
              </h1>
              <p style="margin: 8px 0 0; color: #e0f7ff; font-size: 14px;">
                Premium Motorcycle Rental Service
              </p>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 40px;">
              <h2 style="margin: 0 0 16px; color: #00C6FF; font-size: 24px; font-weight: 600;">
                Email Verification
              </h2>
              
              <p style="margin: 0 0 24px; color: #b8c5d6; font-size: 16px; line-height: 1.6;">
                Thank you for signing up! Please use the verification code below to complete your registration.
              </p>

              <!-- OTP Code Box -->
              <table width="100%" cellpadding="0" cellspacing="0" style="margin: 32px 0;">
                <tr>
                  <td align="center" style="background: linear-gradient(135deg, #1e2749 0%, #151a33 100%); border: 2px solid #00C6FF; border-radius: 12px; padding: 32px;">
                    <p style="margin: 0 0 12px; color: #8a96a8; font-size: 14px; text-transform: uppercase; letter-spacing: 2px;">
                      Your Verification Code
                    </p>
                    <div style="font-size: 48px; font-weight: 700; color: #00C6FF; letter-spacing: 12px; text-shadow: 0 0 20px rgba(0, 198, 255, 0.5);">
                      ${otp}
                    </div>
                  </td>
                </tr>
              </table>

              <div style="background-color: rgba(0, 198, 255, 0.1); border-left: 4px solid #00C6FF; border-radius: 8px; padding: 16px; margin: 24px 0;">
                <p style="margin: 0; color: #b8c5d6; font-size: 14px;">
                  ⏱️ <strong style="color: #00C6FF;">This code expires in 10 minutes</strong>
                </p>
              </div>

              <p style="margin: 24px 0 0; color: #8a96a8; font-size: 14px; line-height: 1.6;">
                If you didn't request this verification code, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 32px 40px; background-color: rgba(0, 0, 0, 0.3); border-top: 1px solid rgba(255, 255, 255, 0.1);">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <p style="margin: 0 0 8px; color: #8a96a8; font-size: 14px; font-weight: 600;">
                      Need help? Contact us
                    </p>
                    <p style="margin: 0; color: #5a6a7f; font-size: 13px;">
                      📧 support@motorent-dumaguete.com<br>
                      📱 +63 XXX XXX XXXX
                    </p>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding-top: 24px;">
                    <p style="margin: 0; color: #4a5568; font-size: 12px;">
                      © 2025 MotoRent Dumaguete. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
        `
      })
    })

    const data = await response.json()

    if (!response.ok) {
      console.error('Resend API error:', data)
      return new Response(
        JSON.stringify({ error: 'Failed to send email', details: data }),
        { 
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    return new Response(
      JSON.stringify({ success: true, data }),
      { 
        status: 200,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  } catch (error) {
    console.error('Error sending OTP email:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})
