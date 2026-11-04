// Plansza cechowa: shared SVG library (hatch patterns, knurls, tool silhouettes, family pictograms,
// lock miniatures, wordmark builder). Design mockup only, not game code.
// Material = hatching, procedurally defined here once; every screen references these ids.
(function () {
  const INK = '#1C1A17', PAPER = '#EFEBE1', DEEP = '#DED7C6', SOFT = '#57514A';
  const P = (id, w, h, body, bg = PAPER) =>
    `<pattern id="${id}" width="${w}" height="${h}" patternUnits="userSpaceOnUse"><rect width="${w}" height="${h}" fill="${bg}"/>${body}</pattern>`;
  const patterns = [
    // materials
    P('h-brass', 4, 4, `<path d="M0 2H4" stroke="${INK}" stroke-width=".55"/>`),
    P('h-steel', 4, 4, `<path d="M0 4L4 0M0 0L4 4" stroke="${INK}" stroke-width=".7"/>`),
    P('h-iron', 5, 5, `<path d="M0 5L5 0M-1 1L1 -1M4 6L6 4" stroke="${INK}" stroke-width="1.5"/><path d="M0 0L5 5" stroke="${INK}" stroke-width=".9"/>`),
    P('h-wood', 40, 10, `<path d="M0 3C10 1 20 5 40 3M0 8C14 6 26 10 40 8" fill="none" stroke="${INK}" stroke-width=".8"/>`),
    P('h-board', 12, 12, `<circle cx="6" cy="6" r="1.1" fill="${SOFT}"/>`, DEEP), // pegboard
    P('h-glass', 9, 9, `<path d="M0 9L9 0" stroke="${SOFT}" stroke-width=".5"/>`),
    // knurls: second channel on tool handles, independent of colour
    P('k-vlines', 3, 6, `<path d="M1.5 0V6" stroke="${INK}" stroke-width="1.1"/>`),
    P('k-slant', 4, 4, `<path d="M0 4L4 0M-1 1L1 -1M3 5L5 3" stroke="${INK}" stroke-width="1"/>`),
    P('k-dots', 4, 4, `<circle cx="2" cy="2" r=".95" fill="${INK}"/>`),
    P('k-cross', 5, 5, `<path d="M1 2.5H4M2.5 1V4" stroke="${INK}" stroke-width=".9"/>`),
    P('k-rings', 5, 10, `<path d="M1.5 0V10M3.5 0V10" stroke="${INK}" stroke-width=".6"/>`),
    P('k-chev', 6, 6, `<path d="M0 0L3 3L0 6M3 0L6 3L3 6" fill="none" stroke="${INK}" stroke-width=".8"/>`),
    P('k-diamond', 5, 5, `<path d="M0 5L5 0M0 0L5 5" stroke="${INK}" stroke-width="1.3"/>`),
  ];

  // Tools: viewBox 0 0 180 40, handle left, tip right. tip = where wear burrs go (x, y, direction).
  const S = (d, w) => `<path d="${d}" fill="none" stroke="${INK}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
  const H = (x, w, pat, rx = 3, y = 12, h = 16) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="url(#${pat})" stroke="${INK}" stroke-width="1.6"/>`;
  const TOOLS = {
    angle: { tip: [150, 21], svg: H(6, 52, 'k-vlines', 1) + S('M58 20H150V34', 5) },
    hook: { tip: [150, 20], svg: H(4, 54, 'k-slant', 7) + S('M58 20H150Q160 20 170 4', 3.4) },
    peg: { tip: [146, 18], svg: `<path d="M6 15H146L152 6H160V27H6Z" fill="url(#h-wood)" stroke="${INK}" stroke-width="1.6" stroke-linejoin="round"/>` },
    ward: { tip: [150, 20], svg: `<circle cx="17" cy="20" r="10" fill="none" stroke="${INK}" stroke-width="3"/>` + S('M27 20H160', 2.2) + `<rect x="156" y="20" width="14" height="13" fill="${INK}"/>` },
    shackle: { tip: [120, 12], svg: `<circle cx="15" cy="20" r="9" fill="none" stroke="${INK}" stroke-width="3.2"/>` + S('M24 20H40L50 10H158Q168 10 168 20Q168 30 158 30H128', 4) },
    ripple: { tip: [128, 20], svg: H(4, 54, 'k-dots', 7) + S('M58 20H128Q133 8 138 20Q143 8 148 20Q153 8 158 20H168', 3.2) },
    lever: { tip: [150, 14], svg: H(4, 46, 'k-chev', 2) + S('M50 22H112L130 12H170', 6) + S('M30 8L158 30', 2.2) + `<rect x="154" y="27" width="16" height="9" fill="${INK}"/>` },
    wedge: { tip: [148, 20], svg: H(4, 54, 'k-rings', 7) + S('M58 20H150', 3) + `<path d="M146 20L161 9L176 20L161 31Z" fill="${INK}"/>` },
    bar: { tip: [140, 20], svg: H(4, 54, 'k-cross', 1) + `<rect x="58" y="16" width="100" height="8" fill="${INK}"/><path d="M158 16L172 24V16L158 24Z" fill="${INK}" stroke="${INK}" stroke-width="1.5" stroke-linejoin="round"/>` },
    crown: { tip: [150, 14], svg: H(4, 46, 'k-diamond', 7) + `<rect x="50" y="13" width="112" height="14" fill="${PAPER}" stroke="${INK}" stroke-width="2.4"/><rect x="162" y="13" width="8" height="5" fill="${INK}"/><rect x="74" y="8" width="9" height="24" rx="2" fill="url(#h-steel)" stroke="${INK}" stroke-width="1.6"/>` },
  };

  // Family pictograms: 16x16, single stroke weight (Aicher-like), no colour.
  const st = `fill="none" stroke="${INK}" stroke-width="1.5" stroke-linejoin="round"`;
  const FAM = {
    wooden: `<rect x="1.5" y="7" width="13" height="5" ${st}/><path d="M5 2.5V7M8 2.5V7M11 2.5V7" ${st}/>`,
    warded: `<circle cx="8" cy="8" r="6.2" ${st}/><path d="M8 4.5A3.5 3.5 0 0 1 11.5 8" ${st}/><path d="M8 11.5A3.5 3.5 0 0 1 4.5 8" ${st}/>`,
    ring: `<rect x="3" y="1.5" width="10" height="3.5" rx="1.5" ${st}/><rect x="3" y="6.25" width="10" height="3.5" rx="1.5" ${st}/><rect x="3" y="11" width="10" height="3.5" rx="1.5" ${st}/>`,
    wafer: `<rect x="1.5" y="3" width="13" height="10" ${st}/><rect x="6" y="6" width="4" height="4" fill="${INK}"/>`,
    wafer2: `<rect x="1.5" y="3" width="13" height="10" ${st}/><rect x="3.5" y="5" width="3.5" height="2.5" fill="${INK}"/><rect x="9" y="8.5" width="3.5" height="2.5" fill="${INK}"/>`,
    pin: `<path d="M1.5 8H14.5" ${st}/><rect x="6" y="1.5" width="4" height="5" fill="${INK}"/><rect x="6" y="9.5" width="4" height="5" rx="1.5" ${st}/>`,
    lever: `<path d="M2 13V5.5Q8 2 14 5.5V13Z" ${st}/><rect x="7" y="4" width="2" height="4" fill="${INK}"/>`,
    levdet: `<path d="M2 14V7.5Q8 4 14 7.5V14Z" ${st}/><path d="M10 1.5V5.5H13" ${st}/><rect x="7" y="6" width="2" height="4" fill="${INK}"/>`,
    tubular: `<circle cx="8" cy="8" r="6.2" ${st}/>${[0, 60, 120, 180, 240, 300].map(a => `<circle cx="${(8 + 3.4 * Math.cos(a * Math.PI / 180)).toFixed(2)}" cy="${(8 + 3.4 * Math.sin(a * Math.PI / 180)).toFixed(2)}" r="1" fill="${INK}"/>`).join('')}`,
    sidebar: `<circle cx="7" cy="8" r="5.5" ${st}/><rect x="11.5" y="4.5" width="3" height="7" fill="${INK}"/>`,
    dimple: `<rect x="1.5" y="4" width="13" height="8" ${st}/><circle cx="5" cy="8" r="1.3" fill="${INK}"/><circle cx="8" cy="8" r="1.3" fill="${INK}"/><circle cx="11" cy="8" r="1.3" fill="${INK}"/>`,
  };

  // Lock miniatures for the showcase: 100x72, plate engraving language.
  const L = (d, f, w = 1.6) => `<path d="${d}" fill="${f}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round"/>`;
  const MINI = {
    khorsabad: L('M8 32H92V46H8Z', 'url(#h-wood)') + L('M34 10H62V56H34Z', 'url(#h-wood)') + S('M41 14V36M48 14V38M55 14V36', 2.2) + L('M86 30h8v18h-8z', PAPER),
    ringkey: `<circle cx="36" cy="44" r="15" fill="none" stroke="${INK}" stroke-width="5"/>` + L('M46 30h26v10H66v6h-4v-6h-4v8h-4v-8h-8z', 'url(#h-brass)'),
    amen: S('M34 30V18Q34 6 50 6Q66 6 66 18V30', 4) + L('M22 30H78V64H22Z', 'url(#h-brass)') +
      [0, 1, 2, 3].map(i => `<rect x="${24 + i * 13.5}" y="33" width="12" height="28" fill="${PAPER}" stroke="${INK}" stroke-width="1.2"/><text x="${30 + i * 13.5}" y="51" font-family="'Brygada 1918'" font-weight="700" font-size="11" text-anchor="middle" fill="${INK}">${'AMEN'[i]}</text>`).join(''),
    barron: L('M14 56V26Q50 8 86 26V56Z', 'url(#h-brass)') + L('M44 22h12v14H44z', PAPER) + L('M4 40H40V48H4Z', 'url(#h-iron)') + L('M58 30h-12', 'none'),
    chubb: L('M14 60V32Q50 14 86 32V60Z', 'url(#h-brass)') + L('M44 28h12v14H44z', PAPER) + S('M70 4V18H84', 3) + L('M4 44H40V52H4Z', 'url(#h-iron)'),
    bramah: S('M36 30V20Q36 8 50 8Q64 8 64 20V30', 4) + `<circle cx="50" cy="48" r="20" fill="url(#h-brass)" stroke="${INK}" stroke-width="1.8"/><circle cx="50" cy="48" r="7" fill="${PAPER}" stroke="${INK}" stroke-width="1.6"/><circle cx="50" cy="48" r="2.5" fill="${INK}"/>`,
    sealed: L('M10 14H90V64H10Z', 'url(#h-wood)') + `<rect x="30" y="22" width="40" height="34" fill="${PAPER}" stroke="${INK}" stroke-width="1.2" stroke-dasharray="3 2"/>` + S('M42 32V28Q42 24 50 24Q58 24 58 28V32', 2) + `<circle cx="50" cy="42" r="8" fill="none" stroke="${INK}" stroke-width="1.4"/>` + `<path d="M71 66l-3 6M74 67l1 6" stroke="${INK}" stroke-width="1.4"/><path d="M80 51l2.6 2.2 3.4-.4.6 3.4 2.8 2-1.4 3.1 1.4 3.1-2.8 2-.6 3.4-3.4-.4L80 71l-2.6-2.2-3.4.4-.6-3.4-2.8-2 1.4-3.1-1.4-3.1 2.8-2 .6-3.4 3.4.4z" fill="${INK}"/><circle cx="80" cy="61" r="4.5" fill="none" stroke="${PAPER}" stroke-width="1.2"/>` + S('M10 60Q40 66 72 60', 1),
    stansbury: L('M8 8H92V38H8Z', 'url(#h-iron)') + L('M8 41H92V64H8Z', 'url(#h-brass)') +
      [24, 46, 68].map((x, i) => `<rect x="${x}" y="12" width="12" height="${14 + i * 2}" fill="url(#h-steel)" stroke="${INK}" stroke-width="1.3"/><rect x="${x}" y="${41}" width="12" height="${14 - i * 3}" rx="3" fill="${PAPER}" stroke="${INK}" stroke-width="1.3"/>`).join('') +
      `<path d="M8 39.5H92" stroke="${PAPER}" stroke-width="3"/>`,
  };

  const sym = (id, vb, body) => `<symbol id="${id}" viewBox="${vb}" overflow="visible">${body}</symbol>`;
  const filters = `
    <filter id="shadow-paint" x="-10%" y="-40%" width="120%" height="180%">
      <feMorphology in="SourceAlpha" operator="dilate" radius="4" result="o"/>
      <feMorphology in="SourceAlpha" operator="dilate" radius="2.6" result="i"/>
      <feComposite in="o" in2="i" operator="out" result="ring"/>
      <feFlood flood-color="${PAPER}"/><feComposite in2="i" operator="in" result="fill"/>
      <feFlood flood-color="${SOFT}"/><feComposite in2="ring" operator="in" result="edge"/>
      <feMerge><feMergeNode in="fill"/><feMergeNode in="edge"/></feMerge>
    </filter>
    <filter id="shadow-outline" x="-10%" y="-40%" width="120%" height="180%">
      <feMorphology in="SourceAlpha" operator="dilate" radius="4" result="o"/>
      <feMorphology in="SourceAlpha" operator="dilate" radius="2.8" result="i"/>
      <feComposite in="o" in2="i" operator="out" result="ring"/>
      <feFlood flood-color="${SOFT}"/><feComposite in2="ring" operator="in"/>
    </filter>`;
  const lib = `<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>${patterns.join('')}${filters}
    ${Object.entries(TOOLS).map(([k, t]) => sym('t-' + k, '0 0 180 40', t.svg)).join('')}
    ${Object.entries(FAM).map(([k, s]) => sym('f-' + k, '0 0 16 16', s)).join('')}
    ${Object.entries(MINI).map(([k, s]) => sym('m-' + k, '0 0 100 72', s)).join('')}
    <symbol id="coin" viewBox="0 0 24 24"><g fill="none" stroke="#8A5A14" stroke-width="1.6"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="9.5" r="2.6"/><path d="M12 12v6M12 15.5h2.5"/></g></symbol>
  </defs></svg>`;
  document.body.insertAdjacentHTML('afterbegin', lib);

  // Burrs (wear 0..4): small notches on the shaft next to the tip.
  const burrs = (key, n, scale = 1) => {
    const [x, y] = TOOLS[key].tip; let d = '';
    for (let i = 0; i < n; i++) { const bx = x - 4 - i * 7; d += `M${bx} ${y - 2}l2.5 -5.5l2.5 5.5`; }
    return n ? `<path d="${d}" fill="none" stroke="${INK}" stroke-width="${1.6 / scale}" stroke-linejoin="miter"/>` : '';
  };

  // Wordmark: Brygada 1918 Bold cut along a shear line; the lower half slides as if the plug turned.
  // The tittle of the i is a driver pin. Returns an <svg> string. Needs fonts loaded.
  function wordmark({ shift = 0.05, color = INK, bg = PAPER, rules = true } = {}) {
    const fs = 100, probe = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    probe.setAttribute('style', 'position:absolute;visibility:hidden');
    probe.innerHTML = `<text font-family="'Brygada 1918'" font-weight="700" font-size="${fs}" letter-spacing="-1">Lockwrıght</text>`;
    document.body.appendChild(probe);
    const t = probe.firstChild, w = t.getComputedTextLength(), ex = t.getExtentOfChar(6);
    const ex7 = t.getExtentOfChar(7);
    probe.remove();
    const base = 112, cut = base - 30, gap = 4, sx = shift * fs, pad = 26;
    const W = w + sx + pad * 2, Hh = 140, x0 = pad;
    const ix = x0 + ex.x + ex.width / 2 - 1; // stem centre of dotless i (approx.)
    const txt = `<text x="${x0}" y="${base}" font-family="'Brygada 1918'" font-weight="700" font-size="${fs}" letter-spacing="-1" fill="${color}">Lockwrıght</text>`;
    const uid = 'wm' + Math.random().toString(36).slice(2, 7);
    const pin = `<rect x="${ix - 6.5}" y="${base - 86}" width="13" height="25" rx="1.5" fill="${color}"/>`;
    const rl = rules ? `<path d="M2 ${cut - gap / 2 - .8}H${x0 - 6}M2 ${cut + gap / 2 + .8}H${x0 - 6 + sx}M${W - pad + 8} ${cut - gap / 2 - .8}H${W - 2}M${W - pad + 8} ${cut + gap / 2 + .8}H${W - 2}" stroke="${color}" stroke-width="1.6"/>` : '';
    return `<svg viewBox="0 0 ${W.toFixed(1)} ${Hh}" class="wordmark" role="img" aria-label="Lockwright">
      <defs><clipPath id="${uid}t"><rect x="0" y="0" width="${W}" height="${cut - gap / 2}"/></clipPath>
      <clipPath id="${uid}b"><rect x="-20" y="${cut + gap / 2}" width="${W + 40}" height="${Hh}"/></clipPath></defs>
      <g clip-path="url(#${uid}t)">${txt}${pin}</g>
      <g clip-path="url(#${uid}b)"><g transform="translate(${sx} 0)">${txt}</g></g>
      ${rl}</svg>`;
  }

  // App icon: one chamber at the moment of "set", the pick (vermilion) lifting from below. 100x100, self-contained.
  function icon(id = 'ic', small = false) {
    const pat = `<pattern id="${id}-iron" width="7" height="7" patternUnits="userSpaceOnUse"><rect width="7" height="7" fill="${PAPER}"/><path d="M0 7L7 0M-1 1L1 -1M6 8L8 6M0 0L7 7" stroke="${INK}" stroke-width="2.2"/></pattern>
      <pattern id="${id}-brass" width="6" height="6" patternUnits="userSpaceOnUse"><rect width="6" height="6" fill="${PAPER}"/><path d="M0 3H6" stroke="${INK}" stroke-width="1.6"/></pattern>`;
    return `<svg viewBox="0 0 100 100" role="img" aria-label="Lockwright"><defs>${pat}</defs>
      <rect width="100" height="100" fill="${PAPER}"/>
      <path d="M0 10H100V50H0Z" fill="url(#${id}-iron)"/>
      <path d="M0 50H100" stroke="${INK}" stroke-width="2"/>
      <path d="M6 54H100V84H6Z" fill="url(#${id}-brass)" stroke="${INK}" stroke-width="2"/>
      <path d="M0 54H100" stroke="${INK}" stroke-width="2"/>
      <rect x="36" y="10" width="28" height="40" fill="${PAPER}" stroke="${INK}" stroke-width="2.4"/>
      <rect x="40" y="54" width="28" height="30" fill="${PAPER}" stroke="${INK}" stroke-width="2.4"/>
      ${small ? '' : `<path d="M40 15h20M40 21h20M40 27h20" stroke="${INK}" stroke-width="2.4"/>`}
      <rect x="38.5" y="31" width="23" height="19" fill="${INK}"/>
      <path d="M44 54h20v14c0 5-5 8-10 8s-10-3-10-8z" fill="${PAPER}" stroke="${INK}" stroke-width="2.6"/>
      <path d="M-4 95C30 94 46 90 54 76" fill="none" stroke="#B3311D" stroke-width="6.5" stroke-linecap="round"/>
      <rect x="3" y="3" width="94" height="94" fill="none" stroke="${INK}" stroke-width="2.4"/>
    </svg>`;
  }

  window.Plansza = { TOOLS, FAM, burrs, wordmark, icon, INK, PAPER, DEEP, SOFT };
})();
