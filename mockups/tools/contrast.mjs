// WCAG contrast + simple CVD (Machado 2009, severity 1.0) check for palette pairs.
// Usage: node tools/contrast.mjs <direction>/palette.json
// palette.json: { "colors": {"name": "#rrggbb"}, "pairs": [["fg","bg","text|graphic"]] }
import { readFileSync } from 'node:fs';

const hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16) / 255);
const lin = c => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
const unlin = c => (c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055);
const lum = rgb => { const [r, g, b] = rgb.map(lin); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
const M = {
  protan: [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
  deutan: [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
  tritan: [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
};
const sim = (rgb, m) => { const l = rgb.map(lin); return m.map(r => unlin(Math.min(1, Math.max(0, r[0] * l[0] + r[1] * l[1] + r[2] * l[2])))); };

const p = JSON.parse(readFileSync(process.argv[2], 'utf8'));
let fail = 0;
console.log('fg'.padEnd(16), 'bg'.padEnd(16), 'use'.padEnd(8), 'ratio', ' protan deutan tritan  ok');
for (const [fg, bg, use] of p.pairs) {
  const a = hex(p.colors[fg]), b = hex(p.colors[bg]);
  const need = use === 'text' ? 4.5 : use === 'large' ? 3 : 3;
  const r = ratio(a, b);
  const cvd = Object.values(M).map(m => ratio(sim(a, m), sim(b, m)));
  const ok = r >= need && cvd.every(c => c >= need);
  if (!ok) fail++;
  console.log(fg.padEnd(16), bg.padEnd(16), use.padEnd(8), r.toFixed(2).padStart(5), cvd.map(c => c.toFixed(2).padStart(6)).join(' '), ok ? ' ✓' : ' FAIL');
}
process.exit(fail ? 1 : 0);
