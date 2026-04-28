-- Add missing columns to existing alerts table
ALTER TABLE public.alerts 
ADD COLUMN IF NOT EXISTS latitude float,
ADD COLUMN IF NOT EXISTS longitude float,
ADD COLUMN IF NOT EXISTS location_address text,
ADD COLUMN IF NOT EXISTS category text DEFAULT 'Other';

-- Add constraint for category
ALTER TABLE public.alerts
ADD CONSTRAINT category_check CHECK (category IN ('Fire', 'Flood', 'Medical', 'Crime', 'Accident', 'Other'));

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS alerts_category_idx ON public.alerts (category);
CREATE INDEX IF NOT EXISTS alerts_location_idx ON public.alerts USING gist (point(longitude, latitude));

-- Create alert_logs table for activity tracking
CREATE TABLE IF NOT EXISTS public.alert_logs (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.alerts(id) on delete cascade,
  changed_by uuid not null references auth.users(id) on delete cascade,
  old_value text,
  new_value text,
  changed_at timestamptz not null default now()
);

CREATE INDEX IF NOT EXISTS alert_logs_alert_id_idx ON public.alert_logs (alert_id);
CREATE INDEX IF NOT EXISTS alert_logs_changed_at_idx ON public.alert_logs (changed_at desc);

-- Enable RLS on alert_logs
ALTER TABLE public.alert_logs ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read all alert logs
DROP POLICY IF EXISTS "alert_logs_select_authenticated" ON public.alert_logs;
CREATE POLICY "alert_logs_select_authenticated"
ON public.alert_logs
FOR SELECT
TO authenticated
USING (true);

-- Users can create logs only for their own alerts
DROP POLICY IF EXISTS "alert_logs_insert_own" ON public.alert_logs;
CREATE POLICY "alert_logs_insert_own"
ON public.alert_logs
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = changed_by);
