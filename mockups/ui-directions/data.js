// Sample content for the UI direction mockups (PL). In the game these come from i18n (game/i18n/content.csv).
window.LW = {
  title: 'Lockwright', subtitle: 'Pogotowie Zamkowe',
  menu: [
    { id: 'start', label: 'Zacznij dyżur', primary: true },
    { id: 'jobs', label: 'Zlecenia' },
    { id: 'workshop', label: 'Warsztat' },
    { id: 'showcase', label: 'Gablota' },
    { id: 'settings', label: 'Ustawienia' },
    { id: 'about', label: 'O grze' },
  ],
  // state: done | open | new
  jobs: [
    { no: '0007', title: 'Rozmowa o 9:30', who: 'Kuba, 23 l.', what: 'kłódka rowerowa', where: 'ul. Kolejowa, przy stojaku', time: '8:41', pay: '120 zł', state: 'done' },
    { no: '0008', title: 'Ziemniak w łazience', who: 'Marta, 34 l.', what: 'zatrzask w łazience', where: 'ul. Długa 7 m. 4', time: '11:05', pay: '90 zł', state: 'done' },
    { no: '0009', title: 'Rosół na gazie', who: 'pani Halina', what: 'drzwi wejściowe', where: 'ul. Ogrodowa 12 m. 9', time: '13:20', pay: '150 zł', state: 'done' },
    { no: '0010', title: 'Kiosk przed szóstą', who: 'pan Stefan, 67 l.', what: 'kłódka przy rolecie', where: 'przystanek Rynek', time: '5:28', pay: '110 zł', state: 'done' },
    { no: '0011', title: 'Pokój 412', who: 'Ola, 20 l.', what: 'drzwi w akademiku', where: 'DS 3, IV piętro', time: '23:10', pay: '80 zł', state: 'open' },
    { no: '0012', title: 'Pałki w szafce', who: 'Edek, 41 l.', what: 'szafka w sali prób', where: 'Dom Kultury, piwnica', time: '19:45', pay: '70 zł', state: 'open' },
    { no: '0013', title: 'Piętro niżej', who: 'pan Roman', what: 'drzwi wejściowe', where: 'ul. Słowików 3 m. 6', time: '21:30', pay: '?', state: 'new' },
    { no: '0014', title: '„Siostra kazała”', who: 'nieznany', what: 'mieszkanie siostry', where: 'ul. Polna 18 m. 2', time: '2:15', pay: '?', state: 'new' },
  ],
  settings: {
    haptics: true, intensity: 100, master: 100, sfx: 100, ambient: 80, autoTension: false, lang: 'Polski',
  },
};
// ?s=menu|jobs|settings ; layout orientation comes from the viewport (media queries).
window.LW.screen = new URLSearchParams(location.search).get('s') || 'menu';
// Small seeded RNG so procedural jitter is identical on every render.
window.LW.rng = function (seed) { let s = seed >>> 0 || 1; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); };
