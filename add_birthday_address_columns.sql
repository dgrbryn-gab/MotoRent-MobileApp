-- Add birthday and address columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS birthday DATE,
ADD COLUMN IF NOT EXISTS address TEXT;

-- Add comments for documentation
COMMENT ON COLUMN public.users.birthday IS 'User date of birth';
COMMENT ON COLUMN public.users.address IS 'User complete address';
