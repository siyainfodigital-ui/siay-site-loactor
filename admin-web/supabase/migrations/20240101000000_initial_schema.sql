-- Enums
CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'office_staff', 'installer');
CREATE TYPE user_status AS ENUM ('active', 'inactive');
CREATE TYPE customer_status AS ENUM ('pending', 'submitted', 'ready_for_verification', 'verified', 'rejected');
CREATE TYPE installation_status AS ENUM ('pending', 'submitted', 'approved', 'rejected');
CREATE TYPE photo_type AS ENUM ('structure', 'panel', 'inverter', 'meter', 'final');

-- Profiles Table (Extends auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'office_staff',
    mobile TEXT,
    status user_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Customers Table
CREATE TABLE public.customers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    application_number TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    mobile TEXT NOT NULL,
    village TEXT,
    application_date DATE,
    assigned_installer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status customer_status NOT NULL DEFAULT 'pending',
    progress INTEGER NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Installations Table
CREATE TABLE public.installations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE UNIQUE NOT NULL,
    inverter_brand TEXT,
    inverter_serial TEXT,
    meter_number TEXT,
    status installation_status NOT NULL DEFAULT 'pending',
    remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Photos Table
CREATE TABLE public.photos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    installation_id UUID REFERENCES public.installations(id) ON DELETE CASCADE NOT NULL,
    photo_type photo_type NOT NULL,
    storage_path TEXT NOT NULL,
    lat NUMERIC,
    lng NUMERIC,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Activity Logs Table
CREATE TABLE public.activity_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Notifications Table
CREATE TABLE public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER customers_updated_at
BEFORE UPDATE ON public.customers
FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER installations_updated_at
BEFORE UPDATE ON public.installations
FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Basic Policies (Can be refined later)

-- Profiles
CREATE POLICY "Users can view all profiles if authenticated" ON public.profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Customers
CREATE POLICY "Authenticated users can view customers" ON public.customers FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert customers" ON public.customers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update customers" ON public.customers FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete customers" ON public.customers FOR DELETE USING (auth.role() = 'authenticated');

-- Installations
CREATE POLICY "Authenticated users can view installations" ON public.installations FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert installations" ON public.installations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update installations" ON public.installations FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete installations" ON public.installations FOR DELETE USING (auth.role() = 'authenticated');

-- Photos
CREATE POLICY "Authenticated users can view photos" ON public.photos FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert photos" ON public.photos FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete photos" ON public.photos FOR DELETE USING (auth.role() = 'authenticated');

-- Activity Logs
CREATE POLICY "Authenticated users can view logs" ON public.activity_logs FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert logs" ON public.activity_logs FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Notifications
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Setup Storage Bucket for Photos
INSERT INTO storage.buckets (id, name, public) VALUES ('photos', 'photos', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Give users authenticated access to folder" ON storage.objects FOR SELECT USING (auth.role() = 'authenticated' AND bucket_id = 'photos');
CREATE POLICY "Give users authenticated insert access to folder" ON storage.objects FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND bucket_id = 'photos');
CREATE POLICY "Give users authenticated update access to folder" ON storage.objects FOR UPDATE USING (auth.role() = 'authenticated' AND bucket_id = 'photos');
CREATE POLICY "Give users authenticated delete access to folder" ON storage.objects FOR DELETE USING (auth.role() = 'authenticated' AND bucket_id = 'photos');
