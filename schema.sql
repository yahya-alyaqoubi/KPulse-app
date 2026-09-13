-- KPulse database schema
-- Run this once in your Supabase project's SQL Editor (Supabase Dashboard -> SQL Editor -> New query -> paste -> Run).

create table if not exists public.entries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id),
  entered_by text,
  date date,
  team text,
  section text,
  kp_from numeric,
  kp_to numeric,
  activity text,
  unit text,
  planned numeric,
  actual numeric,
  manpower numeric,
  equipment text,
  equipment_id text,
  hours numeric,
  downtime numeric,
  has_constraint boolean default false,
  reason text,
  hse text,
  qaqc text,
  remarks text,
  photo text
);

create table if not exists public.constraints (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id),
  entered_by text,
  date date,
  kp text,
  activity text,
  category text,
  description text,
  responsible text,
  priority text,
  status text
);

create table if not exists public.equipment (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id),
  code text,
  name text,
  status text default 'Active',
  notes text
);

-- Row Level Security: only signed-in users can read or write, and every
-- row must be attributed to the user who created it.
alter table public.entries enable row level security;
alter table public.constraints enable row level security;
alter table public.equipment enable row level security;

create policy "entries_select_authenticated" on public.entries
  for select to authenticated using (true);
create policy "entries_insert_own" on public.entries
  for insert to authenticated with check (auth.uid() = user_id);
create policy "entries_update_own" on public.entries
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "entries_delete_own" on public.entries
  for delete to authenticated using (auth.uid() = user_id);

create policy "constraints_select_authenticated" on public.constraints
  for select to authenticated using (true);
create policy "constraints_insert_own" on public.constraints
  for insert to authenticated with check (auth.uid() = user_id);
create policy "constraints_update_own" on public.constraints
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "constraints_delete_own" on public.constraints
  for delete to authenticated using (auth.uid() = user_id);

-- Equipment is shared operational state (any team member can flag a
-- machine as under maintenance), so updates are not restricted to the
-- creator the way entries/constraints are. Only the creator can delete.
create policy "equipment_select_authenticated" on public.equipment
  for select to authenticated using (true);
create policy "equipment_insert_own" on public.equipment
  for insert to authenticated with check (auth.uid() = user_id);
create policy "equipment_update_shared" on public.equipment
  for update to authenticated using (true) with check (true);
create policy "equipment_delete_own" on public.equipment
  for delete to authenticated using (auth.uid() = user_id);

-- Realtime: lets the app push new entries/constraints/equipment changes
-- to every open browser tab live, without refreshing.
alter publication supabase_realtime add table public.entries;
alter publication supabase_realtime add table public.constraints;
alter publication supabase_realtime add table public.equipment;
