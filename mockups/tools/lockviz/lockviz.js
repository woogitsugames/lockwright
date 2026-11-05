// lockviz: developer/designer debug viewer for lockcore replays.
// Input: a lockwright.trace/1 file written by `replay_tool trace` (per-step state
// and events), optionally the lockwright.replay/1 file it came from.
// Design tool only, not game code. States are told apart by shape and pattern
// first, colour second (DESIGN.md).
'use strict';

const $ = (id) => document.getElementById(id);
const Q = 65536;
const STATE_STYLE = {
  // fill: base tone; mark: how the state is drawn without colour.
  free:      { fill: '#f8f6f1', label: 'free' },
  bound:     { fill: '#d9cdb4', label: 'BOUND' },
  near:      { fill: '#c9d6de', label: 'near' },
  set:       { fill: '#3b4f5e', label: 'SET' },
  false_set: { fill: '#d9a98f', label: 'FALSE' },
  overset:   { fill: '#23211d', label: 'OVER' },
  jammed:    { fill: '#a4472a', label: 'JAM' },
};
// Event lanes, top = highest presentation priority (LOCKS.md §1.6).
const LANE_ORDER = ['break', 'stress', 'open', 'set', 'false_set', 'counter_rotate', 'overset', 'drop',
  'detector_trip', 'gate_align', 'near_shear', 'bind', 'contact', 'wear'];
const STRONG = new Set(['break', 'open', 'detector_trip', 'overset', 'drop', 'false_set', 'set']);

let T = null;          // trace
let R = null;          // replay (optional)
let cur = 0;           // frame index
let playing = false;
let lastTs = 0;
let acc = 0;
let patterns = null;

// ---------- loading ----------
async function fetchJson(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error(url + ': ' + r.status);
  return r.json();
}

async function loadByName(name) {
  const t = await fetchJson('traces/' + name + '.trace.json');
  let rp = null;
  try { rp = await fetchJson('../../../lockcore/tests/golden/' + name + '.replay.json'); } catch { /* optional */ }
  setData(t, rp);
}

function setData(t, rp) {
  if (!t || t.schema !== 'lockwright.trace/1') { alert('not a lockwright.trace/1 file'); return; }
  T = t;
  R = rp;
  const nf = T.frame_fields.length;
  T.n = T.elements.length;
  T.nf = nf;
  T.ev = T.events.map((e) => ({ t: e[0], kind: T.event_kinds[e[1]], sub: e[2], el: e[3], inten: e[4], mat: e[5],
    name: e[2] ? (T.event_sub_names[String(e[2])] || T.event_kinds[e[1]] + '#' + e[2]) : T.event_kinds[e[1]] }));
  T.col = {};
  T.frame_fields.forEach((f, i) => { T.col[f] = i; });
  T.lanes = LANE_ORDER.filter((k) => T.ev.some((e) => e.kind === k));
  T.hasRotate = T.frames.some((f) => f[T.col.rotate] !== 0);
  T.hasPush = T.frames.some((f) => f[T.col.push] !== 0);
  T.hasStress = T.frames.some((f) => f[T.col.stress] !== 0);
  $('scrub').max = String(T.frames.length - 1);
  const p = new URLSearchParams(location.search);
  cur = Math.min(T.frames.length - 1, Math.max(0, parseInt(p.get('t') || '0', 10) || 0));
  if (p.get('t') === 'end') cur = T.frames.length - 1;
  const res = T.result;
  $('meta').innerHTML = `${T.family} · tier ${T.tier} · seed ${T.seed} · rules v${T.rules_version} · ` +
    `${res.steps} steps (${(res.steps / T.step_hz).toFixed(2)} s) · ${res.open ? 'open' : 'closed'}` +
    (res.failure !== 'none' ? ` · <span class="warn">failure: ${res.failure}</span>` : '') +
    ` · hash ${res.event_hash_fnv1a64} ` + (res.hash_matches ? '(matches)' : '<span class="warn">MISMATCH</span>');
  renderReplayTable();
  layoutTimeline();
  draw();
}

function renderReplayTable() {
  const rows = [['source', T.source], ['events', T.ev.length], ['elements', T.n]];
  if (R) {
    rows.push(['input runs (RLE)', R.inputs.length]);
    rows.push(['expected steps', R.expected.steps + (R.expected.steps === T.result.steps ? ' ✓' : ' ≠')]);
    rows.push(['expected hash', R.expected.event_hash_fnv1a64]);
    for (const [k, v] of Object.entries(R.difficulty)) rows.push(['d.' + k, v]);
  } else {
    rows.push(['replay', 'not loaded']);
  }
  $('replayTable').innerHTML = rows.map(([k, v]) => `<tr><td class="k">${k}</td><td>${v}</td></tr>`).join('');
}

// ---------- helpers ----------
const fr = (i = cur) => T.frames[i];
const val = (f, name) => f[T.col[name]] / Q;
const elState = (f, i) => T.element_states[f[T.nf + 2 * i]];
const elPos = (f, i) => f[T.nf + 2 * i + 1] / Q;

function fitCanvas(c, cssH) {
  const dpr = window.devicePixelRatio || 1;
  if (cssH) c.style.height = cssH + 'px';
  const w = c.clientWidth, h = c.clientHeight;
  if (c.width !== Math.round(w * dpr) || c.height !== Math.round(h * dpr)) {
    c.width = Math.round(w * dpr);
    c.height = Math.round(h * dpr);
  }
  const g = c.getContext('2d');
  g.setTransform(dpr, 0, 0, dpr, 0, 0);
  return { g, w, h };
}

function makePatterns(g) {
  const mk = (draw) => {
    const c = document.createElement('canvas');
    c.width = c.height = 8;
    const x = c.getContext('2d');
    draw(x);
    return g.createPattern(c, 'repeat');
  };
  return {
    free: null,
    bound: mk((x) => { x.fillStyle = STATE_STYLE.bound.fill; x.fillRect(0, 0, 8, 8); x.strokeStyle = '#23211d'; x.lineWidth = 1.2; x.beginPath(); x.moveTo(0, 8); x.lineTo(8, 0); x.stroke(); }),
    near: mk((x) => { x.fillStyle = STATE_STYLE.near.fill; x.fillRect(0, 0, 8, 8); x.fillStyle = '#23211d'; x.fillRect(3, 3, 2, 2); }),
    set: mk((x) => { x.fillStyle = STATE_STYLE.set.fill; x.fillRect(0, 0, 8, 8); }),
    false_set: mk((x) => { x.fillStyle = STATE_STYLE.false_set.fill; x.fillRect(0, 0, 8, 8); x.strokeStyle = '#23211d'; x.lineWidth = 1; x.beginPath(); x.moveTo(0, 8); x.lineTo(8, 0); x.moveTo(0, 0); x.lineTo(8, 8); x.stroke(); }),
    overset: mk((x) => { x.fillStyle = STATE_STYLE.overset.fill; x.fillRect(0, 0, 8, 8); x.fillStyle = '#f8f6f1'; x.fillRect(3, 0, 2, 8); }),
    jammed: mk((x) => { x.fillStyle = STATE_STYLE.jammed.fill; x.fillRect(0, 0, 8, 8); x.strokeStyle = '#f8f6f1'; x.beginPath(); x.moveTo(0, 4); x.lineTo(4, 0); x.lineTo(8, 4); x.stroke(); }),
  };
}

function text(g, s, x, y, opt = {}) {
  g.font = `${opt.weight || 400} ${opt.size || 12}px Atkinson, sans-serif`;
  g.fillStyle = opt.color || '#23211d';
  g.textAlign = opt.align || 'left';
  g.textBaseline = opt.base || 'alphabetic';
  g.fillText(s, x, y);
}

// ---------- schematic ----------
function drawSchematic() {
  const c = $('schematic');
  const { g, w, h } = fitCanvas(c);
  if (!patterns) patterns = makePatterns(g);
  g.fillStyle = '#efebe2';
  g.fillRect(0, 0, w, h);
  const f = fr();
  text(g, `${T.family}  ·  t = ${cur}  (${(cur / T.step_hz).toFixed(3)} s)`, 16, 26, { size: 16, weight: 700 });
  const box = { x: 16, y: 44, w: w - 32, h: h - 44 - 120 };
  const fam = T.family;
  if (fam === 'ring_combo') drawRings(g, box, f);
  else if (fam === 'warded') drawWarded(g, box, f);
  else if (fam === 'lever' || fam === 'lever_detector') drawLevers(g, box, f);
  else drawLift(g, box, f, fam === 'wafer' ? 'wafer' : 'pin');
  drawGauges(g, { x: 16, y: h - 112, w: w - 32, h: 100 }, f);
}

function stateFill(g, st) { g.fillStyle = patterns[st] || STATE_STYLE[st].fill; }

// Element body drawn by state: shape carries the meaning (DESIGN.md table).
function body(g, st, x, y, bw, bh, kind) {
  const off = st === 'bound' ? 3 : 0;   // binding: pushed sideways
  x += off;
  g.save();
  g.beginPath();
  if (st === 'false_set') {             // hourglass waist
    const m = bh * 0.5, n = bw * 0.28;
    g.moveTo(x, y); g.lineTo(x + bw, y); g.lineTo(x + bw - n, y + m); g.lineTo(x + bw, y + bh);
    g.lineTo(x, y + bh); g.lineTo(x + n, y + m); g.closePath();
  } else if (kind === 'wafer') {
    g.rect(x, y, bw, bh);
  } else {
    g.roundRect(x, y, bw, bh, [bw / 2, bw / 2, 3, 3]);  // pin: domed tip down
  }
  stateFill(g, st);
  g.fill();
  g.lineWidth = st === 'set' || st === 'overset' ? 3 : 2;
  g.setLineDash(st === 'near' ? [5, 3] : []);
  g.strokeStyle = '#23211d';
  g.stroke();
  g.restore();
  if (st === 'bound') {                 // three friction strokes on the pressed side
    g.strokeStyle = '#23211d'; g.lineWidth = 1.5;
    for (let k = 0; k < 3; k++) { g.beginPath(); g.moveTo(x + bw + 3, y + 6 + k * 7); g.lineTo(x + bw + 9, y + k * 7); g.stroke(); }
  }
  if (st === 'set') {                   // flat foot on the ledge
    g.fillStyle = '#23211d'; g.fillRect(x - 5, y + bh - 4, bw + 10, 4);
  }
}

function elementLabel(g, i, st, x, y, extra) {
  text(g, String(i), x, y, { align: 'center', weight: 700, size: 13 });
  text(g, STATE_STYLE[st].label, x, y + 15, { align: 'center', size: 11, weight: st === 'free' ? 400 : 700 });
  if (extra) text(g, extra, x, y + 29, { align: 'center', size: 10, color: '#6b665c' });
}

// pin_tumbler / wooden_pin / wafer: chambers, travel scaled 0..1.
function drawLift(g, box, f, kind) {
  const n = T.n, cw = Math.min(90, box.w / (n + 1.5));
  const x0 = box.x + (box.w - cw * n) / 2 + cw * 0.25;
  const base = box.y + box.h - 70, H = Math.min((box.h - 110) * 0.55, 240);
  // plug / shell schematic: the shear band is each element's set window.
  g.fillStyle = '#ddd6c8'; g.fillRect(x0 - 20, base - H * 1.75 - 20, cw * n + 10, H * 1.75 + 30);
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * cw, ew = cw * 0.42;
    const [lo, hi, variant] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    g.fillStyle = '#f8f6f1'; g.fillRect(cx, base - H * 1.75 - 10, ew + 8, H * 1.75 + 10);   // chamber
    g.strokeStyle = '#6b665c'; g.lineWidth = 1; g.strokeRect(cx, base - H * 1.75 - 10, ew + 8, H * 1.75 + 10);
    // set window: two engraved lines + wedge
    const len = kind === 'wafer' ? 34 : Math.max(40, H * 0.4);
    // window lines mark where the element's top edge must sit (position in [lo, hi])
    const ylo = base - len - (lo / Q) * H, yhi = base - len - (hi / Q) * H;
    g.strokeStyle = '#2f5d7c'; g.lineWidth = 2; g.setLineDash([3, 3]);
    g.beginPath(); g.moveTo(cx - 6, ylo); g.lineTo(cx + ew + 14, ylo); g.moveTo(cx - 6, yhi); g.lineTo(cx + ew + 14, yhi); g.stroke();
    g.setLineDash([]);
    // element: top edge at the current position
    const top = base - len - p * H;
    body(g, st, cx + 4, top, ew, len, kind);
    elementLabel(g, i, st, cx + ew / 2 + 4, base + 44, `${p.toFixed(3)}${variant ? ' v' + variant : ''}`);
  }
  // shear line across the housing (nominal, mid of all windows)
  g.strokeStyle = '#23211d'; g.lineWidth = 2;
  // pick under the addressed element
  drawPick(g, x0, cw, base, H, f);
  drawCore(g, box, f, 'plug');
}

function drawPick(g, x0, cw, base, H, f) {
  const pe = f[T.col.pick_element];
  const lift = f[T.col.view_pick_lift] / Q;
  const depth = val(f, 'pick_depth');
  const tipX = pe >= 0 ? x0 + pe * cw + cw * 0.21 + 4 : x0 + depth * cw * T.n;
  const tipY = base - lift * H * 0.5;
  g.strokeStyle = '#4a4f55'; g.lineWidth = 4; g.lineCap = 'round';
  g.beginPath(); g.moveTo(x0 - 60, base + 22); g.lineTo(tipX - 6, base + 22); g.lineTo(tipX, tipY); g.stroke();
  g.lineCap = 'butt';
  text(g, `pick → ${pe}`, x0 - 66, base + 20, { size: 11, color: '#6b665c', align: 'right' });
  text(g, `lift ${lift.toFixed(2)}`, x0 - 66, base + 34, { size: 11, color: '#6b665c', align: 'right' });
}

// Core rotation dial (fraction of the opening rotation) + tension wrench.
function drawCore(g, box, f, what) {
  const cx = box.x + box.w - 56, cy = box.y + 50, r = 36;
  const rot = val(f, 'core_rotation');
  g.fillStyle = '#f8f6f1'; g.strokeStyle = '#23211d'; g.lineWidth = 2;
  g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.fill(); g.stroke();
  for (let k = 0; k <= 8; k++) {           // engraved scale, 1/8 steps
    const a = -Math.PI / 2 + (k / 8) * Math.PI / 2;
    g.beginPath(); g.moveTo(cx + Math.cos(a) * (r - 6), cy + Math.sin(a) * (r - 6)); g.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r); g.stroke();
  }
  const a = -Math.PI / 2 + rot * Math.PI / 2;
  g.lineWidth = 4; g.beginPath(); g.moveTo(cx, cy); g.lineTo(cx + Math.cos(a) * (r - 4), cy + Math.sin(a) * (r - 4)); g.stroke();
  text(g, `${what} ${(rot * 100).toFixed(1)}%`, cx, cy + r + 16, { align: 'center', size: 11 });
  if (f[T.col.failure]) text(g, T.failures[f[T.col.failure]].toUpperCase(), cx, cy + r + 32, { align: 'center', weight: 700, color: '#a4472a' });
  else if (rot >= 1) text(g, 'OPEN', cx, cy + r + 32, { align: 'center', weight: 700 });
}

// Levers: plates lifted by the key bit; the gate slot must reach the bolt stump.
function drawLevers(g, box, f) {
  const n = T.n, cw = Math.min(90, box.w / (n + 1.5));
  const x0 = box.x + (box.w - cw * n) / 2;
  const base = box.y + box.h - 84, H = Math.min(box.h - 170, 220), plateH = H + 40;
  const stumpY = base - H * 0.5 - 40;
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * cw, ew = cw * 0.7;
    const [lo, hi, falseGates] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    const lift = p * H * 0.5;
    const yb = base - lift;
    g.save();
    if (st === 'bound') g.translate(3, 0);
    stateFill(g, st);
    g.fillRect(cx, yb - plateH, ew, plateH);
    g.lineWidth = st === 'set' ? 3 : 2; g.setLineDash(st === 'near' ? [5, 3] : []); g.strokeStyle = '#23211d';
    g.strokeRect(cx, yb - plateH, ew, plateH);
    g.setLineDash([]);
    // gate slot: where the stump sits when p is inside [lo, hi]
    const sTop = stumpY + (p - hi / Q) * H * 0.5, sBot = stumpY + (p - lo / Q) * H * 0.5;
    g.fillStyle = '#efebe2'; g.fillRect(cx + ew * 0.3, sTop - 6, ew * 0.4, sBot - sTop + 12);
    g.strokeRect(cx + ew * 0.3, sTop - 6, ew * 0.4, sBot - sTop + 12);
    if (st === 'false_set') { g.beginPath(); g.moveTo(cx, yb - plateH); g.lineTo(cx + ew, yb); g.moveTo(cx + ew, yb - plateH); g.lineTo(cx, yb); g.stroke(); }
    g.restore();
    elementLabel(g, i, st, cx + ew / 2, base + 50, `${p.toFixed(3)}${falseGates ? ' fg' + falseGates : ''}`);
  }
  // bolt stump: a fixed bar across all levers
  g.fillStyle = '#4a4f55';
  const rot = val(f, 'core_rotation');
  g.fillRect(x0 - 20 + rot * 60, stumpY - 5, cw * n + 20, 10);
  text(g, 'stump', x0 - 24, stumpY - 10, { size: 11, color: '#6b665c' });
  drawPick(g, x0 - cw * 0.06, cw, base + 10, H, f);
  drawCore(g, box, f, 'bolt');
}

// Warded: wards with gaps in the key-bit height; the bit must clear each gap.
function drawWarded(g, box, f) {
  const n = T.n - 1;
  const cw = Math.min(110, box.w / (n + 3));
  const x0 = box.x + 40;
  const base = box.y + box.h - 60, H = Math.min(box.h - 120, 280);
  const lift = f[T.col.view_pick_lift] / Q;
  const theta = val(f, 'core_rotation');
  const pe = f[T.col.pick_element];
  const Y = (v) => base - v * H;
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * cw;
    const [lo, hi] = T.elements[i];
    const st = elState(f, i);
    g.save();
    if (st === 'bound') g.translate(3, 0);
    stateFill(g, st === 'free' ? 'bound' : st);
    if (st === 'free') g.fillStyle = '#ddd6c8';
    g.fillRect(cx, Y(1), 22, Y(hi / Q) - Y(1));
    g.fillRect(cx, Y(lo / Q), 22, base - Y(lo / Q));
    g.strokeStyle = '#23211d'; g.lineWidth = st === 'near' ? 3 : 2; g.setLineDash(st === 'near' ? [5, 3] : []);
    g.strokeRect(cx, Y(1), 22, Y(hi / Q) - Y(1)); g.strokeRect(cx, Y(lo / Q), 22, base - Y(lo / Q));
    g.restore();
    elementLabel(g, i, st, cx + 11, base + 22, `gap ${(lo / Q).toFixed(2)}–${(hi / Q).toFixed(2)}`);
  }
  // key bit at its height, beside the ward it faces
  const bx = x0 + Math.max(0, Math.min(pe, n)) * cw - 18;
  g.fillStyle = '#4a4f55'; g.fillRect(bx, Y(lift) - 4, 14, 8);
  g.strokeStyle = '#4a4f55'; g.lineWidth = 2; g.beginPath(); g.moveTo(x0 - 30, Y(lift)); g.lineTo(bx, Y(lift)); g.stroke();
  text(g, `bit h ${lift.toFixed(3)} · facing ${pe}`, x0 - 30, Y(lift) - 10, { size: 11, color: '#6b665c' });
  // bolt (last element): slides right with its position
  const bi = n, [blo, bhi] = T.elements[bi], bst = elState(f, bi), bp = elPos(f, bi);
  const by = box.y + 40, bxx = x0 + n * cw + 10;
  g.fillStyle = '#ddd6c8'; g.fillRect(bxx, by, 140, 24);
  body(g, bst, bxx + bp * 80, by + 2, 60, 20, 'wafer');
  g.strokeStyle = '#2f5d7c'; g.setLineDash([3, 3]);
  g.beginPath(); g.moveTo(bxx + (blo / Q) * 80 + 60, by - 6); g.lineTo(bxx + (blo / Q) * 80 + 60, by + 30);
  g.moveTo(bxx + (bhi / Q) * 80 + 60, by - 6); g.lineTo(bxx + (bhi / Q) * 80 + 60, by + 30); g.stroke(); g.setLineDash([]);
  elementLabel(g, bi, bst, bxx + 70, by + 46, `bolt ${bp.toFixed(3)}`);
  drawCore(g, box, f, 'key turn');
  void theta;
}

// Rings: each ring turns; the gate notch must meet the reading line at 12 o'clock.
function drawRings(g, box, f) {
  const n = T.n;
  const r = Math.min(70, box.w / (n * 2.6), box.h / 3);
  const cy = box.y + box.h / 2 + 10;
  const x0 = box.x + (box.w - n * r * 2.5) / 2 + r * 1.25;
  const pe = f[T.col.pick_element];
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * r * 2.5;
    const [lo, hi, falseGates] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    g.save();
    if (st === 'bound') g.translate(3, 0);
    stateFill(g, st); g.strokeStyle = '#23211d'; g.lineWidth = st === 'set' ? 4 : 2; g.setLineDash(st === 'near' ? [5, 3] : []);
    g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.fill(); g.stroke(); g.setLineDash([]);
    g.fillStyle = '#efebe2'; g.beginPath(); g.arc(cx, cy, r * 0.45, 0, Math.PI * 2); g.fill(); g.stroke();
    // gate notch (window) rotates with the ring; aligned when it is at the top.
    const a0 = -Math.PI / 2 + (lo / Q - p) * Math.PI * 2, a1 = -Math.PI / 2 + (hi / Q - p) * Math.PI * 2;
    g.fillStyle = '#f8f6f1'; g.beginPath(); g.arc(cx, cy, r + 1, a0, a1); g.arc(cx, cy, r * 0.62, a1, a0, true); g.closePath(); g.fill(); g.stroke();
    // ring index tick (digit 0)
    const az = -Math.PI / 2 - p * Math.PI * 2;
    g.lineWidth = 3; g.beginPath(); g.moveTo(cx + Math.cos(az) * r * 0.45, cy + Math.sin(az) * r * 0.45); g.lineTo(cx + Math.cos(az) * r * 0.62, cy + Math.sin(az) * r * 0.62); g.stroke();
    g.restore();
    if (i === pe) { g.strokeStyle = '#4a4f55'; g.lineWidth = 3; g.beginPath(); g.arc(cx, cy, r + 10, Math.PI * 0.6, Math.PI * 0.9); g.stroke(); text(g, 'thumb', cx - r - 4, cy + r + 4, { size: 11, color: '#6b665c', align: 'right' }); }
    elementLabel(g, i, st, cx, cy + r + 26, `${p.toFixed(3)}${falseGates ? ' fg' + falseGates : ''}`);
  }
  // reading line across the tops
  g.strokeStyle = '#23211d'; g.lineWidth = 2; g.setLineDash([6, 4]);
  g.beginPath(); g.moveTo(x0 - r * 1.3, cy - r - 2); g.lineTo(x0 + (n - 1) * r * 2.5 + r * 1.3, cy - r - 2); g.stroke(); g.setLineDash([]);
  text(g, 'reading line', x0 - r * 1.3, cy - r - 10, { size: 11, color: '#6b665c' });
  drawCore(g, box, f, 'shackle');
}

function drawGauges(g, b, f) {
  const items = [['tension', val(f, 'tension'), 0], ['pick_depth', val(f, 'pick_depth'), 0], ['pick_lift', val(f, 'pick_lift'), 1],
    ['resistance', val(f, 'tension_resistance'), 0], ['drag', val(f, 'pick_drag'), 0], ['stress', val(f, 'stress'), 0]];
  if (T.hasRotate) items.push(['rotate', val(f, 'rotate'), 1]);
  if (T.hasPush) items.push(['push', val(f, 'push'), 0]);
  const cols = 4, gw = (b.w - (cols - 1) * 12) / cols;
  items.forEach(([name, v, signed], k) => {
    const x = b.x + (k % cols) * (gw + 12), y = b.y + Math.floor(k / cols) * 44;
    text(g, `${name}  ${v.toFixed(3)}`, x, y + 12, { size: 12 });
    g.fillStyle = '#f8f6f1'; g.fillRect(x, y + 18, gw, 14);
    g.strokeStyle = '#23211d'; g.lineWidth = 1.5; g.strokeRect(x, y + 18, gw, 14);
    g.fillStyle = name === 'stress' && v > 0.8 ? '#a4472a' : '#4a4f55';
    if (signed) { const m = x + gw / 2; g.fillRect(Math.min(m, m + v * gw / 2), y + 20, Math.abs(v) * gw / 2, 10); g.fillStyle = '#23211d'; g.fillRect(m - 1, y + 16, 2, 18); }
    else g.fillRect(x + 2, y + 20, Math.max(0, Math.min(1, v)) * (gw - 4), 10);
  });
}

// ---------- timeline ----------
let TL = null;  // layout

function layoutTimeline() {
  const curves = [['tension', 0, '#23211d'], ['pick_depth', 0, '#2f5d7c'], ['pick_lift', 1, '#2f5d7c'], ['view_pick_lift', 1, '#6b665c']];
  if (T.hasRotate) curves.push(['rotate', 1, '#2f5d7c']);
  if (T.hasPush) curves.push(['push', 0, '#2f5d7c']);
  curves.push(['tension_resistance', 0, '#4a4f55'], ['pick_drag', 0, '#4a4f55']);
  if (T.hasStress) curves.push(['stress', 0, '#a4472a']);
  curves.push(['core_rotation', 0, '#23211d']);
  const rowH = 30, stripH = 12, laneH = 13, gap = 8;
  let y = 6;
  const rows = curves.map(([name, signed, color]) => { const r = { name, signed, color, y, h: rowH - 4 }; y += rowH; return r; });
  y += gap;
  const strips = []; for (let i = 0; i < T.n; i++) { strips.push({ i, y, h: stripH - 2 }); y += stripH; }
  y += gap;
  const lanes = T.lanes.map((k) => { const l = { kind: k, y, h: laneH - 2 }; y += laneH; return l; });
  y += 18;
  TL = { rows, strips, lanes, height: y, left: 150, right: 14 };
}

function drawTimeline() {
  const c = $('timeline');
  const { g, w } = fitCanvas(c, TL.height);
  const L = TL.left, W = w - L - TL.right, N = T.frames.length;
  const X = (i) => L + (i / Math.max(1, N - 1)) * W;
  g.fillStyle = '#f8f6f1'; g.fillRect(0, 0, w, TL.height);
  for (const r of TL.rows) {
    const ci = T.col[r.name];
    g.fillStyle = '#efebe2'; g.fillRect(L, r.y, W, r.h);
    if (r.signed) { g.fillStyle = '#d6cfc0'; g.fillRect(L, r.y + r.h / 2, W, 1); }
    text(g, r.name, L - 8, r.y + r.h / 2 + 4, { align: 'right', size: 11 });
    const Y = (v) => r.signed ? r.y + r.h / 2 - (v / Q) * (r.h / 2) : r.y + r.h - (v / Q) * r.h;
    g.strokeStyle = r.color; g.lineWidth = 1.5; g.beginPath();
    // min/max per pixel column keeps spikes visible on long replays
    const step = Math.max(1, Math.floor(N / W));
    for (let i = 0; i < N; i += step) {
      let mn = Infinity, mx = -Infinity;
      for (let j = i; j < Math.min(N, i + step); j++) { const v = T.frames[j][ci]; if (v < mn) mn = v; if (v > mx) mx = v; }
      const x = X(i);
      if (i === 0) g.moveTo(x, Y(mn)); else g.lineTo(x, Y(mn));
      if (mx !== mn) g.lineTo(x, Y(mx));
    }
    g.stroke();
  }
  for (const s of TL.strips) {
    text(g, `element ${s.i}`, L - 8, s.y + s.h - 1, { align: 'right', size: 10 });
    let start = 0;
    const off = T.nf + 2 * s.i;
    for (let i = 1; i <= N; i++) {
      if (i === N || T.frames[i][off] !== T.frames[start][off]) {
        const st = T.element_states[T.frames[start][off]];
        if (st !== 'free') { stateFill(g, st); g.fillRect(X(start), s.y, Math.max(1, X(i) - X(start)), s.h); }
        start = i;
      }
    }
    g.strokeStyle = '#bdb6a7'; g.lineWidth = 1; g.strokeRect(L, s.y, W, s.h);
  }
  for (const l of TL.lanes) {
    text(g, l.kind, L - 8, l.y + l.h - 1, { align: 'right', size: 10, weight: STRONG.has(l.kind) ? 700 : 400 });
    g.fillStyle = '#efebe2'; g.fillRect(L, l.y, W, l.h);
    for (const e of T.ev) {
      if (e.kind !== l.kind) continue;
      const x = X(e.t);
      g.fillStyle = e.kind === 'break' || e.kind === 'detector_trip' ? '#a4472a' : '#23211d';
      if (STRONG.has(e.kind)) { g.beginPath(); g.moveTo(x, l.y); g.lineTo(x + 4, l.y + l.h / 2); g.lineTo(x, l.y + l.h); g.lineTo(x - 4, l.y + l.h / 2); g.fill(); }
      else g.fillRect(x - 0.75, l.y + 1, 1.5, l.h - 2);
    }
  }
  // seconds axis
  const yAx = TL.height - 6;
  for (let s = 0; s <= N / T.step_hz; s += N / T.step_hz > 20 ? 5 : 1) {
    const x = X(s * T.step_hz);
    g.fillStyle = '#6b665c'; g.fillRect(x, yAx - 16, 1, 5);
    text(g, s + ' s', x, yAx, { align: 'center', size: 10, color: '#6b665c' });
  }
  // cursor
  const xc = X(cur);
  g.fillStyle = '#a4472a'; g.fillRect(xc - 1, 0, 2, TL.height - 14);
  g.beginPath(); g.moveTo(xc - 6, 0); g.lineTo(xc + 6, 0); g.lineTo(xc, 8); g.fill();
  TL.X = X; TL.W = W;
}

// ---------- panels ----------
function drawPanels() {
  const f = fr();
  const rows = [['t_step', cur], ['time', (cur / T.step_hz).toFixed(3) + ' s']];
  T.frame_fields.forEach((name, i) => {
    let v = f[i];
    if (name === 'failure') v = T.failures[v];
    else if (!['tool', 'pick_element'].includes(name)) v = (v / Q).toFixed(4);
    rows.push([name, v]);
  });
  $('frameTable').innerHTML = rows.map(([k, v]) => `<tr><td class="k">${k}</td><td>${v}</td></tr>`).join('');
  let er = '';
  for (let i = 0; i < T.n; i++) {
    const [lo, hi, variant] = T.elements[i];
    er += `<tr><td class="k">${i}</td><td><b>${elState(f, i)}</b></td><td>${elPos(f, i).toFixed(4)}</td><td>[${(lo / Q).toFixed(3)}, ${(hi / Q).toFixed(3)}]</td><td>v${variant}</td></tr>`;
  }
  $('elemTable').innerHTML = er;
  const past = T.ev.filter((e) => e.t <= cur).slice(-14);
  $('events').innerHTML = past.reverse().map((e) =>
    `<li class="${e.t === cur ? 'now' : ''}"><span class="t">${e.t}</span>${e.name}${e.el >= 0 ? ' · el ' + e.el : ''} · ${(e.inten / Q).toFixed(2)}${e.mat ? ' · ' + T.materials[e.mat] : ''}</li>`).join('');
  $('scrub').value = String(cur);
  $('time').textContent = `frame ${cur} / ${T.frames.length - 1} · ${(cur / T.step_hz).toFixed(3)} s`;
}

function draw() {
  if (!T) return;
  drawSchematic();
  drawTimeline();
  drawPanels();
}

// ---------- interaction ----------
function seek(i) { cur = Math.max(0, Math.min(T.frames.length - 1, i | 0)); draw(); }
function seekEvent(dir) {
  const evs = T.ev.filter((e) => e.kind !== 'contact' && e.kind !== 'counter_rotate');
  const e = dir > 0 ? evs.find((x) => x.t > cur) : [...evs].reverse().find((x) => x.t < cur);
  if (e) seek(e.t);
}

function tick(ts) {
  if (!playing) return;
  const dt = lastTs ? (ts - lastTs) / 1000 : 0;
  lastTs = ts;
  acc += dt * T.step_hz * parseFloat($('speed').value);
  if (acc >= 1) { const k = Math.floor(acc); acc -= k; cur += k; }
  if (cur >= T.frames.length - 1) { cur = T.frames.length - 1; playing = false; $('play').textContent = 'play'; }
  draw();
  if (playing) requestAnimationFrame(tick);
}

$('play').onclick = () => {
  playing = !playing;
  $('play').textContent = playing ? 'pause' : 'play';
  if (playing) { if (cur >= T.frames.length - 1) cur = 0; lastTs = 0; acc = 0; requestAnimationFrame(tick); }
};
$('back').onclick = () => seek(cur - 1);
$('fwd').onclick = () => seek(cur + 1);
$('prevEv').onclick = () => seekEvent(-1);
$('nextEv').onclick = () => seekEvent(1);
$('scrub').oninput = (e) => seek(parseInt(e.target.value, 10));
window.addEventListener('keydown', (e) => {
  if (!T || e.target.tagName === 'SELECT') return;
  if (e.key === 'ArrowLeft') seek(cur - (e.shiftKey ? 10 : 1));
  else if (e.key === 'ArrowRight') seek(cur + (e.shiftKey ? 10 : 1));
  else if (e.key === '[') seekEvent(-1);
  else if (e.key === ']') seekEvent(1);
  else if (e.key === ' ') { e.preventDefault(); $('play').click(); }
});
{
  const tl = $('timeline');
  let drag = false;
  const at = (e) => { const r = tl.getBoundingClientRect(); seek(Math.round(((e.clientX - r.left - TL.left) / TL.W) * (T.frames.length - 1))); };
  tl.addEventListener('pointerdown', (e) => { drag = true; tl.setPointerCapture(e.pointerId); at(e); });
  tl.addEventListener('pointermove', (e) => { if (drag) at(e); });
  tl.addEventListener('pointerup', () => { drag = false; });
}
const readFile = (input) => new Promise((res) => { const fl = input.files[0]; if (!fl) return res(null); fl.text().then((s) => res(JSON.parse(s))); });
$('fileTrace').onchange = async () => setData(await readFile($('fileTrace')), R);
$('fileReplay').onchange = async () => { R = await readFile($('fileReplay')); if (T) { renderReplayTable(); } };
$('pick').onchange = () => { history.replaceState(null, '', '?trace=' + $('pick').value); loadByName($('pick').value); };
window.addEventListener('resize', draw);

(async function init() {
  let names = [];
  try { names = await fetchJson('traces/index.json'); } catch { /* opened without the traces folder */ }
  $('pick').innerHTML = names.map((n) => `<option>${n}</option>`).join('');
  const want = new URLSearchParams(location.search).get('trace') || names[0];
  if (want) { $('pick').value = want; await document.fonts.ready; await loadByName(want); }
  document.body.dataset.ready = '1';
})();
