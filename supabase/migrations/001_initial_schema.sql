-- ============================================================
-- VareFy Alpha v0.1 — Initial Schema Migration
-- Paste into Supabase SQL Editor and run as one block
-- ============================================================

-- ============================================================
-- PROFILES
-- Extends auth.users. Created by Edge Function on signup.
-- ============================================================

create table public.profiles (
  id                    uuid primary key references auth.users(id) on delete cascade,
  role                  text not null check (role in ('client', 'pro', 'admin', 'integrity_agent')),
  display_name          text not null,
  email                 text not null,
  phone                 text,
  avatar_storage_path   text,
  stripe_connect_id     text,
  stripe_connect_status text check (stripe_connect_status in ('pending', 'active', 'restricted')),
  invite_code_used      text,
  is_verified           boolean default false,
  created_at            timestamptz default now(),
  updated_at            timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Admins and agents can view all profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

create policy "Admins can update any profile"
  on public.profiles for update
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role = 'admin'
    )
  );

create policy "Service role can insert profiles"
  on public.profiles for insert
  with check (true);

-- ============================================================
-- INVITE CODES
-- Admin generates. Required for signup. One use only.
-- ============================================================

create table public.invite_codes (
  code          text primary key,
  role          text not null check (role in ('client', 'pro')),
  used          boolean default false,
  used_by       uuid references public.profiles(id),
  used_at       timestamptz,
  created_by    uuid references public.profiles(id),
  created_at    timestamptz default now()
);

alter table public.invite_codes enable row level security;

create policy "Admins can manage invite codes"
  on public.invite_codes for all
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role = 'admin'
    )
  );

-- Edge Function (service role) reads invite codes to validate on signup
-- No client-side read access to invite codes

-- ============================================================
-- SERVICE CATEGORIES
-- ============================================================

create table public.service_categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  active      boolean default true,
  created_at  timestamptz default now()
);

alter table public.service_categories enable row level security;

create policy "Authenticated users can view active categories"
  on public.service_categories for select
  using (auth.role() = 'authenticated' and active = true);

create policy "Admins can manage service categories"
  on public.service_categories for all
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role = 'admin'
    )
  );

-- Seed initial DFW alpha categories
insert into public.service_categories (name, description) values
  ('Lawn & Landscaping', 'Mowing, edging, trimming, cleanup'),
  ('Cleaning', 'Residential and commercial cleaning'),
  ('Handyman', 'General repairs and maintenance'),
  ('Pressure Washing', 'Driveways, siding, decks'),
  ('Moving & Hauling', 'Furniture moving, junk removal'),
  ('Painting', 'Interior and exterior painting');

-- ============================================================
-- WORK ORDERS
-- Core entity. All state transitions happen here.
-- ============================================================

create table public.work_orders (
  id                        uuid primary key default gen_random_uuid(),
  client_id                 uuid not null references public.profiles(id),
  pro_id                    uuid references public.profiles(id),
  status                    text not null default 'pending' check (status in (
    'pending', 'ready_to_navigate', 'en_route', 'arrived',
    'pre_work', 'active_billing', 'paused', 'post_work',
    'client_review', 'completed', 'disputed', 'cancelled'
  )),
  service_title             text not null,
  service_category_id       uuid references public.service_categories(id),
  address                   text not null,
  latitude                  float8,
  longitude                 float8,
  hourly_rate               float8 not null,
  client_notes              text,
  scheduled_at              timestamptz not null,
  radius_expanded           boolean default false,
  paused_return_status      text,

  -- Billing — server-anchored timestamps only, never device clock
  billing_start_at          timestamptz,
  billing_paused_at         timestamptz,
  elapsed_billing_seconds   float8 default 0,

  -- Totals — written at completion and locked
  labor_total               float8 default 0,
  materials_total           float8 default 0,
  total_paid                float8 default 0,

  -- Payment
  payout_status             text default 'unpaid' check (payout_status in (
    'unpaid', 'pending', 'processing', 'paid', 'disputed', 'failed'
  )),
  stripe_payment_intent_id  text,
  stripe_transfer_id        text,

  created_at                timestamptz default now(),
  updated_at                timestamptz default now(),
  completed_at              timestamptz
);

alter table public.work_orders enable row level security;

create policy "Clients can view their own work orders"
  on public.work_orders for select
  using (auth.uid() = client_id);

create policy "Clients can create work orders"
  on public.work_orders for insert
  with check (auth.uid() = client_id);

create policy "Clients can update their own work orders"
  on public.work_orders for update
  using (auth.uid() = client_id);

create policy "Pros can view assigned work orders"
  on public.work_orders for select
  using (auth.uid() = pro_id);

create policy "Pros can view pending unassigned work orders"
  on public.work_orders for select
  using (
    status = 'pending' and pro_id is null and
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role = 'pro'
    )
  );

create policy "Pros can update their assigned work orders"
  on public.work_orders for update
  using (auth.uid() = pro_id);

create policy "Admins and agents can view all work orders"
  on public.work_orders for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

create policy "Admins and agents can update any work order"
  on public.work_orders for update
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

-- ============================================================
-- TIMELINE EVENTS
-- Append-only audit log. Never delete or update rows.
-- ============================================================

create table public.timeline_events (
  id             uuid primary key default gen_random_uuid(),
  work_order_id  uuid not null references public.work_orders(id) on delete cascade,
  event_type     text not null check (event_type in (
    'confirmed', 'arrived', 'radius_expanded', 'started',
    'paused', 'auto_paused', 'resumed', 'completed',
    'client_approved', 'client_disputed',
    'admin_override', 'payout_initiated', 'payout_completed'
  )),
  actor_id       uuid references public.profiles(id),
  actor_role     text,
  metadata       jsonb,
  occurred_at    timestamptz default now()
);

alter table public.timeline_events enable row level security;

-- No updates or deletes ever — append only
create policy "Participants can view timeline events"
  on public.timeline_events for select
  using (
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and (wo.client_id = auth.uid() or wo.pro_id = auth.uid())
    )
  );

create policy "Participants can insert timeline events"
  on public.timeline_events for insert
  with check (
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and (wo.client_id = auth.uid() or wo.pro_id = auth.uid())
    )
  );

create policy "Admins and agents can view all timeline events"
  on public.timeline_events for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

create policy "Admins can insert timeline events"
  on public.timeline_events for insert
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

-- ============================================================
-- WORK ORDER PHOTOS
-- ============================================================

create table public.work_order_photos (
  id             uuid primary key default gen_random_uuid(),
  work_order_id  uuid not null references public.work_orders(id) on delete cascade,
  uploaded_by    uuid not null references public.profiles(id),
  photo_type     text not null check (photo_type in ('pre', 'post')),
  storage_path   text not null,
  uploaded_at    timestamptz default now()
);

alter table public.work_order_photos enable row level security;

create policy "Participants can view work order photos"
  on public.work_order_photos for select
  using (
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and (wo.client_id = auth.uid() or wo.pro_id = auth.uid())
    )
  );

create policy "Pro can upload photos for their work orders"
  on public.work_order_photos for insert
  with check (
    auth.uid() = uploaded_by and
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and wo.pro_id = auth.uid()
    )
  );

create policy "Admins and agents can view all photos"
  on public.work_order_photos for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

-- ============================================================
-- MATERIAL ITEMS
-- ============================================================

create table public.material_items (
  id                    uuid primary key default gen_random_uuid(),
  work_order_id         uuid not null references public.work_orders(id) on delete cascade,
  description           text not null,
  amount                float8 not null,
  receipt_storage_path  text,
  added_by              uuid references public.profiles(id),
  created_at            timestamptz default now()
);

alter table public.material_items enable row level security;

create policy "Participants can view material items"
  on public.material_items for select
  using (
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and (wo.client_id = auth.uid() or wo.pro_id = auth.uid())
    )
  );

create policy "Pro can manage material items for their work orders"
  on public.material_items for all
  using (
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and wo.pro_id = auth.uid()
    )
  );

create policy "Admins and agents can view all material items"
  on public.material_items for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

-- ============================================================
-- TRANSACTIONS
-- Financial record. Created at completion. Updated by Stripe webhooks.
-- ============================================================

create table public.transactions (
  id                        uuid primary key default gen_random_uuid(),
  work_order_id             uuid not null references public.work_orders(id),
  pro_id                    uuid not null references public.profiles(id),
  transaction_type          text not null check (transaction_type in (
    'labor', 'materials', 'payout', 'refund', 'adjustment'
  )),
  amount                    float8 not null,
  status                    text default 'pending' check (status in (
    'pending', 'processing', 'completed', 'failed', 'cancelled'
  )),
  stripe_payment_intent_id  text,
  stripe_transfer_id        text,
  stripe_payout_id          text,
  is_instant                boolean default false,
  fee_amount                float8 default 0,
  net_amount                float8,
  created_at                timestamptz default now(),
  updated_at                timestamptz default now()
);

alter table public.transactions enable row level security;

create policy "Pro can view their own transactions"
  on public.transactions for select
  using (auth.uid() = pro_id);

create policy "Client can view transactions for their work orders"
  on public.transactions for select
  using (
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and wo.client_id = auth.uid()
    )
  );

create policy "Admins and agents can view all transactions"
  on public.transactions for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

create policy "Admins and agents can update transactions"
  on public.transactions for update
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

-- ============================================================
-- LOCATION EVENTS
-- GPS and radius event log during active jobs.
-- ============================================================

create table public.location_events (
  id             uuid primary key default gen_random_uuid(),
  work_order_id  uuid not null references public.work_orders(id) on delete cascade,
  pro_id         uuid not null references public.profiles(id),
  event_type     text not null check (event_type in (
    'entered_radius', 'exited_radius', 'auto_paused'
  )),
  latitude       float8,
  longitude      float8,
  accuracy       float8,
  occurred_at    timestamptz default now()
);

alter table public.location_events enable row level security;

create policy "Pro can insert location events for their jobs"
  on public.location_events for insert
  with check (
    auth.uid() = pro_id and
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and wo.pro_id = auth.uid()
    )
  );

create policy "Participants can view location events"
  on public.location_events for select
  using (
    exists (
      select 1 from public.work_orders wo
      where wo.id = work_order_id
      and (wo.client_id = auth.uid() or wo.pro_id = auth.uid())
    )
  );

create policy "Admins and agents can view all location events"
  on public.location_events for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );

-- ============================================================
-- UPDATED_AT TRIGGER
-- Automatically stamps updated_at on any row change.
-- ============================================================

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

create trigger set_updated_at
  before update on public.work_orders
  for each row execute function public.handle_updated_at();

create trigger set_updated_at
  before update on public.transactions
  for each row execute function public.handle_updated_at();

-- ============================================================
-- REALTIME
-- Enable live subscriptions for both iOS apps.
-- ============================================================

alter publication supabase_realtime add table public.work_orders;
alter publication supabase_realtime add table public.timeline_events;
alter publication supabase_realtime add table public.work_order_photos;
alter publication supabase_realtime add table public.transactions;
