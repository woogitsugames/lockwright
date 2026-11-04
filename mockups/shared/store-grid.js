// Generic archetypes of competitor store icons (drawn from scratch to represent the clichés
// found in docs/research/ART.md; NOT copies of any real icon). Used to compare our icon in context.
// Usage: <div id="store" data-ours="<svg ...>" data-name="Lockwright"></div><script src="../shared/store-grid.js"></script>
const ARCHETYPES = [
  { name: 'Lock Master 3D', svg: `<svg viewBox="0 0 100 100"><defs><radialGradient id="g1"><stop offset="0" stop-color="#3a3a3a"/><stop offset="1" stop-color="#0b0b0b"/></radialGradient><linearGradient id="au" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset="1" stop-color="#b8860b"/></linearGradient></defs><rect width="100" height="100" fill="url(#g1)"/><path d="M34 46V34a16 16 0 0 1 32 0v12" fill="none" stroke="url(#au)" stroke-width="8"/><rect x="24" y="44" width="52" height="40" rx="6" fill="url(#au)"/><circle cx="50" cy="62" r="5" fill="#3a2a00"/></svg>` },
  { name: 'Safe Cracker', svg: `<svg viewBox="0 0 100 100"><rect width="100" height="100" fill="#20242c"/><circle cx="50" cy="50" r="34" fill="#9aa3ad" stroke="#e5e9ee" stroke-width="4"/><circle cx="50" cy="50" r="16" fill="#5b636d"/><g stroke="#20242c" stroke-width="2">${Array.from({length:12},(_,i)=>`<path d="M50 18v8" transform="rotate(${i*30} 50 50)"/>`).join('')}</g></svg>` },
  { name: 'Unlock Puzzle!', svg: `<svg viewBox="0 0 100 100"><defs><linearGradient id="pv" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7b3fe4"/><stop offset="1" stop-color="#2a7fff"/></linearGradient></defs><rect width="100" height="100" fill="url(#pv)"/><circle cx="50" cy="42" r="14" fill="#fff"/><path d="M44 52h12l4 28H40z" fill="#fff"/></svg>` },
  { name: 'Pick Lock Sim', svg: `<svg viewBox="0 0 100 100"><rect width="100" height="100" fill="#0e1a2b"/><g fill="#f5b638">${[22,38,54,70].map((x,i)=>`<rect x="${x}" y="${30+i*6}" width="10" height="${30-i*4}" rx="3"/>`).join('')}</g><rect x="14" y="66" width="72" height="6" fill="#8fa3bd"/><path d="M10 80h50l10-8" stroke="#d9dee6" stroke-width="4" fill="none"/></svg>` },
  { name: 'Key Escape', svg: `<svg viewBox="0 0 100 100"><rect width="100" height="100" fill="#14110d"/><circle cx="36" cy="50" r="14" fill="none" stroke="#e8b04a" stroke-width="7"/><path d="M50 50h34M72 50v10M80 50v8" stroke="#e8b04a" stroke-width="7"/></svg>` },
];
(function () {
  const el = document.getElementById('store');
  const ours = { name: el.dataset.name || 'Lockwright', svg: el.dataset.ours, ours: true };
  const list = [ARCHETYPES[0], ARCHETYPES[1], ours, ARCHETYPES[2], ARCHETYPES[3], ARCHETYPES[4]];
  el.innerHTML = list.map(a => `<figure class="si${a.ours ? ' ours' : ''}"><div class="si-icon">${a.svg}</div><figcaption>${a.name}</figcaption></figure>`).join('');
  const css = document.createElement('style');
  css.textContent = `#store{display:grid;grid-template-columns:repeat(3,1fr);gap:18px 14px;padding:16px;background:#fbfbfa;border-radius:4px}
  .si{display:flex;flex-direction:column;align-items:center;gap:6px}
  .si-icon{width:72px;height:72px;border-radius:16px;overflow:hidden;box-shadow:0 0 0 .5px rgba(0,0,0,.18)}
  .si-icon svg{width:100%;height:100%;display:block}
  .si figcaption{font:12px/1.2 -apple-system,"Lato",sans-serif;color:#222;text-align:center}`;
  document.head.appendChild(css);
})();
