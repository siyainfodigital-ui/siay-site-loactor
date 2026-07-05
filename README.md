# Siya Site Locator 🌞
**Solar Field Management App** — Flutter + Supabase (100% Free Stack)

## Tech Stack (Zero Cost)
| Layer | Technology | Cost |
|---|---|---|
| Frontend | Flutter | Free |
| Backend | Supabase Free Plan | ₹0 |
| Database | Supabase PostgreSQL | ₹0 |
| Auth | Supabase Phone OTP | ₹0 |
| Storage | Supabase Storage | ₹0 |
| Maps | OpenStreetMap + flutter_map | ₹0 |
| Geocoding | OSM Nominatim API | ₹0 |
| GPS | Device GPS (Geolocator) | ₹0 |
| Navigation | Google Maps deep link (no API key) | ₹0 |

---

## Setup

### 1. Supabase Project Setup

Create a free project at [supabase.com](https://supabase.com)

#### SQL — Run in Supabase SQL Editor:

```sql
-- Customers table (single lightweight table)
CREATE TABLE customers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  mobile      TEXT UNIQUE NOT NULL,
  village     TEXT,
  taluka      TEXT,
  address     TEXT,
  solar_kw    NUMERIC,
  lat         NUMERIC,
  lng         NUMERIC,
  photo_url   TEXT,
  status      TEXT DEFAULT 'P' CHECK (status IN ('P','V','D')),
  installer   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Policy: authenticated users can read/write all rows
CREATE POLICY "Authenticated access" ON customers
  FOR ALL USING (auth.role() = 'authenticated');

-- Index for fast search
CREATE INDEX idx_customers_mobile ON customers(mobile);
CREATE INDEX idx_customers_installer ON customers(installer);
CREATE INDEX idx_customers_status ON customers(status);
```

#### Storage — Create bucket:
1. Go to Storage → New bucket
2. Name: `site_photos`
3. Public: ✅ Yes (for photo URL display)

#### Phone Auth:
1. Go to Auth → Providers → Phone
2. Enable phone provider
3. Configure your SMS provider (Twilio free trial works)

### 2. Environment Variables

Edit `.env` in project root:
```
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### 3. Set User Roles

After an installer logs in for the first time, set their role in Supabase:
```sql
-- Set admin role (run once for admin user)
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin"}'
WHERE phone = '+91XXXXXXXXXX';

-- Set installer role
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{"role": "installer"}'
WHERE phone = '+91XXXXXXXXXX';
```
> Default role (if not set) = installer

### 4. Run the App

```bash
cd "c:\app dev\siyasitelocator"
flutter pub get
flutter run
```

---

## Bulk Upload CSV Format

```csv
name,mobile,village,taluka,address,solar_kw
राम पाटील,9876543210,पुणे,हवेली,123 मेन रोड,3.5
सीता देसाई,9876543211,नाशिक,निफाड,456 साई नगर,5
```

---

## Status Codes

| Code | Meaning | मराठी |
|------|---------|-------|
| P | Pending | प्रलंबित |
| V | Visited | भेट दिली |
| D | Done | पूर्ण |

---

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── theme/app_theme.dart          # Solar green + sky blue
│   ├── constants/
│   │   ├── app_strings.dart          # Marathi + English labels
│   │   └── app_constants.dart        # Status codes, table names
│   ├── models/
│   │   ├── customer_model.dart
│   │   └── installer_model.dart
│   ├── services/
│   │   ├── supabase_service.dart     # DB + Auth + Storage
│   │   ├── location_service.dart     # GPS + Nominatim (free)
│   │   ├── cache_service.dart        # Hive offline cache
│   │   └── csv_excel_service.dart    # Bulk upload parser
│   ├── controllers/                  # GetX controllers
│   ├── bindings/                     # GetX lazy bindings
│   └── routes/app_routes.dart
└── screens/
    ├── splash/splash_screen.dart
    ├── auth/login_screen.dart
    ├── admin/
    │   ├── admin_dashboard_screen.dart
    │   ├── add_customer_screen.dart
    │   ├── map_location_picker_screen.dart  # flutter_map + OSM
    │   ├── bulk_upload_screen.dart
    │   └── customer_list_screen.dart
    └── installer/
        ├── installer_dashboard_screen.dart
        └── site_visit_screen.dart
```

---

## Free API Limits (Supabase Free Plan)
- Database: 500 MB
- Storage: 1 GB  
- Auth: Unlimited users
- Realtime: 500 concurrent connections
- Bandwidth: 5 GB/month

**Running cost: ₹0/month** until ~10,000 active users.
