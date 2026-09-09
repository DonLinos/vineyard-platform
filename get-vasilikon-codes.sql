-- Τρέξε αυτό στο Supabase SQL Editor για να πάρεις τη λίστα ονομάτων/κωδικών
-- πρόσβασης του οινοποιείου Βασιλικόν. Είναι απλό SELECT — δεν αλλάζει τίποτα.

select
  ac.person_name as "Όνομα",
  ac.code        as "Κωδικός",
  ac.active      as "Ενεργός",
  ac.first_used_at as "Πρώτη είσοδος"
from access_codes ac
join wineries w on w.id = ac.winery_id
where w.name ilike '%Βασιλικ%'
order by ac.person_name;
