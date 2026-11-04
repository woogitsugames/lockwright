// Renders every mockups/<direction>/*.html screen to PNG.
// Outputs: <direction>/png/<screen>.portrait.png (412x915 @2x),
//          <screen>.landscape.png (915x412 @2x),
//          <screen>.portrait.gray.png (grayscale, @1x),
//          <screen>.portrait.dim.png (50% brightness simulation, @1x).
// Usage: node tools/render.mjs [direction ...]
import { createRequire } from 'node:module';
import { readdirSync, mkdirSync, existsSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

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

const browser = await chromium.launch();
for (const dir of dirs) {
  const screens = readdirSync(join(root, dir)).filter(f => f.endsWith('.html'));
  if (!screens.length) continue;
  const out = join(root, dir, 'png');
  if (!existsSync(out)) mkdirSync(out);
  for (const v of variants) {
    const ctx = await browser.newContext({ viewport: { width: v.w, height: v.h }, deviceScaleFactor: v.dsf });
    const page = await ctx.newPage();
    for (const s of screens) {
      await page.goto(pathToFileURL(join(root, dir, s)).href);
      await page.evaluate(() => document.fonts.ready);
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
