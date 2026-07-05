# PM Surya Ghar Management System - Admin Web Panel

This is a production-ready Admin Web Panel built for Siya Infotech to manage PM Surya Ghar solar installations, customers, and field staff.

## Technology Stack

* **Framework:** Next.js 15 (App Router)
* **Language:** TypeScript
* **Styling:** Tailwind CSS v4 + shadcn/ui (Material Design 3 inspired)
* **Database & Auth:** Supabase (PostgreSQL, GoTrue, Storage)
* **Icons:** Lucide React
* **Deployment:** Vercel (Recommended)

## Key Features Implemented

1. **Role-Based Access Control (RBAC):** Supabase Auth middleware protecting all dashboard routes.
2. **Dashboard Overview:** Real-time summary statistics and pending verification queues.
3. **Customer & Installation Management:** Powerful data tables with search, filter, and pagination.
4. **Global Image Viewer:** Advanced photo viewer with zoom, pan, and EXIF metadata display for geo-tagged installation photos.
5. **Security:** PostgreSQL Row Level Security (RLS) policies implemented in the database.

## Installation & Local Development

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Supabase Setup:**
   - Create a new project on [Supabase](https://supabase.com).
   - Navigate to the **SQL Editor** in your Supabase dashboard.
   - Copy the contents of `supabase/migrations/20240101000000_initial_schema.sql` and run it to create all tables, types, triggers, and RLS policies.
   - Go to Project Settings -> API and copy your URL and Anon Key.

3. **Environment Variables:**
   - Rename `.env.local.example` (or just create `.env.local`) and add your Supabase credentials:
     ```env
     NEXT_PUBLIC_SUPABASE_URL=your-project-url
     NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
     ```

4. **Run Development Server:**
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000) in your browser.

## Deployment to Vercel

1. Push this codebase to a GitHub repository.
2. Log in to [Vercel](https://vercel.com) and click **Add New Project**.
3. Import your GitHub repository.
4. In the **Environment Variables** section, add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
5. Click **Deploy**. Vercel will automatically detect the Next.js framework and build the production bundle.
6. (Optional) Add your custom domain `admin.siyainfotech.in` in the Vercel project settings under "Domains".

## Performance & Security Notes

- **Image Caching:** Next.js `<Image>` component should be used for Supabase storage URLs to automatically cache and compress images.
- **SSR/Server Components:** By default, pages in the App router are Server Components, meaning they ship zero JavaScript to the client, ensuring fast loads for large datasets (50,000+ customers).
- **RLS:** Never disable Row Level Security in Supabase. It ensures that even if API keys are leaked, users can only access data permitted by their assigned role.
