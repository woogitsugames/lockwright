// Renders every mockups/<direction>/*.html screen to PNG.
// Outputs: <direction>/png/<screen>.portrait.png (412x915 @2x),
//          <screen>.landscape.png (915x412 @2x),
//          <screen>.portrait.gray.png (grayscale, @1x),
//          <screen>.portrait.dim.png (50% brightness simulation, @1x).
// Usage: node tools/render.mjs [direction ...]
import { createRequire } from 'node:module';
import { readdirSync, mkdirSync, existsSync, readFileSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname } from 'node:path';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

// Prefer local devDependency; fall back to the preinstalled global Playwright.
const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); } catch { ({ chromium } = require('/opt/node-tools/node_modules/playwright')); }

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const only = process.argv.slice(2);
const dirs = readdirSync(root, { withFileTypes: true })
  .filter(d => d.isDirectory() && !['tools', 'fonts', 'node_modules', 'shared'].includes(d.name))
  .map(d => d.name)
  .filter(d => only.length === 0 || only.includes(d));

const variants = [
  { suffix: 'portrait', w: 412, h: 915, dsf: 2, filter: null },
  { suffix: 'landscape', w: 915, h: 412, dsf: 2, filter: null },
  { suffix: 'portrait.gray', w: 412, h: 915, dsf: 1, filter: 'grayscale(1)' },
  { suffix: 'portrait.dim', w: 412, h: 915, dsf: 1, filter: 'grayscale(1) brightness(0.5)' },
];

// Static server so ES modules (three.js) load; file:// blocks module scripts.
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.ttf': 'font/ttf', '.svg': 'image/svg+xml', '.png': 'image/png', '.json': 'application/json' };
const server = createServer((req, res) => {
  const f = join(root, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  try { if (!statSync(f).isFile()) throw 0; res.writeHead(200, { 'content-type': types[extname(f)] || 'application/octet-stream' }); res.end(readFileSync(f)); }
  catch { res.writeHead(404); res.end(); }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const base = `http://127.0.0.1:${server.address().port}`;

const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
for (const dir of dirs) {
  const screens = readdirSync(join(root, dir)).filter(f => f.endsWith('.html'));
  if (!screens.length) continue;
  const out = join(root, dir, 'png');
  if (!existsSync(out)) mkdirSync(out);
  for (const v of variants) {
    const ctx = await browser.newContext({ viewport: { width: v.w, height: v.h }, deviceScaleFactor: v.dsf });
    const page = await ctx.newPage();
    for (const s of screens) {
      await page.goto(`${base}/${dir}/${s}`);
      await page.evaluate(() => document.fonts.ready);
      // Pages that render asynchronously (WebGL) set window.__ready=false, then true when done.
      await page.waitForFunction(() => window.__ready !== false, null, { timeout: 60000 });
      if (v.filter) await page.addStyleTag({ content: `html{filter:${v.filter}}` });
      await page.waitForTimeout(150);
      const file = join(out, `${basename(s, '.html')}.${v.suffix}.png`);
      await page.screenshot({ path: file });
      console.log('rendered', file.replace(root + '/', ''));
    }
    await ctx.close();
  }
}
await browser.close();
server.close();
