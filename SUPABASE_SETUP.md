# Supabase Integration Setup Guide

## Prerequisites
1. A Supabase account (https://supabase.com)
2. An existing Supabase project
3. Flutter SDK installed

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Navigate to **Settings** > **API**
3. Copy the following:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

## Step 2: Update Configuration

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'YOUR_ACTUAL_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_ACTUAL_ANON_KEY';
   ```

## Step 3: Install Dependencies

Run the following command in your project root:
```bash
flutter pub get
```

## Step 4: Set Up Database Tables

Run the SQL scripts in your Supabase SQL Editor:

### 1. Create Users Table
```sql
-- See supabase_schema.sql file
```

### 2. Create Motorcycles Table
```sql
-- See supabase_schema.sql file
```

### 3. Create Bookings Table
```sql
-- See supabase_schema.sql file
```

### 4. Create Reviews Table (Optional)
```sql
-- See supabase_schema.sql file
```

## Step 5: Set Up Storage Buckets

1. Go to **Storage** in your Supabase dashboard
2. Create the following buckets:
   - `motorcycle-images` (Public)
   - `user-documents` (Private)
   - `profile-pictures` (Public)

3. Set bucket policies:
   - For public buckets: Allow public read access
   - For private buckets: Restrict to authenticated users

## Step 6: Set Up Row Level Security (RLS)

Enable RLS on all tables and create appropriate policies. See the `supabase_policies.sql` file for examples.

## Step 7: Configure Email Templates (Optional)

1. Go to **Authentication** > **Email Templates**
2. Customize the email templates for:
   - Confirmation email
   - Password reset
   - Magic link

## Step 8: Test the Connection

1. Run your Flutter app:
   ```bash
   flutter run
   ```

2. Check the console for:
   ```
   ✅ Supabase initialized successfully
   ```

3. Try signing up a new user to test the integration

## Troubleshooting

### Error: "Invalid API key"
- Double-check that you copied the correct anon key
- Make sure there are no extra spaces in the config file

### Error: "Failed to initialize Supabase"
- Verify your Supabase URL is correct
- Check your internet connection
- Ensure the Supabase project is active

### Tables not found
- Make sure you ran all SQL scripts in the Supabase SQL Editor
- Check that table names in `supabase_config.dart` match your database

### Authentication not working
- Verify email confirmation is disabled (or handle email verification)
- Check RLS policies allow the operations you're trying to perform

## Next Steps

1. **Update Services**: Integrate SupabaseService into existing services:
   - Replace `AuthService` with `AuthServiceSupabase` in `main.dart`
   - Update `MotorcycleService` to use Supabase
   - Update `BookingService` to use Supabase

2. **Handle Realtime**: Use Supabase realtime features for live updates

3. **Implement Storage**: Upload images for motorcycles and user documents

4. **Add Error Handling**: Implement proper error handling throughout the app

## Migration from Mock Data

To migrate from the current mock implementation to Supabase:

1. Update `main.dart` to use `AuthServiceSupabase` instead of `AuthService`
2. Create Supabase versions of `MotorcycleService` and `BookingService`
3. Seed your database with initial motorcycle data
4. Test all features thoroughly

## Security Best Practices

1. **Never commit secrets**: Keep your `supabase_config.dart` out of version control if it contains real credentials
2. **Use environment variables**: For production, use environment variables or a secrets management system
3. **Enable RLS**: Always enable Row Level Security on your tables
4. **Validate on server**: Don't rely solely on client-side validation
5. **Monitor usage**: Keep an eye on your Supabase dashboard for unusual activity

## Support

For Supabase-specific issues:
- Documentation: https://supabase.com/docs
- Discord: https://discord.supabase.com
- GitHub: https://github.com/supabase/supabase

For Flutter integration:
- supabase_flutter docs: https://supabase.com/docs/reference/dart/introduction
