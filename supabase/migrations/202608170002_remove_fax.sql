-- Safe cleanup for any environment that ran an earlier draft of the schema.
drop table if exists public.fax_jobs cascade;
alter table if exists public.users drop column if exists stripe_customer_id;
alter table if exists public.subscriptions drop column if exists stripe_customer_id;
alter table if exists public.subscriptions drop column if exists stripe_subscription_id;
