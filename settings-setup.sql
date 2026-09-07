-- Vitis Vision — πίνακας για τις "Ρυθμίσεις" (⚙️) του admin.html: επιπλέον ποικιλίες
-- πέρα από τη βασική ενσωματωμένη λίστα. Τρέξε αυτό ΜΙΑ ΦΟΡΑ στο Supabase → SQL Editor.
-- Το 'VAS — Vasilissa' ΔΕΝ χρειάζεται αυτόν τον πίνακα — προστέθηκε ήδη απευθείας στη βασική
-- λίστα μέσα στον κώδικα (admin.html). Αυτός ο πίνακας είναι για ΟΠΟΙΑΔΗΠΟΤΕ ποικιλία θελήσεις
-- να προσθέσεις στο μέλλον μέσα από το ⚙️ Ρυθμίσεις, χωρίς να χρειάζεται να ξαναγράψω κώδικα.

create table if not exists custom_varieties (
  id uuid primary key default gen_random_uuid(),
  winery_id uuid not null references wineries(id) on delete cascade,
  code text,
  name text not null,
  created_at timestamptz not null default now(),
  unique(winery_id, name)
);

-- Row Level Security: ενεργοποίησε το ίδιο μοτίβο πρόσβασης που έχεις ήδη στους άλλους
-- πίνακες (π.χ. variety_thresholds, access_codes). Αν δεν είσαι σίγουρος τι πολιτική έχεις
-- ήδη εκεί, τρέξε πρώτα: select * from pg_policies where tablename='variety_thresholds';
-- και αντίγραψε το ίδιο μοτίβο εδώ, αλλάζοντας μόνο το όνομα πίνακα.
alter table custom_varieties enable row level security;
