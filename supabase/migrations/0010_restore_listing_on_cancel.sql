-- =============================================================================
-- Listings: restore availability when an order is cancelled.
--
-- 0005 marks a listing as sold as soon as an order is created. If that order is
-- later cancelled, the listing should become active again, unless another
-- non-cancelled order still exists for the same listing.
-- =============================================================================

create or replace function public.sync_listing_status_from_order() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    update public.listings
       set status = 'sold'
     where id = new.listing_id
       and status <> 'sold';
    return new;
  end if;

  if (
    tg_op = 'UPDATE'
    and new.status = 'cancelled'
    and old.status is distinct from new.status
  ) then
    update public.listings
       set status = 'active'
     where id = new.listing_id
       and status = 'sold'
       and not exists (
         select 1
           from public.orders o
          where o.listing_id = new.listing_id
            and o.id <> new.id
            and o.status <> 'cancelled'
       );
  end if;

  return new;
end; $$;

drop trigger if exists trg_orders_mark_sold on public.orders;
drop trigger if exists trg_orders_sync_listing_status on public.orders;
create trigger trg_orders_sync_listing_status after insert or update of status
  on public.orders for each row execute function public.sync_listing_status_from_order();

drop function if exists public.mark_listing_sold();
