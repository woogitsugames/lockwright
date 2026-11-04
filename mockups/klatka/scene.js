// Direction "Klatka schodowa" — physically lit cutaway, three.js. Mockup tool only, not game code.
// World units = dp of the 412-wide section; y grows DOWN in our layout coordinates, converted with Y().
import * as THREE from '../node_modules/three/build/three.module.js';
import { RoundedBoxGeometry } from '../node_modules/three/examples/jsm/geometries/RoundedBoxGeometry.js';

export const Y = y => -y;

// ---------- procedural textures (own work) ----------
function rng(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }

export function woodTexture(w = 512, h = 512, seed = 7, base = [92, 58, 34]) {
  const c = document.createElement('canvas'); c.width = w; c.height = h; const g = c.getContext('2d'); const r = rng(seed);
  g.fillStyle = `rgb(${base})`; g.fillRect(0, 0, w, h);
  for (let i = 0; i < 260; i++) {
    const y0 = r() * h, a = 2 + r() * 6, f = 0.004 + r() * 0.01, d = (r() - 0.5) * 40, l = r() * 0.25;
    g.strokeStyle = `rgba(${r() < 0.5 ? '30,16,8' : '150,105,70'},${0.10 + l})`; g.lineWidth = 0.6 + r() * 2.2; g.beginPath();
    for (let x = 0; x <= w; x += 8) g.lineTo(x, y0 + Math.sin(x * f + d) * a + Math.sin(x * f * 3.1) * a * 0.3);
    g.stroke();
  }
  // wear: lighter rub marks
  for (let i = 0; i < 40; i++) { g.fillStyle = `rgba(200,160,110,${0.03 + r() * 0.05})`; g.fillRect(r() * w, r() * h, 20 + r() * 80, 1 + r() * 3); }
  const t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; t.wrapS = t.wrapT = THREE.RepeatWrapping; return t;
}

// brushed/satin roughness map: fine directional scratches + a few deep ones (wear)
export function brushedRough(seed = 3, base = 150, dir = 0) {
  const n = 256, c = document.createElement('canvas'); c.width = c.height = n; const g = c.getContext('2d'); const r = rng(seed);
  g.fillStyle = `rgb(${base},${base},${base})`; g.fillRect(0, 0, n, n);
  g.save(); if (dir) { g.translate(n / 2, n / 2); g.rotate(dir); g.translate(-n / 2, -n / 2); }
  for (let i = 0; i < 900; i++) { const v = base + (r() - 0.5) * 70; g.strokeStyle = `rgb(${v},${v},${v})`; g.lineWidth = r() * 1.2; const y = r() * n * 1.4 - n * 0.2; g.beginPath(); g.moveTo(-20, y); g.lineTo(n + 20, y + (r() - 0.5) * 4); g.stroke(); }
  g.restore();
  for (let i = 0; i < 14; i++) { g.strokeStyle = 'rgb(235,235,235)'; g.lineWidth = 0.8; g.beginPath(); const x = r() * n, y = r() * n; g.moveTo(x, y); g.lineTo(x + (r() - 0.5) * 60, y + (r() - 0.5) * 20); g.stroke(); }
  const t = new THREE.CanvasTexture(c); t.wrapS = t.wrapT = THREE.RepeatWrapping; return t;
}

// ---------- materials: separated by VALUE + roughness/texture, not hue only ----------
export function materials() {
  return {
    // steel housing: light, satin, cool-neutral
    steel: new THREE.MeshStandardMaterial({ color: 0xb9bab6, metalness: 0.85, roughness: 0.48, roughnessMap: brushedRough(1, 125) }),
    // brass plug & key pins: mid value, warmer, slightly rougher (aged)
    brass: new THREE.MeshStandardMaterial({ color: 0xb08a4c, metalness: 0.9, roughness: 0.42, roughnessMap: brushedRough(2, 120, Math.PI / 2) }),
    // iron: dark, very rough, almost non-reflective (driver pins of security type / door hardware)
    iron: new THREE.MeshStandardMaterial({ color: 0x3e3b37, metalness: 0.55, roughness: 0.82 }),
    // driver pins: hardened steel, darker than housing so they separate inside the steel chamber
    driver: new THREE.MeshStandardMaterial({ color: 0x7c7f80, metalness: 0.9, roughness: 0.36, roughnessMap: brushedRough(5, 100) }),
    spring: new THREE.MeshStandardMaterial({ color: 0x9a9c9c, metalness: 0.9, roughness: 0.3 }),
    recess: new THREE.MeshStandardMaterial({ color: 0x1b1916, metalness: 0.2, roughness: 0.95 }),
    pick: new THREE.MeshStandardMaterial({ color: 0xdcdcd8, metalness: 0.95, roughness: 0.25 }),
    handle: new THREE.MeshStandardMaterial({ color: 0x7a2a1c, metalness: 0.0, roughness: 0.7 }),
    wood: new THREE.MeshStandardMaterial({ map: woodTexture(), roughness: 0.78, metalness: 0 }),
    leather: new THREE.MeshStandardMaterial({ map: woodTexture(512, 256, 11, [70, 44, 30]), roughness: 0.9 }),
  };
}

// ---------- geometry helpers ----------
export function plateWithHoles(x0, y0, x1, y1, holes, depth) {
  const s = new THREE.Shape();
  s.moveTo(x0, Y(y0)); s.lineTo(x1, Y(y0)); s.lineTo(x1, Y(y1)); s.lineTo(x0, Y(y1)); s.lineTo(x0, Y(y0));
  for (const [hx, hy, hw, hh] of holes) {
    const p = new THREE.Path(); p.moveTo(hx, Y(hy)); p.lineTo(hx, Y(hy + hh)); p.lineTo(hx + hw, Y(hy + hh)); p.lineTo(hx + hw, Y(hy)); p.lineTo(hx, Y(hy)); s.holes.push(p);
  }
  const g = new THREE.ExtrudeGeometry(s, { depth, bevelEnabled: true, bevelThickness: 0.8, bevelSize: 0.8, bevelSegments: 2, curveSegments: 4 });
  g.translate(0, 0, -depth);
  return g;
}

export function spring(cx, yTop, yBot, coils, r = 11, wire = 1.7) {
  class Helix extends THREE.Curve { getPoint(t) { const a = t * coils * Math.PI * 2; return new THREE.Vector3(cx + Math.cos(a) * r, Y(yTop + (yBot - yTop) * t), -15 + Math.sin(a) * r); } }
  return new THREE.TubeGeometry(new Helix(), Math.max(64, coils * 24), wire, 6, false);
}

// lathe profile given as [radius, y] pairs along the pin axis (y in layout coords, downward)
export function lathe(cx, profile) {
  const pts = profile.map(([r, y]) => new THREE.Vector2(r, Y(y)));
  const g = new THREE.LatheGeometry(pts, 40); g.translate(cx, 0, -15); return g;
}
export function driverPin(cx, y0, h = 46, r = 14.5) { return lathe(cx, [[0, y0], [r - 1.5, y0], [r, y0 + 1.5], [r, y0 + h - 1.5], [r - 1.5, y0 + h], [0, y0 + h]]); }
export function spoolPin(cx, y0, h = 62, r = 14.5, waist = 8) {
  return lathe(cx, [[0, y0], [r - 1.5, y0], [r, y0 + 1.5], [r, y0 + 16], [waist, y0 + 26], [waist, y0 + 36], [r, y0 + 46], [r, y0 + h - 1.5], [r - 1.5, y0 + h], [0, y0 + h]]);
}
export function keyPin(cx, y0, h, r = 12) {
  const pr = [[0, y0], [r - 1, y0], [r, y0 + 1]]; const tip = y0 + h;
  for (let i = 0; i <= 8; i++) { const a = (i / 8) * Math.PI / 2; pr.push([r * Math.cos(a), tip - 8 + 8 * Math.sin(a)]); }
  return lathe(cx, pr);
}

export function flatPath(points, width = 5, thick = 2.2) {
  // flat strip (pick blade) following a 2D polyline in layout coords
  const curve = new THREE.CatmullRomCurve3(points.map(([x, y]) => new THREE.Vector3(x, Y(y), -10)));
  const g = new THREE.TubeGeometry(curve, 80, width / 2, 8, false);
  g.scale(1, 1, thick / width); return g;
}

export function makeRenderer(canvas, w, h) {
  const r = new THREE.WebGLRenderer({ canvas, antialias: true, preserveDrawingBuffer: true });
  r.setPixelRatio(window.devicePixelRatio || 1); r.setSize(w, h, false);
  r.outputColorSpace = THREE.SRGBColorSpace; r.toneMapping = THREE.ACESFilmicToneMapping; r.toneMappingExposure = 1.05;
  r.shadowMap.enabled = true; r.shadowMap.type = THREE.PCFSoftShadowMap;
  return r;
}

// warm stairwell bulb (key), cool landing window (fill). No bloom, no env-map chrome.
export function stairwellLights(scene, target = [206, -190, 0]) {
  scene.add(new THREE.HemisphereLight(0xcfd6e0, 0x3a2a1c, 0.9));
  const key = new THREE.SpotLight(0xffd7a8, 9e5, 0, Math.PI / 5, 0.6, 2);
  key.position.set(-220, 380, 520); key.target.position.set(...target); key.castShadow = true; key.shadow.mapSize.set(2048, 2048); key.shadow.bias = -0.0005;
  scene.add(key, key.target);
  const fill = new THREE.DirectionalLight(0xbfd0e6, 0.55); fill.position.set(600, 100, 300); scene.add(fill);
  return key;
}

export function orthoCamera(x0, x1, yTop, yBot, yaw = -0.16, pitch = 0.07) {
  const cam = new THREE.OrthographicCamera(x0, x1, Y(yTop), Y(yBot), -2000, 2000);
  // rotate around section centre for a 2.5D read of extrusion depth
  const cx = (x0 + x1) / 2, cy = (Y(yTop) + Y(yBot)) / 2;
  const w = (x1 - x0) / 2, h = (Y(yTop) - Y(yBot)) / 2;
  cam.left = -w; cam.right = w; cam.top = h; cam.bottom = -h;
  cam.position.set(cx + Math.sin(yaw) * 1000, cy + Math.sin(pitch) * 1000, Math.cos(yaw) * 1000);
  cam.lookAt(cx, cy, 0); cam.updateProjectionMatrix();
  return cam;
}

// project layout point to CSS px of the canvas (for chalk overlay)
export function projector(cam, cssW, cssH) {
  return (x, y, z = 0) => { const v = new THREE.Vector3(x, Y(y), z).project(cam); return [(v.x + 1) / 2 * cssW, (1 - v.y) / 2 * cssH]; };
}

export { THREE };
