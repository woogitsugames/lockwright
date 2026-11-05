// Renders every UI direction to PNG: mockups/ui-directions/out/<dir>/<screen>.<orient>.png (@2x)
// plus grayscale checks in out/<dir>/gray/. Then builds out/compare.png.
// Usage: node mockups/ui-directions/render.mjs [dir ...]
import { createRequire } from 'node:module';
import { readdirSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { join, dirname, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); } catch { ({ chromium } = require('/opt/node-tools/node_modules/playwright')); }

const root = dirname(fileURLToPath(import.meta.url));
const only = process.argv.slice(2);
const dirs = readdirSync(root, { withFileTypes: true })
  .filter(d => d.isDirectory() && /^\d-/.test(d.name)).map(d => d.name)
  .filter(d => !only.length || only.some(o => d.startsWith(o)));
const shots = [
  { s: 'menu', o: 'portrait', w: 412, h: 915 },
  { s: 'jobs', o: 'portrait', w: 412, h: 915 },
  { s: 'settings', o: 'portrait', w: 412, h: 915 },
  { s: 'menu', o: 'landscape', w: 915, h: 412 },
];
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.ttf': 'font/ttf', '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg' };
const repo = join(root, '..', '..');
const server = createServer((req, res) => {
  const f = join(repo, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  try { if (!statSync(f).isFile()) throw 0; res.writeHead(200, { 'content-type': types[extname(f)] || 'application/octet-stream' }); res.end(readFileSync(f)); }
  catch { res.writeHead(404); res.end(); }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const base = `http://127.0.0.1:${server.address().port}/mockups/ui-directions`;
const browser = await chromium.launch();
for (const dir of dirs) {
  const out = join(root, 'out', dir); mkdirSync(join(out, 'gray'), { recursive: true });
  for (const v of shots) {
    for (const gray of [false, true]) {
      const ctx = await browser.newContext({ viewport: { width: v.w, height: v.h }, deviceScaleFactor: gray ? 1 : 2 });
      const page = await ctx.newPage();
      page.on('pageerror', e => console.error(dir, v.s, e.message));
      await page.goto(`${base}/${dir}/index.html?s=${v.s}`);
      await page.evaluate(() => document.fonts.ready);
      await page.waitForFunction(() => window.__ready !== false, null, { timeout: 30000 });
      if (gray) await page.addStyleTag({ content: 'html{filter:grayscale(1)}' });
      await page.waitForTimeout(120);
      await page.screenshot({ path: join(out, gray ? 'gray' : '', `${v.s}.${v.o}.png`) });
      await ctx.close();
    }
    console.log('rendered', dir, v.s, v.o);
  }
}
// Comparison sheet: 4 directions as rows, 3 portrait screens each.
const all = readdirSync(root, { withFileTypes: true }).filter(d => d.isDirectory() && /^\d-/.test(d.name)).map(d => d.name).sort();
const meta = all.map(d => { try { return { d, label: readFileSync(join(root, d, 'LABEL'), 'utf8').trim() }; } catch { return { d, label: d }; } });
const html = `<!doctype html><meta charset=utf-8><link rel=stylesheet href="${base}/fonts.css"><style>
body{background:#e9e7e2;font-family:"Schibsted Grotesk";color:#1b1a18;padding:40px;width:${40 * 2 + 3 * 412 + 2 * 24 + 260}px;overflow:visible;height:auto}
.row{display:flex;gap:24px;margin-bottom:40px;align-items:flex-start}
.lab{width:236px;flex:none}
.lab b{display:block;font-size:44px;font-weight:800;line-height:1}
.lab span{display:block;font-size:20px;font-weight:600;margin-top:8px;line-height:1.2}
.lab small{display:block;font-size:14px;margin-top:12px;color:#4a4740;line-height:1.35}
figure{width:412px}figure img{width:412px;height:915px;display:block;outline:1px solid #b9b5ad}
figcaption{font-size:14px;margin-top:6px;color:#4a4740}
h1{font-size:28px;margin-bottom:28px;font-weight:800}
</style><h1>Lockwright — 4 kierunki UI menu (412×915)</h1>
${meta.map((m, i) => `<div class=row><div class=lab><b>${i + 1}</b><span>${m.label.split('\n')[0]}</span><small>${m.label.split('\n').slice(1).join('<br>')}</small></div>
${['menu', 'jobs', 'settings'].map(s => `<figure><img src="${base}/out/${m.d}/${s}.portrait.png"><figcaption>${{ menu: 'Menu główne', jobs: 'Zlecenia', settings: 'Ustawienia' }[s]}</figcaption></figure>`).join('')}</div>`).join('')}`;
writeFileSync(join(root, 'out', '_compare.html'), html);
const ctx = await browser.newContext({ viewport: { width: 1600, height: 900 }, deviceScaleFactor: 1 });
const page = await ctx.newPage();
await page.goto(`${base}/out/_compare.html`);
await page.evaluate(() => document.fonts.ready); await page.waitForTimeout(300);
await page.screenshot({ path: join(root, 'out', 'compare.png'), fullPage: true });
await browser.close(); server.close();
console.log('compare.png done');
