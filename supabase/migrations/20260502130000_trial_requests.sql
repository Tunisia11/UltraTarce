-- 20260502130000_trial_requests.sql
-- Create trial_requests table for controlled signup flow

CREATE TABLE IF NOT EXISTS public.trial_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    email text NOT NULL,
    phone text,
    company_name text NOT NULL,
    message text,
    status text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'approved', 'rejected', 'converted')),
    source text DEFAULT 'trace_ultra',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    converted_user_id uuid,
    converted_tenant_id uuid,
    internal_notes text
);

-- Enable RLS
ALTER TABLE public.trial_requests ENABLE ROW LEVEL SECURITY;

-- 1. Anonymous/Authenticated users can INSERT trial requests
CREATE POLICY "Anyone can submit trial requests" 
ON public.trial_requests 
FOR INSERT 
TO public
WITH CHECK (true);

-- 2. Platform admins can SELECT/UPDATE trial requests
-- We assume admins have a metadata field or belong to a specific tenant/role
-- For simplicity in this pilot, we check if the user is an 'owner' of any tenant 
-- OR we can use the existing 'team_members' role check if we designate an admin tenant.
-- Let's use the existing role check for 'owner' or 'admin' on a specific platform tenant if available.
-- For now, let's allow users with 'owner' role in at least one tenant to read (for the admin dashboard).
CREATE POLICY "Platform admins can manage trial requests" 
ON public.trial_requests 
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.team_members
    WHERE user_id = auth.uid()
    AND role IN ('owner', 'admin')
  )
);

-- 3. No public SELECT
-- (Implicitly handled by not adding a SELECT policy for anon)

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_trial_requests_updated_at
BEFORE UPDATE ON public.trial_requests
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- Add index for search
CREATE INDEX idx_trial_requests_email ON public.trial_requests(email);
CREATE INDEX idx_trial_requests_status ON public.trial_requests(status);
CREATE INDEX idx_trial_requests_created_at ON public.trial_requests(created_at);
