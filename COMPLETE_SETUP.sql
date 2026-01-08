-- =============================================
-- COMPLETE SETUP SCRIPT FOR SUPABASE
-- =============================================
-- Run this entire script in your Supabase SQL Editor
-- https://app.supabase.com/project/hceylmoutuzldbywawtm/sql

-- =============================================
-- STEP 1: CREATE TABLES
-- =============================================

-- Users Table
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

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- Motorcycles Table
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
    features TEXT[],
    rating DECIMAL(3, 2) DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_motorcycles_brand ON public.motorcycles(brand);
CREATE INDEX IF NOT EXISTS idx_motorcycles_category ON public.motorcycles(category);
CREATE INDEX IF NOT EXISTS idx_motorcycles_available ON public.motorcycles(is_available);
CREATE INDEX IF NOT EXISTS idx_motorcycles_price ON public.motorcycles(price_per_day);

-- Bookings Table
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
    duration INTEGER NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    security_deposit DECIMAL(10, 2) DEFAULT 0.00,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    license_number TEXT NOT NULL,
    license_image_url TEXT,
    valid_id_type TEXT,
    valid_id_image_url TEXT,
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
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN (
        'pending',
        'paid',
        'refunded'
    )),
    payment_method TEXT,
    payment_date TIMESTAMP WITH TIME ZONE,
    special_requests TEXT,
    cancellation_reason TEXT,
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_bookings_user ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_motorcycle ON public.bookings(motorcycle_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON public.bookings(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status ON public.bookings(payment_status);

-- Reviews Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    motorcycle_id UUID NOT NULL REFERENCES public.motorcycles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(booking_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_motorcycle ON public.reviews(motorcycle_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON public.reviews(rating);

-- Penalties Table
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

CREATE INDEX IF NOT EXISTS idx_penalties_booking ON public.penalties(booking_id);
CREATE INDEX IF NOT EXISTS idx_penalties_user ON public.penalties(user_id);
CREATE INDEX IF NOT EXISTS idx_penalties_status ON public.penalties(status);

-- Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'reservation_approved',
        'reservation_rejected',
        'reservation_completed',
        'reservation_cancelled',
        'payment_received',
        'system_notification'
    )),
    is_read BOOLEAN DEFAULT FALSE,
    related_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at);

-- OTP Codes Table (for email verification during signup)
CREATE TABLE IF NOT EXISTS public.otp_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_codes_email ON public.otp_codes(email);
CREATE INDEX IF NOT EXISTS idx_otp_codes_is_used ON public.otp_codes(is_used);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires_at ON public.otp_codes(expires_at);

-- =============================================
-- STEP 2: CREATE TRIGGERS
-- =============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_motorcycles_updated_at BEFORE UPDATE ON public.motorcycles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON public.notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- STEP 3: CREATE HELPER FUNCTIONS
-- =============================================

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

CREATE TRIGGER update_motorcycle_rating_trigger
AFTER INSERT OR UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION update_motorcycle_rating();

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.owns_booking(booking_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.bookings
        WHERE id = booking_uuid AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- STEP 4: INSERT SAMPLE DATA
-- =============================================

INSERT INTO public.motorcycles (name, brand, model, category, engine, transmission, fuel_capacity, color, year, plate_number, price_per_day, description, features, rating, total_reviews, image_url)
VALUES 
    ('Yamaha NMAX 155', 'Yamaha', 'NMAX', 'Scooter', '155cc', 'Automatic', '7.1L', 'Black', 2023, 'ABC1234', 800.00, 'Comfortable and fuel-efficient scooter perfect for city riding', ARRAY['ABS', 'Smart Key', 'USB Charger'], 4.5, 120, 'https://placehold.co/400x300/1e3a8a/white?text=Yamaha+NMAX'),
    ('Honda Click 160', 'Honda', 'Click', 'Scooter', '160cc', 'Automatic', '5.5L', 'Red', 2023, 'XYZ5678', 700.00, 'Stylish and reliable scooter with great fuel economy', ARRAY['LED Lights', 'Digital Display', 'Under Seat Storage'], 4.3, 85, 'https://placehold.co/400x300/dc2626/white?text=Honda+Click'),
    ('Suzuki Raider R150', 'Suzuki', 'Raider', 'Sport', '150cc', 'Manual', '12L', 'Blue', 2022, 'DEF9012', 900.00, 'Sporty underbone with powerful engine', ARRAY['Disc Brakes', 'Digital Speedometer'], 4.2, 45, 'https://placehold.co/400x300/2563eb/white?text=Suzuki+Raider'),
    ('Honda PCX 160', 'Honda', 'PCX', 'Scooter', '157cc', 'Automatic', '8.1L', 'White', 2024, 'GHI3456', 850.00, 'Premium scooter with advanced features', ARRAY['ABS', 'Smart Key', 'LED Lights'], 4.8, 95, 'https://placehold.co/400x300/059669/white?text=Honda+PCX'),
    ('Yamaha Mio Aerox 155', 'Yamaha', 'Aerox', 'Scooter', '155cc', 'Automatic', '5.5L', 'Black', 2024, 'JKL7890', 750.00, 'Sport-inspired automatic scooter', ARRAY['VVA Engine', 'ABS', 'Smart Key'], 4.7, 78, 'https://placehold.co/400x300/7c3aed/white?text=Yamaha+Aerox')
ON CONFLICT (plate_number) DO NOTHING;

-- =============================================
-- STEP 5: ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motorcycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.penalties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

-- =============================================
-- STEP 6: CREATE RLS POLICIES
-- =============================================

-- OTP Codes Policies
-- Allow unauthenticated users to insert OTP during signup
CREATE POLICY "Allow inserting OTP during signup"
ON public.otp_codes FOR INSERT
WITH CHECK (true);

-- Allow reading OTP records (needed during verification)
CREATE POLICY "Allow reading OTP by email"
ON public.otp_codes FOR SELECT
USING (true);

-- Allow updating OTP records (to mark as used after verification)
CREATE POLICY "Allow updating OTP status"
ON public.otp_codes FOR UPDATE
USING (true);

-- Users Policies
CREATE POLICY "Users can view own profile"
ON public.users FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Admins can view all users"
ON public.users FOR SELECT
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can update any user"
ON public.users FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Allow user creation during signup"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Motorcycles Policies
CREATE POLICY "Anyone can view motorcycles"
ON public.motorcycles FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Only admins can insert motorcycles"
ON public.motorcycles FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Only admins can update motorcycles"
ON public.motorcycles FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Only admins can delete motorcycles"
ON public.motorcycles FOR DELETE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Bookings Policies
CREATE POLICY "Users can view own bookings"
ON public.bookings FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create own bookings"
ON public.bookings FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own pending bookings"
ON public.bookings FOR UPDATE
USING (auth.uid() = user_id AND status IN ('pending', 'waiting_approval'));

CREATE POLICY "Admins can view all bookings"
ON public.bookings FOR SELECT
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can update any booking"
ON public.bookings FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can delete bookings"
ON public.bookings FOR DELETE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Reviews Policies
CREATE POLICY "Anyone can view reviews"
ON public.reviews FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Users can create reviews for own bookings"
ON public.reviews FOR INSERT
WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
        SELECT 1 FROM public.bookings
        WHERE id = booking_id AND user_id = auth.uid() AND status = 'completed'
    )
);

CREATE POLICY "Users can update own reviews"
ON public.reviews FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews"
ON public.reviews FOR DELETE
USING (auth.uid() = user_id);

CREATE POLICY "Admins can delete any review"
ON public.reviews FOR DELETE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Penalties Policies
CREATE POLICY "Users can view own penalties"
ON public.penalties FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all penalties"
ON public.penalties FOR SELECT
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Only admins can create penalties"
ON public.penalties FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Only admins can update penalties"
ON public.penalties FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Only admins can delete penalties"
ON public.penalties FOR DELETE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Notifications Policies
CREATE POLICY "Users can view own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications"
ON public.notifications FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins can view all notifications"
ON public.notifications FOR SELECT
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can create any notification"
ON public.notifications FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can delete any notification"
ON public.notifications FOR DELETE
USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- =============================================
-- DONE! Your database is ready to use.
-- =============================================
