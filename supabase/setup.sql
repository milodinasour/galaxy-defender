-- Galaxy Defender global leaderboard
-- Run this once in Supabase: SQL Editor -> New query -> paste -> Run.
-- Safe to run again: it only creates what's missing.

-- 1. Every finished game is one row.
create table if not exists public.galaxydefender_scores (
  id         bigint generated always as identity primary key,
  username   text        not null check (username ~ '^[A-Za-z0-9 _-]{1,16}$'),
  score      integer     not null check (score between 1 and 100000),
  level      integer     not null check (level between 1 and 100),
  created_at timestamptz not null default now()
);

-- 2. Row Level Security: the game (using the public key) may only
--    read scores and add new ones. Nobody can edit or delete them.
alter table public.galaxydefender_scores enable row level security;

drop policy if exists "Anyone can read scores" on public.galaxydefender_scores;
create policy "Anyone can read scores"
  on public.galaxydefender_scores for select
  to anon, authenticated
  using (true);

drop policy if exists "Anyone can add a score" on public.galaxydefender_scores;
create policy "Anyone can add a score"
  on public.galaxydefender_scores for insert
  to anon, authenticated
  with check (true);

grant select, insert on public.galaxydefender_scores to anon, authenticated;

-- 3. The leaderboard is simply the highest rows in galaxydefender_scores
--    (the game reads the table directly, so a pilot can appear more than once).

-- 4. Copy scores from the old "scores" table (only if it exists and the new
--    table is still empty, so running this twice never duplicates anything).
do $$
begin
  if to_regclass('public.scores') is not null
     and not exists (select 1 from public.galaxydefender_scores) then
    insert into public.galaxydefender_scores (username, score, level, created_at)
    select username, score, level, created_at
    from public.scores
    order by created_at;
  end if;
end $$;
