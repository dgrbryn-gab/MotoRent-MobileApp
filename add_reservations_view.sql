-- =============================================
-- CREATE RESERVATIONS VIEW
-- =============================================
-- This creates a view called 'reservations' that mirrors the 'bookings' table
-- Run this in your Supabase SQL Editor

-- Create a view that acts as an alias for the bookings table
CREATE OR REPLACE VIEW public.reservations AS
SELECT * FROM public.bookings;

-- Enable RLS on the view (inherits from bookings table)
ALTER VIEW public.reservations SET (security_invoker = on);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reservations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reservations TO service_role;

-- =============================================
-- ALTERNATIVE: CREATE reservations TABLE
-- =============================================
-- If you prefer a separate table instead of a view, uncomment below:

/*
-- Drop the view first if it exists
DROP VIEW IF EXISTS public.reservations;

-- Create the reservations table (same structure as bookings)
CREATE TABLE IF NOT EXISTS public.reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    motorcycle_id UUID NOT NULL REFERENCES public.motorcycles(id) ON DELETE CASCADE,
    motorcycle_name TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    pickup_time TEXT,
    return_time TEXT,
    total_price DECIMAL(10, 2) NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    payment_method TEXT,
    gcash_reference_number TEXT,
    gcash_proof_url TEXT,
    payment_status TEXT DEFAULT 'unpaid',
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'pending',
        'waiting_approval',
        'confirmed',
        'active',
        'completed',
        'cancelled',
        'rejected'
    )),
    admin_notes TEXT,
    license_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_reservations_user ON public.reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_motorcycle ON public.reservations(motorcycle_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON public.reservations(status);
CREATE INDEX IF NOT EXISTS idx_reservations_dates ON public.reservations(start_date, end_date);

-- Enable RLS
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

-- Create policies (same as bookings)
CREATE POLICY "Users can view own reservations"
ON public.reservations FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create own reservations"
ON public.reservations FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own pending reservations"
ON public.reservations FOR UPDATE
USING (auth.uid() = user_id AND status IN ('pending', 'waiting_approval'));

CREATE POLICY "Admins can view all reservations"
ON public.reservations FOR SELECT
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can update any reservation"
ON public.reservations FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can delete reservations"
ON public.reservations FOR DELETE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Create trigger for updated_at
CREATE TRIGGER update_reservations_updated_at BEFORE UPDATE ON public.reservations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
*/
