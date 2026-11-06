// Tests for the lockviz v0.6 family schematics (D-59).
// Run: cd mockups && npm install && node --test tools/lockviz/test/
// - consistency: traces/index.json <-> trace files <-> schema
// - geometry unit tests for the pure helpers in families_v06.js
// - viewer smoke test (Playwright): every indexed trace renders at frame 0 / mid / end
//   without pageerror, with data-ready="1" and the expected data-schematic
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); } catch { ({ chromium } = require('/opt/node-tools/node_modules/playwright')); }

const here = dirname(fileURLToPath(import.meta.url));
const lockvizDir = join(here, '..');
const repo = join(lockvizDir, '..', '..', '..');
const tracesDir = join(lockvizDir, 'traces');

const indexNames = JSON.parse(readFileSync(join(tracesDir, 'index.json'), 'utf8'));

const EXPECTED_SCHEMATIC = {
  dial_safe: 'drawDialSafe', combo: 'drawCombo', dimple: 'drawDimple', disc_detainer: 'drawDiscs',
  egyptian: 'drawEgyptian', axial_slider: 'drawSliders', time_lock: 'drawTimeLock', magnetic: 'drawMagnetic',
  ring_combo: 'drawRings', warded: 'drawWarded', lever: 'drawLevers', lever_detector: 'drawLevers',
  pin_tumbler: 'drawLift', wafer: 'drawLift', wooden_pin: 'drawLift',
};
const V06_FAMILIES = ['dial_safe', 'combo', 'dimple', 'disc_detainer', 'egyptian', 'axial_slider', 'time_lock', 'magnetic'];

function traceInfo(name) {
  const t = JSON.parse(readFileSync(join(tracesDir, name + '.trace.json'), 'utf8'));
  return t;
}

test('index.json matches the trace files and every trace is lockwright.trace/1', () => {
  const onDisk = readdirSync(tracesDir).filter((f) => f.endsWith('.trace.json')).map((f) => f.slice(0, -'.trace.json'.length)).sort();
  assert.deepEqual([...indexNames].sort(), onDisk, 'index.json <-> traces/*.trace.json');
  assert.deepEqual(indexNames, [...indexNames].sort(), 'index.json is sorted');
  for (const name of indexNames) {
    const t = traceInfo(name);
    assert.equal(t.schema, 'lockwright.trace/1', name);
    assert.ok(t.frames.length > 0 && Array.isArray(t.elements) && t.element_states.includes('free'), name);
    assert.ok(EXPECTED_SCHEMATIC[t.family], `known family ${t.family} (${name})`);
  }
});

test('geometry helpers (LOCKVIZ_GEOM)', async () => {
  await import('../families_v06.js');
  const G = globalThis.LOCKVIZ_GEOM;
  assert.ok(G && globalThis.FAMILY_DRAW_V06, 'families_v06.js exposes globals');
  assert.equal(G.wrap01(-0.25), 0.75);
  assert.equal(G.wrap01(1.25), 0.25);
  assert.equal(G.gateCenter(0, 65536), 0.5);
  assert.equal(G.wheelDigit(0.0, 10), 0);
  assert.equal(G.wheelDigit(0.95, 10), 0);   // 9.5 rounds to 10 -> 0
  assert.equal(G.wheelDigit(0.94, 10), 9);
  assert.equal(G.wheelDigit(-0.05, 10), 0);   // wraps
  assert.equal(G.discDetent(0.4375, 8), 4);    // 3.5 -> 4
  assert.equal(G.discDetent(0.0, 8), 0);
  assert.deepEqual([G.dialDivisions(1), G.dialDivisions(2), G.dialDivisions(3)], [20, 30, 40]);
  assert.equal(G.sliderAngle(0, 4), -Math.PI / 2);
  assert.ok(Math.abs(G.sliderAngle(1, 4) - 0) < 1e-12);
  assert.equal(G.fieldLag(0.5, 0.2), 0.3);
  assert.equal(G.fieldLag(0.2, 0.5), -0.3);
  for (const fam of V06_FAMILIES) assert.equal(typeof globalThis.FAMILY_DRAW_V06[fam], 'function', fam);
});

test('every indexed trace renders at frames 0 / mid / end with the expected schematic', async (t) => {
  const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.ttf': 'font/ttf' };
  const server = createServer((req, res) => {
    const f = join(repo, decodeURIComponent(new URL(req.url, 'http://x').pathname));
    try { if (!statSync(f).isFile()) throw 0; res.writeHead(200, { 'content-type': types[extname(f)] || 'application/octet-stream' }); res.end(readFileSync(f)); }
    catch { res.writeHead(404); res.end(); }
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}/mockups/tools/lockviz/index.html`;
  const browser = await chromium.launch({ args: ['--no-sandbox', '--disable-dev-shm-usage'] });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const failures = [];
  try {
    // small batches of pages to keep runtime sane on long traces
    const jobs = [];
    for (const name of indexNames) {
      const info = traceInfo(name);
      const n = info.frames.length;
      for (const frame of ['0', String(Math.floor((n - 1) / 2)), 'end']) jobs.push({ name, family: info.family, frame });
    }
    const BATCH = 4;
    for (let k = 0; k < jobs.length; k += BATCH) {
      await Promise.all(jobs.slice(k, k + BATCH).map(async ({ name, family, frame }) => {
        const page = await context.newPage();
        const errors = [];
        page.on('pageerror', (e) => errors.push(e.message));
        try {
          await page.goto(`${base}?trace=${name}&t=${frame}`);
          await page.waitForSelector('body[data-ready="1"]', { timeout: 30000 });
          const ready = await page.getAttribute('body', 'data-ready');
          const schematic = await page.getAttribute('body', 'data-schematic');
          const want = EXPECTED_SCHEMATIC[family];
          if (ready !== '1') failures.push(`${name}@${frame}: data-ready=${ready}`);
          if (schematic !== want) failures.push(`${name}@${frame}: data-schematic=${schematic}, want ${want}`);
          if (V06_FAMILIES.includes(family) && schematic === 'drawLift') failures.push(`${name}@${frame}: v0.6 family fell back to drawLift`);
          if (errors.length) failures.push(`${name}@${frame}: pageerror: ${errors.join('; ')}`);
        } catch (e) {
          failures.push(`${name}@${frame}: ${e.message}`);
        } finally {
          await page.close();
        }
      }));
    }
  } finally {
    await browser.close();
    server.close();
  }
  assert.deepEqual(failures, [], failures.join('\n'));
});
