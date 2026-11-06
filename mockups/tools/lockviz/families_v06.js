// lockviz: schematics for the lockcore v0.6 families (D-59), drawn by drawSchematic()
// in lockviz.js through FAMILY_DRAW_V06. Same rules as the older schematics:
// states are told apart by shape/pattern/line weight first, colour second (DESIGN.md),
// no gradients/neon/glow, elements >= 28 px at 1440 width. Design tool only, not game code.
// Pure geometry helpers live in LOCKVIZ_GEOM (unit-tested from test/ in Node).
'use strict';

// ---------- pure geometry (no DOM; unit-tested in test/lockviz.test.mjs) ----------
const LOCKVIZ_GEOM = {
  wrap01: (x) => ((x % 1) + 1) % 1,
  gateCenter: (loQ16, hiQ16) => (((loQ16 + hiQ16) / 2) / 65536 + 1) % 1,
  wheelDigit: (pos, digits = 10) => Math.floor((((pos % 1) + 1) % 1) * digits + 0.5) % digits,
  sliderAngle: (i, n) => -Math.PI / 2 + (i / n) * Math.PI * 2,
  discDetent: (pos, positions = 8) => Math.round((((pos % 1) + 1) % 1) * positions) % positions,
  dialDivisions: (tier) => ({ 1: 20, 2: 30, 3: 40 }[tier] || 20),
  // magnetic: signed distance between the thumb target and the lagging field (fractions of travel)
  fieldLag: (thumb, field) => thumb - field,
};

// ---------- shared bits ----------
// Gate window [lo, hi] (Q16) rotated by -p: the wedge sits at the top (12 o'clock) when set.
function gateWedge(g, cx, cy, r, lo, hi, p) {
  const a0 = -Math.PI / 2 + (LOCKVIZ_GEOM.wrap01(lo / Q - p)) * Math.PI * 2;
  const a1 = a0 + ((hi - lo) / Q) * Math.PI * 2;
  g.beginPath();
  g.arc(cx, cy, r + 1, a0, a1);
  g.arc(cx, cy, r * 0.62, a1, a0, true);
  g.closePath();
  g.fillStyle = '#f8f6f1';
  g.fill();
  g.strokeStyle = '#23211d'; g.lineWidth = 1.5; g.stroke();
}

function wheelBody(g, cx, cy, r, st) {
  g.save();
  if (st === 'bound') g.translate(3, 0);
  stateFill(g, st);
  g.strokeStyle = '#23211d';
  g.lineWidth = st === 'set' ? 4 : 2;
  g.setLineDash(st === 'near' ? [5, 3] : []);
  g.beginPath(); g.arc(cx, cy, r, 0, Math.PI * 2); g.fill(); g.stroke();
  g.setLineDash([]);
  g.fillStyle = '#efebe2';
  g.beginPath(); g.arc(cx, cy, r * 0.45, 0, Math.PI * 2); g.fill(); g.stroke();
  if (st === 'false_set') {
    g.lineWidth = 2;
    g.beginPath(); g.moveTo(cx - r, cy); g.lineTo(cx + r, cy); g.moveTo(cx + r, cy); g.lineTo(cx - r, cy); g.stroke();
  }
  g.restore();
}

function readingLine(g, x0, x1, y, label) {
  g.strokeStyle = '#23211d'; g.lineWidth = 2; g.setLineDash([6, 4]);
  g.beginPath(); g.moveTo(x0, y); g.lineTo(x1, y); g.stroke(); g.setLineDash([]);
  if (label) text(g, label, x0, y - 8, { size: 11, color: '#6b665c' });
}

// ---------- dial_safe: wheel pack, fence, crank, listening cup ----------
function dialAngleAt(i) {
  if (!T._dialAngle) {
    const a = [0];
    for (let k = 1; k < T.frames.length; k++) {
      a.push(a[k - 1] + T.frames[k][T.col.view_pick_lift] / Q / T.step_hz);
    }
    T._dialAngle = a;
  }
  return LOCKVIZ_GEOM.wrap01(T._dialAngle[Math.min(i, T._dialAngle.length - 1)]);
}

function drawDialSafe(g, box, f) {
  const n = T.n;
  const div = LOCKVIZ_GEOM.dialDivisions(T.tier);
  const r = Math.min(64, box.w / (n * 2.9), box.h / 3.4);
  const cy = box.y + box.h / 2 + 24;
  const x0 = box.x + (box.w - n * r * 2.6) / 2 + r * 1.3;
  const pe = f[T.col.pick_element];
  const allSet = T.elements.every((_, i) => elState(f, i) === 'set');
  const hp = val(f, 'hold_progress');
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * r * 2.6;
    const ri = r * (1 - 0.05 * i);              // wheel pack: graded diameters, wheel 0 farthest from the crank
    const [lo, hi, falseGates] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    wheelBody(g, cx, cy, ri, st);
    gateWedge(g, cx, cy, ri, lo, hi, p);         // gate vs the fence at 12 o'clock
    const az = -Math.PI / 2 - p * Math.PI * 2;   // index tick (division 0)
    g.strokeStyle = '#23211d'; g.lineWidth = 3;
    g.beginPath(); g.moveTo(cx + Math.cos(az) * ri * 0.45, cy + Math.sin(az) * ri * 0.45);
    g.lineTo(cx + Math.cos(az) * ri * 0.62, cy + Math.sin(az) * ri * 0.62); g.stroke();
    if (i === pe) {                              // listening cup on the heard wheel
      g.strokeStyle = '#4a4f55'; g.lineWidth = 3;
      g.beginPath(); g.arc(cx, cy, ri + 10, Math.PI * 0.55, Math.PI * 1.45); g.stroke();
      text(g, 'listening', cx, cy - ri - 16, { size: 11, color: '#6b665c', align: 'center' });
    }
    elementLabel(g, i, st, cx, cy + ri + 26, `${Math.round(LOCKVIZ_GEOM.wrap01(p) * div)}/${div}${falseGates ? ' fg' + falseGates : ''}`);
  }
  // fence above the wheel pack: drops into the cam notch when every gate is aligned
  const fenceDrop = allSet ? 8 + hp * 14 : 0;
  const fy = cy - r - 26 - fenceDrop;
  g.fillStyle = '#4a4f55';
  g.fillRect(x0 - r * 1.3, fy, n * r * 2.6, 10);
  g.fillStyle = '#efebe2';
  g.beginPath(); g.moveTo(x0 - 6, fy + 10); g.lineTo(x0 + 6, fy + 10); g.lineTo(x0, fy + 22); g.closePath(); g.fill(); g.strokeStyle = '#23211d'; g.stroke();
  text(g, allSet ? `fence dropped ${(hp * 100).toFixed(0)}%` : 'fence', x0 - r * 1.3, fy - 8, { size: 11, color: '#6b665c' });
  // label at the right end: above the line it collided with the fence bar (review V03)
  const fx1 = x0 + (n - 1) * r * 2.6 + r * 1.3;
  readingLine(g, x0 - r * 1.3, fx1, cy - r - 2, '');
  text(g, 'fence line', fx1 + 6, cy - r + 2, { size: 11, color: '#6b665c' });
  // crank (dial) left of the core gauge (drawCore sits at the top-right corner; review V03: they overlapped)
  const dx = box.x + box.w - 56 - 120, dcy = box.y + 56, dr = 34;
  const da = dialAngleAt(cur);
  g.fillStyle = '#f8f6f1'; g.strokeStyle = '#23211d'; g.lineWidth = 2;
  g.beginPath(); g.arc(dx, dcy, dr, 0, Math.PI * 2); g.fill(); g.stroke();
  for (let k = 0; k < div; k++) {
    const a = -Math.PI / 2 + (k / div) * Math.PI * 2;
    g.lineWidth = k % 5 === 0 ? 2 : 1;
    g.beginPath(); g.moveTo(dx + Math.cos(a) * (dr - (k % 5 === 0 ? 8 : 4)), dcy + Math.sin(a) * (dr - (k % 5 === 0 ? 8 : 4)));
    g.lineTo(dx + Math.cos(a) * dr, dcy + Math.sin(a) * dr); g.stroke();
  }
  const aa = -Math.PI / 2 + da * Math.PI * 2;
  g.lineWidth = 4; g.beginPath(); g.moveTo(dx, dcy); g.lineTo(dx + Math.cos(aa) * (dr - 4), dcy + Math.sin(aa) * (dr - 4)); g.stroke();
  text(g, `dial ${LOCKVIZ_GEOM.wheelDigit(da, div)}/${div} · ${(val(f, 'tension')).toFixed(2)} press`, dx, dcy + dr + 16, { align: 'center', size: 11 });
  drawCore(g, box, f, 'bolt');
}

// ---------- combo: thumbwheel row, digits at the reading line, sleeve notch, cable ----------
function drawCombo(g, box, f) {
  const n = T.n;
  const r = Math.min(70, box.w / (n * 2.6), box.h / 3.2);
  const cy = box.y + box.h / 2 + 16;
  const x0 = box.x + (box.w - n * r * 2.5) / 2 + r * 1.25;
  const pe = f[T.col.pick_element];
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * r * 2.5;
    const [lo, hi, falseGates] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    wheelBody(g, cx, cy, r, st);
    gateWedge(g, cx, cy, r * 0.86, lo, hi, p);   // sleeve notch (tulejka) vs the bolt tooth
    const d = LOCKVIZ_GEOM.wheelDigit(p, 10);    // digit at the reading line
    text(g, String(d), cx, cy + 5, { align: 'center', size: 16, weight: 700 });
    if (st === 'overset') text(g, 'slip', cx, cy - r - 30, { align: 'center', size: 10, color: '#a4472a', weight: 700 });
    if (i === pe) { g.strokeStyle = '#4a4f55'; g.lineWidth = 3; g.beginPath(); g.arc(cx, cy, r + 10, Math.PI * 0.6, Math.PI * 0.9); g.stroke(); text(g, 'thumb', cx - r - 4, cy + r + 4, { size: 11, color: '#6b665c', align: 'right' }); }
    elementLabel(g, i, st, cx, cy + r + 26, `d${d} ${(p).toFixed(3)}${falseGates ? ' fg' + falseGates : ''}`);
  }
  readingLine(g, x0 - r * 1.3, x0 + (n - 1) * r * 2.5 + r * 1.3, cy - r - 2, 'reading line');
  // cable from the last wheel to the shackle (tension = cable pull)
  const rot = val(f, 'core_rotation');
  g.strokeStyle = '#4a4f55'; g.lineWidth = 3;
  g.beginPath(); g.moveTo(x0 + (n - 1) * r * 2.5 + r, cy); g.lineTo(box.x + box.w - 90, cy - 30 + rot * 30); g.lineTo(box.x + box.w - 60, cy - 30 + rot * 30); g.stroke();
  text(g, `cable pull T=${val(f, 'tension').toFixed(2)}`, x0 + (n - 1) * r * 2.5 + r + 8, cy + 20, { size: 11, color: '#6b665c' });  // below the cable (review V03)
  drawCore(g, box, f, 'shackle');
}

// ---------- dimple: two pin rows seen from the side; telescopic pin = sleeve + inner window ----------
function drawDimple(g, box, f) {
  const rows = [[], []];
  for (let i = 0; i < T.n; i++) rows[(T.elements[i][2] & 16) ? 1 : 0].push(i);
  // review V03: each row gets its own band (chambers, then the three label lines under them); before,
  // the side-row labels were drawn inside the main-row chambers
  const band = (box.h - 20) / 2;
  let mainBase = box.y + box.h - 60;
  rows.forEach((idxs, row) => {
    if (!idxs.length) return;
    const n = idxs.length;
    const cw = Math.min(90, box.w / (n + 1.5));
    const x0 = box.x + (box.w - cw * n) / 2 + cw * 0.25;
    const bandTop = box.y + 10 + (row === 1 ? 0 : band);   // side row on top, main row below
    const base = bandTop + band - 52;
    const H = (band - 52 - 20) / 1.75;
    if (row === 0) mainBase = base;
    g.fillStyle = '#ddd6c8'; g.fillRect(x0 - 20, base - H * 1.75 - 20, cw * n + 10, H * 1.75 + 30);
    idxs.forEach((i, k) => {
      const cx = x0 + k * cw, ew = cw * 0.42;
      const [lo, hi, variant] = T.elements[i];
      const spool = (variant & 15) === 1;
      const st = elState(f, i), p = elPos(f, i);
      g.fillStyle = '#f8f6f1'; g.fillRect(cx, base - H * 1.75 - 10, ew + 8, H * 1.75 + 10);
      g.strokeStyle = '#6b665c'; g.lineWidth = 1; g.strokeRect(cx, base - H * 1.75 - 10, ew + 8, H * 1.75 + 10);
      const len = Math.max(40, H * 0.4);
      const ylo = base - len - (lo / Q) * H, yhi = base - len - (hi / Q) * H;
      g.strokeStyle = '#2f5d7c'; g.lineWidth = 2; g.setLineDash([3, 3]);
      g.beginPath(); g.moveTo(cx - 6, ylo); g.lineTo(cx + ew + 14, ylo); g.moveTo(cx - 6, yhi); g.lineTo(cx + ew + 14, yhi); g.stroke();
      g.setLineDash([]);
      if (spool) {                                // inner pin: narrower window inside the sleeve window
        const ilo = lo + (hi - lo) * 0.3, ihi = hi - (hi - lo) * 0.3;
        const iylo = base - len - (ilo / Q) * H, iyhi = base - len - (ihi / Q) * H;
        g.strokeStyle = '#2f5d7c'; g.lineWidth = 1.5;
        g.beginPath(); g.moveTo(cx + 2, iylo); g.lineTo(cx + ew + 6, iylo); g.moveTo(cx + 2, iyhi); g.lineTo(cx + ew + 6, iyhi); g.stroke();
      }
      const top = base - len - p * H;
      body(g, st, cx + 4, top, ew, len, 'pin');
      if (spool) { g.fillStyle = '#efebe2'; g.fillRect(cx + 4 + ew * 0.3, top + 4, ew * 0.4, len - 8); g.strokeStyle = '#23211d'; g.lineWidth = 1; g.strokeRect(cx + 4 + ew * 0.3, top + 4, ew * 0.4, len - 8); }
      elementLabel(g, i, st, cx + ew / 2 + 4, base + 16, `${p.toFixed(3)}${spool ? ' tel' : ''}${(variant & 16) ? ' side' : ''}`);
    });
    text(g, row === 1 ? 'side row' : 'main row', x0 - 26, base - H * 1.75 + 2, { size: 11, color: '#6b665c', align: 'right' });
  });
  drawPick(g, box.x + 40, 90, mainBase, 100, f);
  drawCore(g, box, f, 'plug');
}

// ---------- disc_detainer: disc stack in cross-section, side bar, both-way rotation, overturn ----------
function drawDiscs(g, box, f) {
  const n = T.n;
  const R = Math.min(box.h / 2 - 60, 130);
  const cw = Math.min(64, box.w / (n + 2));
  const x0 = box.x + (box.w - cw * n) / 2;
  const cy = box.y + box.h / 2 + 10;
  const pe = f[T.col.pick_element];
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * cw + cw / 2;
    const [lo, hi, falseGates] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    g.save();
    if (st === 'bound') g.translate(3, 0);
    stateFill(g, st);
    g.strokeStyle = '#23211d'; g.lineWidth = st === 'set' || st === 'overset' ? 3 : 2;
    g.setLineDash(st === 'near' ? [5, 3] : []);
    g.beginPath(); g.ellipse(cx, cy, cw * 0.32, R, 0, 0, Math.PI * 2); g.fill(); g.stroke();
    g.setLineDash([]);
    // 8 detent positions around the rim
    g.fillStyle = '#23211d';
    for (let k = 0; k < 8; k++) {
      const a = (k / 8) * Math.PI * 2;
      g.fillRect(cx + Math.sin(a) * cw * 0.32 - 1, cy - Math.cos(a) * R - 1, 2, 3);
    }
    // gate cutout on the rim, at the top when set
    const gc = LOCKVIZ_GEOM.gateCenter(lo, hi) - p;
    const nx = cx + Math.sin(LOCKVIZ_GEOM.wrap01(gc) * Math.PI * 2) * cw * 0.32;
    const ny = cy - Math.cos(LOCKVIZ_GEOM.wrap01(gc) * Math.PI * 2) * R;
    g.fillStyle = '#f8f6f1';
    g.beginPath(); g.arc(nx, ny, 5, 0, Math.PI * 2); g.fill(); g.stroke();
    g.restore();
    if (i === pe) { g.strokeStyle = '#4a4f55'; g.lineWidth = 3; g.strokeRect(cx - cw * 0.42, cy - R - 10, cw * 0.84, R * 2 + 14); text(g, 'pick', cx, cy - R - 14, { size: 11, color: '#6b665c', align: 'center' }); }
    elementLabel(g, i, st, cx, cy + R + 26, `${LOCKVIZ_GEOM.discDetent(p)}/8 ${(p).toFixed(3)}${falseGates ? ' fg' + falseGates : ''}`);
  }
  // side bar (listwa) above the stack: a tooth drops into each set disc's cutout
  const ly = cy - R - 24;
  g.fillStyle = '#4a4f55'; g.fillRect(x0 - 10, ly, cw * n + 20, 8);
  for (let i = 0; i < n; i++) {
    if (elState(f, i) === 'set') {
      const cx = x0 + i * cw + cw / 2;
      g.fillRect(cx - 5, ly + 8, 10, 14);
    }
  }
  text(g, 'side bar', x0 - 14, ly + 6, { size: 11, color: '#6b665c', align: 'right' });
  const lift = val(f, 'pick_lift');
  text(g, `disc turn ${lift >= 0 ? '+' : ''}${lift.toFixed(2)} (both ways)`, x0 - 14, ly - 10, { size: 11, color: '#6b665c', align: 'right' });
  drawCore(g, box, f, 'core');
}

// ---------- egyptian: wooden bolt with holes, gravity-falling pegs, wedge, bolt slide ----------
function drawEgyptian(g, box, f) {
  const n = T.n;
  const cw = Math.min(110, box.w / (n + 1.5));
  const x0 = box.x + (box.w - cw * n) / 2 + cw * 0.25;
  const base = box.y + box.h - 80, H = Math.min(box.h - 140, 200);
  const rot = val(f, 'core_rotation');
  // bolt slides right with hold progress (core_rotation)
  const bx = x0 - 20 + rot * 60, bw = cw * n + 40;
  g.fillStyle = '#ddd6c8'; g.fillRect(bx, base, bw, 30);
  g.strokeStyle = '#23211d'; g.lineWidth = 2; g.strokeRect(bx, base, bw, 30);
  text(g, `bolt ${(rot * 100).toFixed(0)}%`, bx + bw + 8, base + 20, { size: 11, color: '#6b665c' });
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * cw + cw / 2;
    const [lo, hi] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    g.fillStyle = '#efebe2'; g.beginPath(); g.arc(cx + rot * 60, base + 15, 9, 0, Math.PI * 2); g.fill(); g.stroke();   // hole in the bolt
    const ylo = base - 6 - (lo / Q) * H, yhi = base - 6 - (hi / Q) * H;                                                // set window
    g.strokeStyle = '#2f5d7c'; g.lineWidth = 2; g.setLineDash([3, 3]);
    g.beginPath(); g.moveTo(cx - 10, ylo); g.lineTo(cx + 10, ylo); g.moveTo(cx - 10, yhi); g.lineTo(cx + 10, yhi); g.stroke(); g.setLineDash([]);
    const top = base - 6 - p * H;
    body(g, st, cx - 9, top, 18, Math.max(30, H * 0.22), 'pin');                                                     // peg (falls by gravity)
    elementLabel(g, i, st, cx, base + 52, `${p.toFixed(3)}${st === 'overset' ? ' wedge' : ''}`);
  }
  drawPick(g, x0 - 20, cw, base + 34, H, f);
  drawCore(g, box, f, 'bolt');
}

// ---------- axial_slider: front view, radial sliders pressed inward, false notches ----------
function drawSliders(g, box, f) {
  const n = T.n;
  const R = Math.min(box.h / 2 - 82, box.w / 6, 170);   // review V03: room for the 3 label lines + pusher ring at 12 and 6 o'clock
  const cx = box.x + box.w / 2, cy = box.y + box.h / 2 + 8;
  const maxL = R * 0.62;
  const pe = f[T.col.pick_element];
  // gate plate ring
  g.fillStyle = '#ddd6c8'; g.beginPath(); g.arc(cx, cy, R, 0, Math.PI * 2); g.fill();
  g.strokeStyle = '#23211d'; g.lineWidth = 2; g.stroke();
  g.fillStyle = '#efebe2'; g.beginPath(); g.arc(cx, cy, R - maxL - 14, 0, Math.PI * 2); g.fill(); g.stroke();
  for (let i = 0; i < n; i++) {
    const a = LOCKVIZ_GEOM.sliderAngle(i, n);
    const [lo, hi, falseGates] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    const ux = Math.cos(a), uy = Math.sin(a);
    // window marks on the gate plate (radial dashed lines at depths lo and hi)
    g.strokeStyle = '#2f5d7c'; g.lineWidth = 2; g.setLineDash([3, 3]);
    for (const wv of [lo, hi]) {
      const rr = R - (wv / Q) * maxL;
      g.beginPath(); g.moveTo(cx + ux * (rr - 8), cy + uy * (rr - 8)); g.lineTo(cx + ux * (rr + 8), cy + uy * (rr + 8)); g.stroke();
    }
    g.setLineDash([]);
    if (falseGates) {
      g.strokeStyle = '#2f5d7c'; g.lineWidth = 1.5;
      for (let k = 1; k <= falseGates; k++) {
        const rr = R - ((hi / Q) + k * 0.05) * maxL;
        g.beginPath(); g.moveTo(cx + ux * rr - uy * 4, cy + uy * rr + ux * 4); g.lineTo(cx + ux * rr + uy * 4, cy + uy * rr - ux * 4); g.stroke();
      }
    }
    // slider: pressed radially inward, depth p
    const rOut = R - 6, rIn = R - p * maxL;
    g.save();
    if (st === 'bound') g.translate(3, 0);
    stateFill(g, st);
    g.strokeStyle = '#23211d'; g.lineWidth = st === 'set' || st === 'overset' ? 3 : 2;
    g.setLineDash(st === 'near' ? [5, 3] : []);
    g.beginPath();
    g.moveTo(cx + ux * rOut - uy * 12, cy + uy * rOut + ux * 12);
    g.lineTo(cx + ux * rIn - uy * 12, cy + uy * rIn + ux * 12);
    g.lineTo(cx + ux * rIn + uy * 12, cy + uy * rIn - ux * 12);
    g.lineTo(cx + ux * rOut + uy * 12, cy + uy * rOut - ux * 12);
    g.closePath(); g.fill(); g.stroke();
    g.restore();
    if (i === pe) {
      g.strokeStyle = '#4a4f55'; g.lineWidth = 3;
      g.beginPath(); g.arc(cx + ux * (R + 12), cy + uy * (R + 12), 8, 0, Math.PI * 2); g.stroke();
    }
    // review V03: the 3-line label block (baseline y-11 .. y+31) is centred on a point outside the ring,
    // so at 12 o'clock it no longer sits on the pusher ring; 'pusher' goes into the label
    const d = R + (i === pe ? 26 : 12) + 24;
    const lx = cx + ux * (d + 12 * Math.abs(ux)), ly = cy + uy * d - 10;
    elementLabel(g, i, st, lx, ly, `${p.toFixed(2)}${falseGates ? ' fg' + falseGates : ''}${i === pe ? ' · pusher' : ''}`);
  }
  // core hub rotates with core_rotation
  const rot = val(f, 'core_rotation');
  g.fillStyle = '#f8f6f1'; g.strokeStyle = '#23211d'; g.lineWidth = 2;
  g.beginPath(); g.arc(cx, cy, 20, 0, Math.PI * 2); g.fill(); g.stroke();
  const a = rot * Math.PI * 2;
  g.lineWidth = 3; g.beginPath(); g.moveTo(cx, cy); g.lineTo(cx + Math.cos(a) * 16, cy + Math.sin(a) * 16); g.stroke();
  text(g, `press ${val(f, 'pick_lift').toFixed(2)} (inward)`, box.x + 16, box.y + box.h - 12, { size: 11, color: '#6b665c' });
  drawCore(g, box, f, 'core');
}

// ---------- time_lock: gear train in order, spring band, time.tick rhythm axis, run progress ----------
function drawTimeLock(g, box, f) {
  const n = T.n;
  const rg = Math.min(38, box.w / (n * 2.7), box.h / 4.4);
  const cy = box.y + box.h / 2 - 26;
  const x0 = box.x + (box.w - n * rg * 2.2) / 2 + rg * 1.1;
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * rg * 2.2;
    const st = elState(f, i), p = elPos(f, i);
    const [lo, hi] = T.elements[i];
    g.save();
    if (st === 'bound') g.translate(3, 0);
    stateFill(g, st);
    g.strokeStyle = '#23211d'; g.lineWidth = st === 'set' ? 3 : 2; g.setLineDash(st === 'near' ? [5, 3] : []);
    g.beginPath(); g.arc(cx, cy, rg * 0.8, 0, Math.PI * 2); g.fill(); g.stroke(); g.setLineDash([]);
    for (let k = 0; k < 8; k++) {                 // teeth
      const a = (k / 8) * Math.PI * 2 + (i % 2) * Math.PI / 8;
      g.fillStyle = '#23211d';
      g.fillRect(cx + Math.cos(a) * rg * 0.8 - 2, cy + Math.sin(a) * rg * 0.8 - 2, 4, 4);
    }
    g.fillStyle = '#efebe2'; g.beginPath(); g.arc(cx, cy, rg * 0.3, 0, Math.PI * 2); g.fill(); g.stroke();
    g.restore();
    // seat depth window on the axle below
    const wy = cy + rg + 18;
    g.strokeStyle = '#2f5d7c'; g.lineWidth = 2; g.setLineDash([3, 3]);
    g.beginPath(); g.moveTo(cx - (lo / Q) * rg, wy); g.lineTo(cx - (hi / Q) * rg, wy); g.stroke(); g.setLineDash([]);
    g.fillStyle = '#4a4f55'; g.fillRect(cx - (p) * rg - 2, wy - 6, 4, 12);
    elementLabel(g, i, st, cx, cy + rg + 40, `${p.toFixed(2)} meshed ${i}`);
  }
  text(g, 'gear train (wheel 0 first)', x0 - rg, cy - rg - 12, { size: 11, color: '#6b665c' });
  // rhythm axis: time.tick marks up to the cursor + hold_progress run bar
  const axY = box.y + box.h - 46, axX = box.x + 40, axW = box.w - 80;
  g.strokeStyle = '#23211d'; g.lineWidth = 1.5;
  g.beginPath(); g.moveTo(axX, axY); g.lineTo(axX + axW, axY); g.stroke();
  const tEnd = cur / T.step_hz;
  for (const e of T.ev) {
    if (e.name !== 'time.tick' || e.t > cur) continue;
    const x = axX + (e.t / T.step_hz / Math.max(1, T.frames.length / T.step_hz)) * axW;
    g.strokeStyle = '#23211d'; g.lineWidth = 2;
    g.beginPath(); g.moveTo(x, axY - 7); g.lineTo(x, axY + 7); g.stroke();
  }
  const hp = val(f, 'hold_progress');
  g.fillStyle = '#3b4f5e'; g.fillRect(axX, axY - 3, hp * axW, 6);
  text(g, `time.tick rhythm · run ${(hp * 100).toFixed(0)}% · wind T=${val(f, 'tension').toFixed(2)}`, axX, axY + 20, { size: 11, color: '#6b665c' });
  drawCore(g, box, f, 'run');
}

// ---------- magnetic: pins, probe thumb vs lagging field line ----------
function drawMagnetic(g, box, f) {
  const n = T.n, cw = Math.min(90, box.w / (n + 1.5));
  const x0 = box.x + (box.w - cw * n) / 2 + cw * 0.25;
  const base = box.y + box.h - 70, H = Math.min((box.h - 110) * 0.55, 240);
  g.fillStyle = '#ddd6c8'; g.fillRect(x0 - 20, base - H * 1.75 - 20, cw * n + 10, H * 1.75 + 30);
  for (let i = 0; i < n; i++) {
    const cx = x0 + i * cw, ew = cw * 0.42;
    const [lo, hi] = T.elements[i];
    const st = elState(f, i), p = elPos(f, i);
    g.fillStyle = '#f8f6f1'; g.fillRect(cx, base - H * 1.75 - 10, ew + 8, H * 1.75 + 10);
    g.strokeStyle = '#6b665c'; g.lineWidth = 1; g.strokeRect(cx, base - H * 1.75 - 10, ew + 8, H * 1.75 + 10);
    const len = Math.max(40, H * 0.4);
    const ylo = base - len - (lo / Q) * H, yhi = base - len - (hi / Q) * H;
    g.strokeStyle = '#2f5d7c'; g.lineWidth = 2; g.setLineDash([3, 3]);
    g.beginPath(); g.moveTo(cx - 6, ylo); g.lineTo(cx + ew + 14, ylo); g.moveTo(cx - 6, yhi); g.lineTo(cx + ew + 14, yhi); g.stroke(); g.setLineDash([]);
    const top = base - len - p * H;
    body(g, st, cx + 4, top, ew, len, 'pin');
    elementLabel(g, i, st, cx + ew / 2 + 4, base + 44, p.toFixed(3));
  }
  // probe: thumb target vs the lagging field — the visible gap is the field delay
  const thumb = val(f, 'pick_lift'), field = val(f, 'view_pick_lift');
  const yThumb = base - thumb * H * 0.5, yField = base - field * H * 0.5;
  g.strokeStyle = '#4a4f55'; g.lineWidth = 4; g.lineCap = 'round';
  const pe = f[T.col.pick_element];
  const tipX = pe >= 0 ? x0 + pe * cw + cw * 0.21 + 4 : x0 + val(f, 'pick_depth') * cw * T.n;
  g.beginPath(); g.moveTo(x0 - 60, yThumb + 22); g.lineTo(tipX - 6, yThumb + 22); g.lineTo(tipX, yThumb); g.stroke();
  g.lineCap = 'butt';
  g.strokeStyle = '#23211d'; g.lineWidth = 2; g.setLineDash([6, 4]);
  g.beginPath(); g.moveTo(x0 - 20, yField); g.lineTo(x0 + cw * n + 20, yField); g.stroke(); g.setLineDash([]);
  text(g, `field ${field.toFixed(2)}`, x0 + cw * n + 24, yField + 4, { size: 11, color: '#6b665c' });
  text(g, `thumb ${thumb.toFixed(2)} · lag ${LOCKVIZ_GEOM.fieldLag(thumb, field).toFixed(3)}`, x0 - 66, yThumb + 20, { size: 11, color: '#6b665c', align: 'right' });
  drawCore(g, box, f, 'plug');
}

const FAMILY_DRAW_V06 = {
  dial_safe: drawDialSafe,
  combo: drawCombo,
  dimple: drawDimple,
  disc_detainer: drawDiscs,
  egyptian: drawEgyptian,
  axial_slider: drawSliders,
  time_lock: drawTimeLock,
  magnetic: drawMagnetic,
};

globalThis.LOCKVIZ_GEOM = LOCKVIZ_GEOM;
globalThis.FAMILY_DRAW_V06 = FAMILY_DRAW_V06;
