# Supabase Storage Bucket Setup for License Upload

## Issue
Getting an error when uploading license images because the `documents` bucket doesn't exist or isn't properly configured.

## Solution: Create Storage Bucket

### Step 1: Create the Bucket

1. Go to your Supabase Dashboard:
   https://supabase.com/dashboard/project/hceylmoutuzldbywawtm/storage/buckets

2. Click **"New bucket"**

3. Enter the following:
   - **Name:** `documents`
   - **Public bucket:** ✅ **Check this box** (Make it public)
   - **File size limit:** 5 MB (or your preference)
   - **Allowed MIME types:** `image/jpeg, image/png, image/jpg`

4. Click **"Create bucket"**

### Step 2: Set Storage Policies (Allow Upload)

After creating the bucket, you need to allow users to upload their own files:

1. Click on the `documents` bucket
2. Go to **"Policies"** tab
3. Click **"New policy"**
4. Select **"For full customization"** → **"INSERT"**
5. Enter:
   - **Policy name:** `Users can upload own documents`
   - **Policy definition:**
   ```sql
   ((bucket_id = 'documents'::text) AND ((auth.uid())::text = (storage.foldername(name))[1]))
   ```
   - **Allowed operation:** INSERT
   - **Target roles:** authenticated

6. Click **"Review"** → **"Save policy"**

### Step 3: Allow Reading Files (Public Access)

1. Still in Policies tab, click **"New policy"** again
2. Select **"For full customization"** → **"SELECT"**
3. Enter:
   - **Policy name:** `Public can view documents`
   - **Policy definition:**
   ```sql
   (bucket_id = 'documents'::text)
   ```
   - **Allowed operation:** SELECT
   - **Target roles:** public, authenticated

4. Click **"Review"** → **"Save policy"**

### Alternative: Quick Setup with SQL

Run this SQL in Supabase SQL Editor:

```sql
-- Create documents bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents' 
  AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- Allow public read access
CREATE POLICY "Public can view documents"
ON storage.objects FOR SELECT
TO public, authenticated
USING (bucket_id = 'documents');
```

---

## Testing

After setup:
1. Hot reload your Flutter app (`r` in terminal)
2. Go to Profile → Driver's License
3. Try uploading an image
4. Should now work! ✅

## Troubleshooting

If still not working, check the Flutter console output for error messages starting with:
- `ERROR: Failed to upload file to Supabase Storage:`
- `DEBUG: Uploading file to Supabase Storage...`

Common errors:
- **"new row violates row-level security policy"** → Storage policies not set up correctly
- **"Bucket not found"** → Bucket doesn't exist
- **"File does not exist"** → Image picker issue (try different image)
