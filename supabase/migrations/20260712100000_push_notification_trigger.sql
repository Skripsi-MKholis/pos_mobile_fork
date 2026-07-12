-- Aktifkan pg_net untuk HTTP call async dari Postgres
create extension if not exists pg_net with schema extensions;

-- Trigger function: teruskan INSERT notifications ke Edge Function push-notification.
-- Anon key dipakai sebagai bearer agar lolos verifikasi JWT function (key ini memang publik).
create or replace function public.notify_push_on_notification()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform net.http_post(
    url := 'https://nolawradcdkemdyumoqs.supabase.co/functions/v1/push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vbGF3cmFkY2RrZW1keXVtb3FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MjAzNjIsImV4cCI6MjA5MTQ5NjM2Mn0.uwTp2g6yPJv6JUvyv4NBr1m0DgVt5fmKPiR3ED4hs4I'
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'notifications',
      'record', to_jsonb(NEW)
    ),
    timeout_milliseconds := 5000
  );
  return NEW;
end;
$$;

drop trigger if exists trigger_push_notification on public.notifications;
create trigger trigger_push_notification
  after insert on public.notifications
  for each row execute function public.notify_push_on_notification();
