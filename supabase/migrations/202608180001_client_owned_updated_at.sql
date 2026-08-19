-- The set_updated_at trigger unconditionally stamped now() on every UPDATE,
-- clobbering the client-supplied updated_at that cloud sync uses for
-- last-write-wins comparisons. After the first sync every upsert resolved to
-- an UPDATE, so every remote row looked "newer" than local and the whole
-- library was re-downloaded on each sync. Respect an explicitly supplied
-- updated_at and only default it when the client left it untouched.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.updated_at is null or new.updated_at is not distinct from old.updated_at then
    new.updated_at = now();
  end if;
  return new;
end;
$$;
