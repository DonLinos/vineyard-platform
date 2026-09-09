-- Vitis Vision — υποδομή για το email "ο Χ συνδέθηκε για πρώτη φορά με τον κωδικό του".
-- Τρέξε το ΜΕΤΑ το signup-and-access-security-setup.sql (χρειάζεται τη συνάρτηση
-- check_access_code που δημιουργήθηκε εκεί — εδώ την αντικαθιστούμε με μια εκδοχή που
-- επιπλέον καταγράφει την πρώτη χρήση κάθε κωδικού).

alter table access_codes add column if not exists first_used_at timestamptz;

-- Αντικαθιστούμε τη check_access_code: τώρα, την πρώτη φορά που ένας ΕΝΕΡΓΟΣ κωδικός
-- χρησιμοποιείται με επιτυχία, καταγράφει το χρόνο (first_used_at) και επιστρέφει
-- is_first_use = true — μία φορά μόνο, ποτέ ξανά για τον ίδιο κωδικό.
drop function if exists check_access_code(text);

create function check_access_code(p_code text)
returns table(winery_id uuid, person_name text, active boolean, is_first_use boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_first boolean := false;
begin
  update access_codes
  set first_used_at = now()
  where code = p_code and active = true and first_used_at is null
  returning true into v_first;

  return query
  select ac.winery_id, ac.person_name, ac.active, coalesce(v_first, false) as is_first_use
  from access_codes ac
  where ac.code = p_code;
end;
$$;

revoke all on function check_access_code(text) from public;
grant execute on function check_access_code(text) to anon, authenticated;
