-- Two integrity fixes for the free-tier AI cap and App Store entitlements.
--
-- 1. The AI cap was enforced with a read-modify-write across two round trips,
--    so concurrent requests all read the same pre-increment value and every one
--    of them passed the check. Reserving a message must be a single atomic
--    statement.
-- 2. An App Store transaction was never bound to the account that redeemed it,
--    so one purchase could unlock Plus on unlimited accounts.

-- Atomically reserve one AI message for a user.
--
-- Rolls the monthly window over when it has expired, then increments only when
-- the caller is entitled or still under the limit. Returns the post-increment
-- count so the caller can report usage without a second read. SECURITY DEFINER
-- because usage_limits is RLS-protected and this must be callable for the
-- authenticated user without granting them direct write access.
create or replace function public.consume_ai_message(
  p_user_id uuid,
  p_limit integer,
  p_unlimited boolean
)
returns table (allowed boolean, used integer, monthly_limit integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_period_start timestamptz := date_trunc('month', now());
  v_period_end timestamptz := date_trunc('month', now()) + interval '1 month';
  v_used integer;
begin
  -- Insert-or-lock the row, resetting the counter when the window rolled over.
  insert into public.usage_limits as u (user_id, ai_messages_used, period_start, period_end)
  values (p_user_id, 0, v_period_start, v_period_end)
  on conflict (user_id) do update
    set ai_messages_used = case
          when u.period_end <= now() then 0
          else u.ai_messages_used
        end,
        period_start = case
          when u.period_end <= now() then v_period_start
          else u.period_start
        end,
        period_end = case
          when u.period_end <= now() then v_period_end
          else u.period_end
        end
  returning u.ai_messages_used into v_used;

  if not p_unlimited and v_used >= p_limit then
    return query select false, v_used, p_limit;
    return;
  end if;

  -- The row is locked by the statement above for the rest of this transaction,
  -- so this increment cannot race another caller.
  update public.usage_limits
    set ai_messages_used = ai_messages_used + 1,
        updated_at = now()
    where user_id = p_user_id
    returning ai_messages_used into v_used;

  return query select true, v_used, p_limit;
end;
$$;

revoke all on function public.consume_ai_message(uuid, integer, boolean) from public;
grant execute on function public.consume_ai_message(uuid, integer, boolean) to service_role;

-- One App Store transaction may unlock exactly one account. Partial so the
-- many rows seeded with a null transaction id by handle_new_user still insert.
create unique index if not exists subscriptions_app_store_transaction_id_key
  on public.subscriptions (app_store_transaction_id)
  where app_store_transaction_id is not null;
