// shared.js — Vitis Vision: κοινό config + auth helper για όλες τις σελίδες.
// Πριν, το SUPABASE_URL/KEY και η requireAccess() ήταν αντιγραμμένα ξεχωριστά μέσα σε κάθε HTML
// αρχείο· αυτό το αρχείο τα κρατάει σε ΕΝΑ σημείο, ώστε μια αλλαγή (π.χ. νέο Supabase key, ή fix
// στη requireAccess) να γίνεται μία φορά και να ισχύει παντού, αντί να ξεχνιέται σε κάποιο αρχείο.
//
// Χρήση σε κάθε σελίδα: μετά το <script src=".../supabase.min.js"> και ΠΡΙΝ το δικό της <script>,
// πρόσθεσε: <script src="shared.js"></script>

const SUPABASE_URL = 'https://xxyrareqzgvsaolhftbh.supabase.co';
const SUPABASE_KEY = 'sb_publishable_x46jDuVbrSELrlekl5pQ7A_4i4xuaNE';

// Το όνομα του σύμβουλου εμφανίζεται στο dashboard κάθε οινοποιείου (είναι ο ίδιος σε όλα,
// σε αντίθεση με τον επόπτη που είναι διαφορετικός ανά οινοποιείο — αυτός ρυθμίζεται από
// τις Ρυθμίσεις ⚙️ στο admin.html). Άλλαξέ το εδώ αν χρειαστεί ποτέ.
const CONSULTANT_NAME = 'Απόστολος Γρηγορίου';

// Κοινό helper για σελίδες που δέχονται είτε πραγματικό Supabase login (ο σύμβουλος)
// είτε προσωπικό access code (εργαζόμενοι οινοποιείου, χωρίς email/password).
// Καλείται ως: const access = await requireAccess(supa, WINERY_ID);
// Επιστρέφει null (και κάνει redirect στο access.html) αν δεν υπάρχει έγκυρη πρόσβαση.
// Αλλιώς επιστρέφει { method:'auth'|'code', personName, wineryId }.
async function requireAccess(supa, wineryId) {
  // 1) Έλεγχος πραγματικού Supabase login (σύμβουλος)
  try {
    const { data: { session } } = await supa.auth.getSession();
    if (session && session.user) {
      if (wineryId) {
        const { data: membership } = await supa
          .from('memberships')
          .select('winery_id')
          .eq('user_id', session.user.id)
          .eq('winery_id', wineryId)
          .maybeSingle();
        if (membership) {
          return { method: 'auth', personName: session.user.email, wineryId };
        }
      } else {
        return { method: 'auth', personName: session.user.email, wineryId: null };
      }
    }
  } catch (e) {
    console.warn('requireAccess: auth session check failed', e);
  }

  // 2) Έλεγχος access code session (εργαζόμενος)
  try {
    const raw = sessionStorage.getItem('accessSession');
    if (raw) {
      const acc = JSON.parse(raw);
      if (acc && acc.wineryId && String(acc.wineryId) === String(wineryId)) {
        return { method: 'code', personName: acc.personName, wineryId: acc.wineryId };
      }
    }
  } catch (e) {
    console.warn('requireAccess: access code session check failed', e);
  }

  // 3) Καμία έγκυρη πρόσβαση — redirect στην ενιαία σελίδα σύνδεσης (login.html), η οποία
  // δέχεται είτε email+κωδικό (σύμβουλος) είτε προσωπικό κωδικό πρόσβασης (πελάτης/εργαζόμενος).
  const currentPage = window.location.pathname.split('/').pop();
  window.location.href = 'login.html?return=' + encodeURIComponent(currentPage);
  return null;
}

// ─── ΚΑΝΟΝΙΚΑ ΟΝΟΜΑΤΑ ΠΟΙΚΙΛΙΩΝ ───
// Πριν, αυτό το map + οι δύο συναρτήσεις ήταν αντιγραμμένα ξεχωριστά μέσα σε report.html,
// harvest.html και harvest-actual-entry.html — αν διόρθωνες ένα λάθος όνομα (π.χ. "Mattaro")
// μόνο σε ένα αρχείο, οι άλλες σελίδες συνέχιζαν να δείχνουν το λάθος. Τώρα υπάρχει ΕΝΑ σημείο.
//
// Προσθήκη νέας διόρθωσης: πρόσθεσε μια γραμμή στο VARIETY_NAME_FIX παρακάτω με το ΑΚΡΙΒΕΣ
// (ίδιο case/κενά) string όπως είναι αποθηκευμένο στη στήλη blocks.variety, π.χ.:
//   'Mattaro': 'Mataro',
const VARIETY_NAME_FIX = {
  'Moschato Fileri': 'Moschofilero',
  'Mattaro': 'Mataro',   // παλιό λάθος ορθογραφίας — σωστό είναι Mataro
  'Matarro': 'Mataro',
};

// Δέχεται το raw variety string ενός block όπως είναι αποθηκευμένο στη βάση, σε
// ΟΠΟΙΑΔΗΠΟΤΕ μορφή έχει χρησιμοποιηθεί ιστορικά:
//   "SRH — Syrah" (κωδικός + em-dash — η τρέχουσα σωστή μορφή από το dropdown του admin)
//   "SRH - Syrah" (κωδικός + απλή παύλα — παλιότερη χειροκίνητη καταχώρηση)
//   "Syrah"       (μόνο το όνομα, χωρίς κωδικό)
// και σε κάθε περίπτωση επιστρέφει το ΚΑΘΑΡΟ όνομα/ονόματα ποικιλίας, ώστε το ίδιο block να
// εμφανίζεται και να ομαδοποιείται πάντα με το ίδιο όνομα σε κάθε σελίδα (admin, reports,
// harvest, κλπ) — π.χ. "SRH — Syrah", "SRH - Syrah" και "Syrah" δίνουν όλα ['Syrah'].
function parseVarietyNames(varietyStr) {
  if (!varietyStr) return ['Άγνωστη ποικιλία'];
  // χωρίζει "κωδικός" από "όνομα" είτε υπάρχει em-dash (—), en-dash (–) είτε απλή παύλα (-)
  const parts = varietyStr.split(/\s*[—–-]\s*/);
  const namePart = (parts.length > 1 ? parts[parts.length - 1] : parts[0]).trim();
  return namePart.split('/')
    .map(s => s.trim())
    .map(s => VARIETY_NAME_FIX[s] || s)
    .filter(Boolean);
}

// Καθαρό, ενιαίο string για εμφάνιση (π.χ. "Yiannoudi / Xynisteri")
function displayVariety(varietyStr) {
  return parseVarietyNames(varietyStr).join(' / ');
}
