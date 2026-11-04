// Builds compare/contact.png: rows = directions, columns = screens (portrait), plus a grayscale lock column.
import { createRequire } from 'node:module';
import { readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const require = createRequire(import.meta.url);
let chromium; try { ({ chromium } = require('playwright')); } catch { ({ chromium } = require('/opt/node-tools/node_modules/playwright')); }
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dirs = [['plansza', 'Plansza cechowa · ilustracyjny (rycina)'], ['przeswit', 'Prześwit · graficzny (wycinanka pod lampą)'], ['klatka', 'Klatka schodowa · realistyczny (three.js)'], ['sodowa', 'Sodowa noc · ilustracyjny (linoryt / riso)']];
const rows = dirs.map(([d, label]) => {
  const files = readdirSync(join(root, d, 'png')).filter(f => f.endsWith('.portrait.png')).sort();
  const imgs = files.map(f => `<img src="../${d}/png/${f}">`).join('') + `<img src="../${d}/png/01-lock.portrait.gray.png">`;
  return `<section><h2>${label}</h2><div class="r">${imgs}</div></section>`;
}).join('');
const html = `<!doctype html><meta charset="utf-8"><link rel="stylesheet" href="../shared/fonts.css"><style>html,body{overflow:visible;height:auto}body{background:#ecebe7;padding:24px;font:600 22px "Atkinson Hyperlegible Next"}h2{margin:18px 0 10px}.r{display:flex;gap:14px}.r img{width:206px;height:457px;object-fit:cover;object-position:top;border:1px solid #999}</style>${rows}`;
writeFileSync(join(root, 'compare', 'contact.html'), html);
const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1340, height: 900 } });
await p.goto(pathToFileURL(join(root, 'compare', 'contact.html')).href); await p.waitForTimeout(500);
await p.screenshot({ path: join(root, 'compare', 'contact.png'), fullPage: true }); await b.close(); console.log('ok');
