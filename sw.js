// Vitis Vision — ελάχιστο service worker.
//
// Ο μοναδικός του σκοπός είναι να κάνει τη σελίδα "εγκαταστάσιμη" σαν εφαρμογή στο κινητό
// (Android/Chrome απαιτεί registered service worker με fetch handler για να δείξει το "Install"/
// "Προσθήκη στην αρχική οθόνη"). ΔΕΝ κάνει caching δεδομένων — τα reports είναι ζωντανά στοιχεία
// από το Supabase, δεν θέλουμε ποτέ να δείχνει παλιά/μπαγιάτικα δεδομένα επειδή έμειναν σε cache.
// Απλά αφήνει κάθε request να πάει κανονικά στο δίκτυο.

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request));
});
