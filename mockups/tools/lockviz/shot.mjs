// Screenshots lockviz with Playwright.
// Usage: node mockups/tools/lockviz/shot.mjs [trace-name] [frame|end] [out.png]
// Default: pin_tumbler_t5_s1_clumsy at frame 1700 -> mockups/tools/lockviz/shot.png
import { createRequire } from 'node:module';
import { readFileSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); } catch { ({ chromium } = require('/opt/node-tools/node_modules/playwright')); }

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..', '..', '..');
const [name = 'pin_tumbler_t5_s1_clumsy', frame = '1700', out = join(here, 'shot.png')] = process.argv.slice(2);

// Serve the repo root so the page can also fetch lockcore/tests/golden/*.replay.json.
const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.ttf': 'font/ttf' };
const server = createServer((req, res) => {
  const f = join(repo, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  try { if (!statSync(f).isFile()) throw 0; res.writeHead(200, { 'content-type': types[extname(f)] || 'application/octet-stream' }); res.end(readFileSync(f)); }
  catch { res.writeHead(404); res.end(); }
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const port = server.address().port;
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });
page.on('pageerror', (e) => console.error('pageerror:', e.message));
await page.goto(`http://127.0.0.1:${port}/mockups/tools/lockviz/index.html?trace=${name}&t=${frame}`);
await page.waitForSelector('body[data-ready="1"]');
await page.screenshot({ path: out, fullPage: true });
await browser.close();
server.close();
console.log(out);
