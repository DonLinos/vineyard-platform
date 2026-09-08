-- Vitis Vision — SQL για το sign up με email + το κλείσιμο ενός παλιού κενού ασφαλείας.
-- Τρέξε ΟΛΟΚΛΗΡΟ αυτό το αρχείο μία φορά στο Supabase SQL Editor.
--
-- ΜΕΡΟΣ 1 — "Εκκρεμείς εγγραφές": όταν κάποιος κάνει sign up με email από το login.html, δεν
-- παίρνει αυτόματα πρόσβαση σε κανένα οινοποίειο (αυτό παραμένει επιλογή του admin). Ο νέος
-- λογαριασμός καταγράφεται εδώ, ώστε να τον βλέπεις μέσα στο admin (Ρυθμίσεις ⚙️) και να του
-- δίνεις πρόσβαση με ένα κλικ.
create table if not exists pending_signups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null unique,
  email text not null,
  note text,
  created_at timestamptz default now()
);

alter table pending_signups enable row level security;

-- Ο ίδιος ο χρήστης που μόλις έκανε εγγραφή μπορεί να καταχωρήσει τη δική του εκκρεμή αίτηση.
drop policy if exists "users can create their own pending signup" on pending_signups;
create policy "users can create their own pending signup" on pending_signups
  for insert with check (auth.uid() = user_id);

-- Μόνο λογαριασμοί με ρόλο 'agronomist' σε ΚΑΠΟΙΟ οινοποίειο (δηλαδή εσύ / οι συνεργάτες σου
-- σήμερα) μπορούν να δουν και να διαχειριστούν τις εκκρεμείς εγγραφές.
drop policy if exists "agronomists can view pending signups" on pending_signups;
create policy "agronomists can view pending signups" on pending_signups
  for select using (
    exists (select 1 from memberships m where m.user_id = auth.uid() and m.role = 'agronomist')
  );

drop policy if exists "agronomists can delete pending signups" on pending_signups;
create policy "agronomists can delete pending signups" on pending_signups
  for delete using (
    exists (select 1 from memberships m where m.user_id = auth.uid() and m.role = 'agronomist')
  );


-- ΜΕΡΟΣ 2 — Κλείνει ένα παλιό, πραγματικό κενό ασφαλείας που είχαμε εντοπίσει νωρίτερα αλλά
-- δεν είχαμε διορθώσει ακόμα: ο πίνακας access_codes είχε ΑΝΟΙΧΤΗ πολιτική SELECT (ο καθένας
-- με το δημόσιο anon key μπορούσε να διαβάσει ΟΛΟΥΣ τους κωδικούς όλων των οινοποιείων). Αυτό
-- ήταν σκόπιμο τότε, γιατί η σελίδα εισόδου με κωδικό (πριν το login) χρειάζεται να ψάξει τον
-- κωδικό ΧΩΡΙΣ να είναι κανείς ακόμα συνδεδεμένος. Τώρα που προσθέτουμε sign up (και άρα πιο
-- εύκολη πρόσβαση σε λογαριασμό), είναι η κατάλληλη στιγμή να το κλείσουμε σωστά:
--   • Η αναζήτηση κωδικού γίνεται πλέον μέσω μιας συνάρτησης (check_access_code) που επιστρέφει
--     ΜΟΝΟ τα 3 πεδία που χρειάζεται η σελίδα εισόδου για τον ΣΥΓΚΕΚΡΙΜΕΝΟ κωδικό — όχι όλον τον
--     πίνακα.
--   • Η παλιά ανοιχτή πολιτική SELECT αφαιρείται.
--   • Προστίθεται σωστή πολιτική SELECT ώστε ο admin να συνεχίσει να βλέπει τους κωδικούς ΤΟΥ
--     ΔΙΚΟΥ ΤΟΥ οινοποιείου μέσα στο admin.html, όπως και πριν.
create or replace function check_access_code(p_code text)
returns table(winery_id uuid, person_name text, active boolean)
language sql
security definer
set search_path = public
as $$
  select winery_id, person_name, active from access_codes where code = p_code;
$$;

revoke all on function check_access_code(text) from public;
grant execute on function check_access_code(text) to anon, authenticated;

do $$
declare
  pol record;
begin
  for pol in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'access_codes' and cmd = 'SELECT'
  loop
    execute format('drop policy %I on public.access_codes', pol.policyname);
  end loop;
end $$;

create policy "winery members can view their access codes" on access_codes
  for select using (has_winery_access(winery_id));


-- ΣΗΜΕΙΩΣΗ (ρύθμιση, όχι SQL): στο Supabase dashboard → Authentication → Settings υπάρχει η
-- επιλογή "Confirm email". Δεν χρειάζεται να την αλλάξεις — όποια κι αν είναι, ο νέος
-- λογαριασμός ΔΕΝ αποκτά καμία πρόσβαση σε δεδομένα μέχρι να του τη δώσεις εσύ χειροκίνητα από
-- τις "Εκκρεμείς εγγραφές" στο admin.html. Αν είναι ενεργή, ο χρήστης απλά θα χρειαστεί να
-- επιβεβαιώσει το email του πριν προλάβει να συνδεθεί — δεν επηρεάζει την ασφάλεια.
