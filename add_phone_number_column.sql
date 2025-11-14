-- Add phone_number column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- Add comment
COMMENT ON COLUMN public.users.phone_number IS 'User phone number';

-- If there's existing data in a 'phone' column, migrate it
UPDATE public.users 
SET phone_number = phone 
WHERE phone IS NOT NULL AND phone_number IS NULL;
