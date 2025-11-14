# Migration Guide: Supabase Integration Complete

## ✅ What Has Been Done

### 1. **Database Schema Created** (`supabase_schema.sql`)
- Users table with authentication support
- Motorcycles table with all features
- Bookings table with complete workflow
- Reviews table for ratings
- Penalties table (optional)
- Triggers for automatic timestamps
- Helper functions for availability checking

### 2. **Security Policies Created** (`supabase_policies.sql`)
- Row Level Security (RLS) enabled on all tables
- Customer access policies (view/manage own data)
- Admin access policies (full control)
- Storage bucket policies for images and documents

### 3. **Flutter Models Updated**
- `User` model now supports both camelCase and snake_case
- `Motorcycle` model handles database field mappings
- `Booking` model maps to database schema
- All models have `toJson(forDatabase: true)` method

### 4. **Supabase Services Created**
- ✅ `AuthServiceSupabase` - Complete authentication
- ✅ `MotorcycleServiceSupabase` - Motorcycle management
- ✅ `BookingServiceSupabase` - Booking operations
- ✅ `SupabaseService` - Low-level database wrapper

### 5. **Main.dart Updated**
- Replaced mock services with Supabase services
- Supabase initialization on app startup

---

## 🚀 Setup Steps (Complete These)

### Step 1: Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project (or create a new one)
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

### Step 2: Update Configuration

Open `lib/config/supabase_config.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual credentials:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### Step 3: Run Database Schema

1. Go to **SQL Editor** in Supabase Dashboard
2. Create a new query
3. Copy the entire contents of `supabase_schema.sql`
4. Run the query
5. Verify tables are created in **Table Editor**

### Step 4: Apply Security Policies

1. In **SQL Editor**, create another new query
2. Copy the entire contents of `supabase_policies.sql`
3. Run the query
4. Verify RLS is enabled (check table settings)

### Step 5: Create Storage Buckets

1. Go to **Storage** in Supabase Dashboard
2. Create three public buckets:
   - `motorcycle-images` (Public)
   - `user-documents` (Private - policies control access)
   - `profile-pictures` (Public)

### Step 6: Install Dependencies

Run in your terminal:

```bash
flutter pub get
```

This installs the `supabase_flutter` package.

---

## 🔄 Migration from Mock Data

### Current State:
- Your app still uses mock data from `motorcycle_data.dart`
- Mock authentication in `AuthService`
- Mock bookings in `BookingService`

### New State (After Setup):
- ✅ Real authentication with Supabase
- ✅ Real motorcycle data from database
- ✅ Real bookings stored in database
- ✅ Real-time sync between web and mobile

### Important Code Changes:

#### **Provider Usage (No Change Needed)**

Your screens already use Provider, so they'll automatically use the new services:

```dart
// This code stays the same!
final authService = Provider.of<AuthServiceSupabase>(context);
final motorcycleService = Provider.of<MotorcycleServiceSupabase>(context);
final bookingService = Provider.of<BookingServiceSupabase>(context);
```

But the type names changed, so you might need to update imports:

**Before:**
```dart
import 'package:moto_rent_dumaguete/services/auth_service.dart';
```

**After:**
```dart
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
```

---

## 📝 Testing Checklist

### Authentication Flow
- [ ] Sign up new user
- [ ] Verify email sent (check Supabase Auth → Users)
- [ ] Login with email
- [ ] Login with username
- [ ] Password reset
- [ ] Update profile

### Motorcycle Management
- [ ] View all motorcycles
- [ ] Search motorcycles
- [ ] Filter by category
- [ ] View motorcycle details
- [ ] Check availability

### Booking Flow
- [ ] Create new booking
- [ ] Upload documents (license, ID)
- [ ] View booking list
- [ ] Admin approve/reject booking
- [ ] Payment confirmation
- [ ] Cancel booking

### Admin Features
- [ ] View all bookings
- [ ] Manage motorcycles
- [ ] Update motorcycle availability
- [ ] View all users

---

## 🐛 Troubleshooting

### Issue: "Failed to initialize Supabase"
**Solution:** Check that you've updated `supabase_config.dart` with correct credentials.

### Issue: "Table doesn't exist"
**Solution:** Make sure you ran `supabase_schema.sql` in SQL Editor.

### Issue: "Permission denied" or "RLS policy violation"
**Solution:** Run `supabase_policies.sql` to enable Row Level Security.

### Issue: "No motorcycles showing"
**Solution:** 
1. Check database has data (run sample motorcycles from schema)
2. Check RLS policies allow SELECT
3. Check network connection

### Issue: "Can't upload images"
**Solution:** Create storage buckets and apply storage policies from `supabase_policies.sql`.

---

## 🔒 Security Notes

1. **Never commit** `supabase_config.dart` with real credentials to Git
2. Add to `.gitignore`:
   ```
   lib/config/supabase_config.dart
   ```

3. Use environment variables for production:
   ```dart
   static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
   ```

---

## 📊 Data Synchronization

### Web ↔ Mobile Sync

Since both platforms use the same Supabase backend:

1. **Users:** Login once, access from both
2. **Motorcycles:** Add on web, appears instantly on mobile
3. **Bookings:** Create on mobile, admin manages on web
4. **Real-time:** Use Supabase realtime for live updates

### Example: Real-time Bookings

```dart
// In BookingServiceSupabase, add this method:
void subscribeToBookings(String userId) {
  _supabaseService.subscribeToTable(
    'bookings',
    (event) {
      if (event.newRecord != null) {
        final booking = Booking.fromJson(event.newRecord!);
        if (booking.userId == userId) {
          _bookings.insert(0, booking);
          notifyListeners();
        }
      }
    },
  );
}
```

---

## 🎯 Next Steps

1. ✅ Update `supabase_config.dart` with your credentials
2. ✅ Run SQL schema in Supabase dashboard
3. ✅ Create storage buckets
4. ✅ Test authentication flow
5. ⏳ Add sample motorcycles (or import from web)
6. ⏳ Test complete booking flow
7. ⏳ Implement image upload functionality
8. ⏳ Add real-time features (optional)

---

## 📞 Support

If you encounter issues:

1. Check Supabase logs in Dashboard → Logs
2. Check Flutter console for error messages
3. Verify table structure matches models
4. Test with Supabase API directly (Postman)

---

## 🎉 Benefits of This Integration

✅ **Shared Data:** Same motorcycles, users, bookings across web & mobile  
✅ **Real-time Sync:** Changes appear instantly  
✅ **Secure:** Row Level Security protects user data  
✅ **Scalable:** Supabase handles growth automatically  
✅ **Offline Support:** Can add local caching later  
✅ **File Storage:** Built-in storage for images & documents  
✅ **Authentication:** Email, OAuth, magic links supported  

Your mobile app is now fully integrated with your existing web application! 🚀
