-- Vitis Vision — FIX: "column reference active is ambiguous" (Postgres error 42702)
-- στη check_access_code, που εμπόδιζε ΟΛΟΥΣ τους κωδικούς πρόσβασης να συνδεθούν
-- (Σεπτέμβριος 2026).
--
-- Αιτία: η function επιστρέφει μια στήλη "active" (RETURNS TABLE(..., active boolean, ...)),
-- και μέσα στο σώμα της υπήρχε ένα UPDATE ... WHERE active = true χωρίς alias πίνακα — η
-- Postgres δεν μπορούσε να ξεχωρίσει αν το "active" αναφέρεται στη μεταβλητή επιστροφής της
-- function ή στη στήλη access_codes.active. Λύση: alias "ac" στο UPDATE + πλήρως
-- προσδιορισμένα ονόματα στηλών (ac.code, ac.active, ac.first_used_at).
--
-- Τρέξε ΟΛΟΚΛΗΡΟ αυτό το αρχείο μία φορά στο Supabase SQL Editor. Αντικαθιστά τη function,
-- δεν πειράζει τίποτα άλλο (πίνακες, δεδομένα, RLS policies).

create or replace function check_access_code(p_code text)
returns table(winery_id uuid, person_name text, active boolean, is_first_use boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_first boolean := false;
begin
  update access_codes ac
  set first_used_at = now()
  where ac.code = p_code and ac.active = true and ac.first_used_at is null
  returning true into v_first;

  return query
  select ac.winery_id, ac.person_name, ac.active, coalesce(v_first, false) as is_first_use
  from access_codes ac
  where ac.code = p_code;
end;
$$;

revoke all on function check_access_code(text) from public;
grant execute on function check_access_code(text) to anon, authenticated;
