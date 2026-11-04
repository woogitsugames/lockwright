// Tool silhouettes for the "Przeswit" direction. Each tool = stroked card strips (w = strip width)
// + light cuts (knurling code: lines / dots / crosses / rings). Local frame: x 0..100, y around 0.
// Modes: 'own' (minium card lying in its light cut-out), 'locked' (perforated punch line, not cut yet),
//        'empty' (bright hole: the tool is missing).
const TOOL = {
  tw_angle: { name: 'Napinacz kątowy', en: 'Angle Tensioner', price: 0, opens: 'wkładki bębenkowe, płytkowe',
    s: [['M14 -16V8H96', 7]], cut: 'M40 6.5h6M54 6.5h6M68 6.5h6M82 6.5h6' , cw: 1.6 },
  pk_hook: { name: 'Haczyk', en: 'Hook Pick', price: 0, opens: 'bębenkowe, płytkowe, z listwą',
    s: [['M2 0H42', 11], ['M42 0H88L96 -12', 4.5]], cut: 'M10 -3v6M17 -3v6M24 -3v6M31 -3v6', cw: 1.8 },
  pk_peg: { name: 'Podważka kołkowa', en: 'Peg Lifter', price: 0, opens: 'zasuwy drewniane',
    s: [['M2 0H78', 13], ['M78 -2H92L98 -6', 6]], cut: 'M6 -2C22 -4 40 1 70 -2M10 3C30 2 46 5 66 3', cw: 1, wood: true },
  pk_ward: { name: 'Sonda przelotowa', en: 'Ward Probe', price: 80, opens: 'zamki zapadkowe',
    s: [['M14 0H86', 3.5], ['M86 2H98V14H86Z', 3.5]], ring: [8, 0, 6.5], cut: '', cw: 0 },
  pk_ripple: { name: 'Falownik', en: 'Ripple Pick', price: 350, opens: 'płytkowe; bębenkowe bez zabezpieczeń',
    s: [['M2 0H40', 11], ['M40 0H60C64 0 66 -8 70 -8S76 0 80 0S86 -8 90 -8S96 0 99 0', 4.5]],
    dots: [[10, 0], [18, 0], [26, 0], [34, 0]], cw: 0 },
  tl_shackle: { name: 'Ciągadło kabłąka', en: 'Shackle Puller', price: 150, opens: 'kłódki szyfrowe',
    s: [['M16 0H78C90 0 90 -16 78 -16H70', 5]], ring: [8, 0, 7], cut: '', cw: 0 },
  pk_lever: { name: 'Korba dźwigniowa', en: 'Lever Crank', price: 500, opens: 'zamki dźwigniowe',
    s: [['M6 10L52 -2L60 -14', 8], ['M10 -14L92 8L98 0', 3.5]], cut: 'M14 7l3 -1M22 5l3 -1M30 3l3 -1', cw: 1.6 },
  pk_wedge: { name: 'Klin dwustronny', en: 'Twin Wedge', price: 700, opens: 'płytkowe dwustronne',
    s: [['M2 0H40', 11], ['M40 0H84', 4.5], ['M84 0L91 -7L98 0L91 7Z', 4]], cross: [[12, 0], [24, 0], [34, 0]], cw: 0 },
  tw_bar: { name: 'Napinacz listwowy', en: 'Top Bar Tensioner', price: 600, opens: 'wąskie wkładki t5+',
    s: [['M4 0H84', 9], ['M84 0L98 -2', 4]], cross: [[16, 0], [30, 0], [44, 0], [58, 0]], cw: 0 },
};

function toolSVG(id, mode = 'own', k = 1) {
  const t = TOOL[id]; let o = '';
  const L = 'var(--light)', T = 'var(--tool)';
  const strips = (col, extra, dash) => t.s.map(([d, w]) =>
    `<path d="${d}" fill="none" stroke="${col}" stroke-width="${w + extra}" stroke-linecap="round" stroke-linejoin="round"${dash ? ` stroke-dasharray="${dash}"` : ''}/>`).join('') +
    (t.ring ? `<circle cx="${t.ring[0]}" cy="${t.ring[1]}" r="${t.ring[2]}" fill="none" stroke="${col}" stroke-width="${3.5 + extra}"${dash ? ` stroke-dasharray="${dash}"` : ''}/>` : '');
  if (mode === 'locked') return strips(L, -1, '1.6 2.6');
  o += strips(L, 4);                       // the cut-out slot (light gap around the card)
  if (mode === 'empty') return o;
  o += strips(T, 0);
  if (t.cut) o += `<path d="${t.cut}" fill="none" stroke="${L}" stroke-width="${t.cw}"/>`;
  if (t.dots) o += t.dots.map(([x, y]) => `<circle cx="${x}" cy="${y}" r="1.7" fill="${L}"/>`).join('');
  if (t.cross) o += t.cross.map(([x, y]) => `<path d="M${x-2.4} ${y-2.4}l4.8 4.8M${x+2.4} ${y-2.4}l-4.8 4.8" stroke="${L}" stroke-width="1.4"/>`).join('');
  return o;
}
// coin = punched washer (square hole). onDark swaps card and light.
const coinG = (onDark = false) => { const a = onDark ? 'var(--light)' : 'var(--ink)', b = onDark ? 'var(--ink)' : 'var(--light)';
  return `<circle cx="13" cy="13" r="11.5" fill="${a}"/><rect x="9.5" y="9.5" width="7" height="7" fill="${b}"/><path d="M13 2.5v3M13 20.5v3M2.5 13h3M20.5 13h3" stroke="${b}" stroke-width="1.2"/>`; };
const coinSVG = (s = 18, onDark = false) => `<svg viewBox="0 0 26 26" width="${s}" height="${s}">${coinG(onDark)}</svg>`;

// Wordmark: stencil caps with one continuous horizontal shear slit; the lower half sits 1 notch
// to the right (the plug has turned by one division = "set"). fg = letter colour, the slit stays background.
let _wm = 0;
function wordmark(size = 64, fg = 'var(--ink)', text = 'LOCKWRIGHT', track = .02, fit = 0) {
  const id = 'wm' + (_wm++), gap = Math.max(2, size * .07), cut = size * .44, sh = Math.max(1.5, size * .035);
  const t = (dx) => `<text x="${dx}" y="${size*.86}" font-family="Big Shoulders Stencil" font-weight="800" font-size="${size}" letter-spacing="${size*track}"${fit ? ` textLength="${fit}" lengthAdjust="spacingAndGlyphs"` : ''} fill="${fg}" style="font-variation-settings:'opsz' 72">${text}</text>`;
  return `<defs><clipPath id="${id}t"><rect x="-10" y="-10" width="9999" height="${cut + 10}"/></clipPath><clipPath id="${id}b"><rect x="-10" y="${cut + gap}" width="9999" height="${size}"/></clipPath></defs>` +
    `<g clip-path="url(#${id}t)">${t(0)}</g><g clip-path="url(#${id}b)">${t(sh)}</g>`;
}
// App icon (100x100): lightbox tile, cut cross-section, one pin set on the slit, minium tension wrench.
const ICON = `<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><rect width="100" height="100" fill="#FFF4D6"/>
<rect x="12" y="12" width="76" height="35" fill="#1D1A16"/><rect x="12" y="53" width="76" height="30" fill="#47371A"/>
<rect x="38" y="20" width="24" height="27" fill="#FFF4D6"/><rect x="38" y="53" width="24" height="17" fill="#FFF4D6"/>
<rect x="42" y="27" width="16" height="16" fill="#2B3236"/><rect x="40" y="42" width="20" height="5" fill="#1D1A16"/>
<path d="M42 57h16v9q0 6-8 6t-8-6z" fill="#47371A"/>
<rect x="12" y="74" width="62" height="6" fill="#FFF4D6"/>
<path d="M38 77H8V95" fill="none" stroke="#FFF4D6" stroke-width="10"/><path d="M38 77H8V95" fill="none" stroke="#C9532A" stroke-width="6.5"/></svg>`;
