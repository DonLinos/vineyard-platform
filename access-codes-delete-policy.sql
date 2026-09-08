-- Vitis Vision — επιτρέπει τη ΔΙΑΓΡΑΦΗ κωδικών πρόσβασης (το νέο κουμπί "Διαγραφή" στις
-- Ρυθμίσεις ⚙️). Ίδιο μοτίβο με τα insert/update που έτρεξες ήδη σήμερα.
create policy "access_codes_delete" on access_codes
for delete
using (has_winery_access(winery_id));
