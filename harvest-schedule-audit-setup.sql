-- Vitis Vision — προσθέτει "ποιος το άλλαξε τελευταία" στο ημερολόγιο τρύγου (harvest_schedule),
-- ώστε αν συμβεί λάθος όταν μπαίνουν πολλά άτομα με κωδικό, να μπορείς να δεις ποιος το έκανε.
alter table harvest_schedule add column if not exists updated_by text;
