-- =============================================
-- MOTORCYCLE RENTAL SYSTEM - SUPABASE SCHEMA
-- =============================================
-- This schema is designed to work with your existing web app
-- Make sure table/column names match your current database

-- =============================================
-- 1. USERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT auth.uid(),
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone_number TEXT,
    address TEXT,
    license_number TEXT,
    license_image_url TEXT,
    profile_image_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- =============================================
-- 2. OTP CODES TABLE (for email verification)
-- =============================================
CREATE TABLE IF NOT EXISTS public.otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for OTP lookups
CREATE INDEX IF NOT EXISTS idx_otp_codes_email ON public.otp_codes(email);
CREATE INDEX IF NOT EXISTS idx_otp_codes_is_used ON public.otp_codes(is_used);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires_at ON public.otp_codes(expires_at);

-- =============================================
-- 3. MOTORCYCLES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.motorcycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    category TEXT NOT NULL,
    engine TEXT NOT NULL,
    transmission TEXT NOT NULL,
    fuel_capacity TEXT NOT NULL,
    color TEXT NOT NULL,
    year INTEGER NOT NULL,
    plate_number TEXT UNIQUE NOT NULL,
    price_per_day DECIMAL(10, 2) NOT NULL,
    description TEXT,
    features TEXT[], -- Array of features
    rating DECIMAL(3, 2) DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_motorcycles_brand ON public.motorcycles(brand);
CREATE INDEX IF NOT EXISTS idx_motorcycles_category ON public.motorcycles(category);
CREATE INDEX IF NOT EXISTS idx_motorcycles_available ON public.motorcycles(is_available);
CREATE INDEX IF NOT EXISTS idx_motorcycles_price ON public.motorcycles(price_per_day);

-- =============================================
-- 4. BOOKINGS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    motorcycle_id UUID NOT NULL REFERENCES public.motorcycles(id) ON DELETE CASCADE,
    motorcycle_name TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    pickup_date DATE NOT NULL,
    pickup_time TIME NOT NULL,
    return_date DATE NOT NULL,
    duration INTEGER NOT NULL, -- in days
    total_price DECIMAL(10, 2) NOT NULL,
    security_deposit DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Customer information
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    
    -- License information
    license_number TEXT NOT NULL,
    license_image_url TEXT,
    
    -- Valid ID information
    valid_id_type TEXT,
    valid_id_image_url TEXT,
    
    -- Booking status
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'pending',
        'waiting_approval',
        'confirmed',
        'active',
        'completed',
        'cancelled',
        'rejected'
    )),
    current_step INTEGER DEFAULT 1,
    
    -- Payment information
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN (
        'pending',
        'paid',
        'refunded'
    )),
    payment_method TEXT,
    payment_date TIMESTAMP WITH TIME ZONE,
    
    -- Additional fields
    special_requests TEXT,
    cancellation_reason TEXT,
    admin_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bookings_user ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_motorcycle ON public.bookings(motorcycle_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON public.bookings(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON public.bookings(payment_status);

-- =============================================
-- 4. REVIEWS TABLE (Optional)
-- =============================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    motorcycle_id UUID NOT NULL REFERENCES public.motorcycles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(booking_id) -- One review per booking
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_reviews_motorcycle ON public.reviews(motorcycle_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON public.reviews(rating);

-- =============================================
-- 5. PENALTIES TABLE (Optional)
-- =============================================
CREATE TABLE IF NOT EXISTS public.penalties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    motorcycle_id UUID NOT NULL REFERENCES public.motorcycles(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'waived')),
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_penalties_booking ON public.penalties(booking_id);
CREATE INDEX IF NOT EXISTS idx_penalties_user ON public.penalties(user_id);
CREATE INDEX IF NOT EXISTS idx_penalties_status ON public.penalties(status);

-- =============================================
-- 6. TRIGGERS FOR UPDATED_AT
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to users table
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to motorcycles table
CREATE TRIGGER update_motorcycles_updated_at BEFORE UPDATE ON public.motorcycles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to bookings table
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to reviews table
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 7. SAMPLE DATA (Optional - for testing)
-- =============================================

-- Insert sample motorcycles
INSERT INTO public.motorcycles (name, brand, model, category, engine, transmission, fuel_capacity, color, year, plate_number, price_per_day, description, features, rating, total_reviews)
VALUES 
    ('Yamaha NMAX 155', 'Yamaha', 'NMAX', 'Scooter', '155cc', 'Automatic', '7.1L', 'Black', 2023, 'ABC1234', 800.00, 'Comfortable and fuel-efficient scooter perfect for city riding', ARRAY['ABS', 'Smart Key', 'USB Charger'], 4.5, 120),
    ('Honda Click 160', 'Honda', 'Click', 'Scooter', '160cc', 'Automatic', '5.5L', 'Red', 2023, 'XYZ5678', 700.00, 'Stylish and reliable scooter with great fuel economy', ARRAY['LED Lights', 'Digital Display', 'Under Seat Storage'], 4.3, 85),
    ('Suzuki Raider R150', 'Suzuki', 'Raider', 'Sport', '150cc', 'Manual', '12L', 'Blue', 2022, 'DEF9012', 900.00, 'Sporty underbone with powerful engine', ARRAY['Disc Brakes', 'Digital Speedometer'], 4.2, 45)
ON CONFLICT (plate_number) DO NOTHING;

-- =============================================
-- 8. FUNCTIONS FOR BUSINESS LOGIC
-- =============================================

-- Function to check motorcycle availability
CREATE OR REPLACE FUNCTION check_motorcycle_availability(
    motorcycle_uuid UUID,
    start_datetime TIMESTAMP WITH TIME ZONE,
    end_datetime TIMESTAMP WITH TIME ZONE
)
RETURNS BOOLEAN AS $$
DECLARE
    booking_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO booking_count
    FROM public.bookings
    WHERE motorcycle_id = motorcycle_uuid
        AND status NOT IN ('cancelled', 'rejected')
        AND (
            (start_date BETWEEN start_datetime AND end_datetime)
            OR (end_date BETWEEN start_datetime AND end_datetime)
            OR (start_date <= start_datetime AND end_date >= end_datetime)
        );
    
    RETURN booking_count = 0;
END;
$$ LANGUAGE plpgsql;

-- Function to update motorcycle rating
CREATE OR REPLACE FUNCTION update_motorcycle_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.motorcycles
    SET 
        rating = (SELECT AVG(rating) FROM public.reviews WHERE motorcycle_id = NEW.motorcycle_id),
        total_reviews = (SELECT COUNT(*) FROM public.reviews WHERE motorcycle_id = NEW.motorcycle_id)
    WHERE id = NEW.motorcycle_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update motorcycle rating on review insert/update
CREATE TRIGGER update_motorcycle_rating_trigger
AFTER INSERT OR UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION update_motorcycle_rating();

-- =============================================
-- NOTES:
-- =============================================
-- 1. Make sure to enable Row Level Security (RLS) on all tables
-- 2. Create appropriate policies for your use case
-- 3. Adjust column names if they differ from your web app
-- 4. Add any additional fields specific to your business needs
-- 5. Consider adding indexes for frequently queried columns
