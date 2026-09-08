-- Vitis Vision — προσθέτει στήλη για το όνομα του επόπτη κάθε οινοποιείου, ώστε να
-- εμφανίζεται στο dashboard του πελάτη (reports.html) μαζί με το όνομα του σύμβουλου.
-- Ρυθμίζεται από τον admin μέσα από τις Ρυθμίσεις (⚙️) στο admin.html.
alter table wineries add column if not exists supervisor_name text;
