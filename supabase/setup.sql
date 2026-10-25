-- Galaxy Defender global leaderboard
-- Run this once in Supabase: SQL Editor -> New query -> paste -> Run.

-- 1. Every finished game is one row.
create table if not exists public.scores (
  id         bigint generated always as identity primary key,
  username   text        not null check (username ~ '^[A-Za-z0-9 _-]{1,16}$'),
  score      integer     not null check (score between 1 and 100000),
  level      integer     not null check (level between 1 and 100),
  created_at timestamptz not null default now()
);

-- 2. Row Level Security: the game (using the public key) may only
--    read scores and add new ones. Nobody can edit or delete them.
alter table public.scores enable row level security;

drop policy if exists "Anyone can read scores" on public.scores;
create policy "Anyone can read scores"
  on public.scores for select
  to anon, authenticated
  using (true);

drop policy if exists "Anyone can add a score" on public.scores;
create policy "Anyone can add a score"
  on public.scores for insert
  to anon, authenticated
  with check (true);

grant select, insert on public.scores to anon, authenticated;

-- 3. The leaderboard: each pilot's best score (names compared ignoring case).
create or replace view public.leaderboard
  with (security_invoker = true) as
select distinct on (lower(username))
  username, score, level, created_at
from public.scores
order by lower(username), score desc, created_at asc;

grant select on public.leaderboard to anon, authenticated;
