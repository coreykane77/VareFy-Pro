-- ============================================================
-- VareFy Alpha v0.1 — Storage Buckets & Policies
-- ============================================================

-- Avatars: public (profile photos shown in UI)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true);

-- Work order photos and receipts: private (RLS controlled)
insert into storage.buckets (id, name, public)
values ('work-orders', 'work-orders', false);

-- ============================================================
-- STORAGE POLICIES — avatars
-- ============================================================

create policy "Anyone can view avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update their own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- STORAGE POLICIES — work-orders
-- ============================================================

create policy "Participants can view work order files"
  on storage.objects for select
  using (
    bucket_id = 'work-orders' and
    exists (
      select 1 from public.work_orders wo
      where wo.id::text = (storage.foldername(name))[1]
      and (wo.client_id = auth.uid() or wo.pro_id = auth.uid())
    )
  );

create policy "Pro can upload files for their work orders"
  on storage.objects for insert
  with check (
    bucket_id = 'work-orders' and
    exists (
      select 1 from public.work_orders wo
      where wo.id::text = (storage.foldername(name))[1]
      and wo.pro_id = auth.uid()
    )
  );

create policy "Admins and agents can view all work order files"
  on storage.objects for select
  using (
    bucket_id = 'work-orders' and
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
      and p.role in ('admin', 'integrity_agent')
    )
  );
