-- Vitis Vision — προσθέτει στήλη email στον πίνακα wineries (μόνο για αρχείο/επικοινωνία,
-- ΔΕΝ χρησιμοποιείται για login — το προσωπικό συνεχίζει να μπαίνει με κωδικό πρόσβασης).
-- Ρυθμίζεται από τον admin μέσα από τις Ρυθμίσεις (⚙️) στο admin.html.
alter table wineries add column if not exists email text;
