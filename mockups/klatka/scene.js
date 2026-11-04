// Direction "Klatka schodowa" — physically lit cutaway, three.js. Mockup tool only, not game code.
// World units = dp of the 412-wide section; y grows DOWN in our layout coordinates, converted with Y().
import * as THREE from '../node_modules/three/build/three.module.js';
import { RoomEnvironment } from '../node_modules/three/examples/jsm/environments/RoomEnvironment.js';
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
    steel: new THREE.MeshStandardMaterial({ color: 0xc4c5c1, metalness: 0.8, roughness: 0.55, roughnessMap: brushedRough(1, 125) }),
    // brass plug & key pins: mid value, warmer, slightly rougher (aged)
    brass: new THREE.MeshStandardMaterial({ color: 0xb89252, metalness: 0.8, roughness: 0.58, roughnessMap: brushedRough(2, 120, Math.PI / 2) }),
    // iron: dark, very rough, almost non-reflective (driver pins of security type / door hardware)
    iron: new THREE.MeshStandardMaterial({ color: 0x3e3b37, metalness: 0.55, roughness: 0.82 }),
    // driver pins: hardened steel, darker than housing so they separate inside the steel chamber
    driver: new THREE.MeshStandardMaterial({ color: 0x9fa2a3, metalness: 0.75, roughness: 0.42, roughnessMap: brushedRough(5, 100) }),
    spring: new THREE.MeshStandardMaterial({ color: 0xa8aaaa, metalness: 0.8, roughness: 0.45 }),
    recess: new THREE.MeshStandardMaterial({ color: 0x15130f, metalness: 0.0, roughness: 1.0 }),
    pick: new THREE.MeshStandardMaterial({ color: 0xe6e6e2, metalness: 0.7, roughness: 0.38 }),
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
export function stairwellLights(scene, target = [206, -190, 0], renderer) {
  if (renderer) { const pm = new THREE.PMREMGenerator(renderer); scene.environment = pm.fromScene(new RoomEnvironment(), 0.04).texture; scene.environmentIntensity = 0.55; }
  scene.add(new THREE.HemisphereLight(0xcfd6e0, 0x3a2a1c, 0.5));
  const key = new THREE.SpotLight(0xffd7a8, 5e5, 0, Math.PI / 5, 0.7, 2);
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

// ---------- stairwell set (menu, job card) ----------
function canvasTex(w, h, draw, srgb = true) { const c = document.createElement('canvas'); c.width = w; c.height = h; draw(c.getContext('2d'), w, h); const t = new THREE.CanvasTexture(c); if (srgb) t.colorSpace = THREE.SRGBColorSpace; return t; }

export function lamperiaTexture() {
  // lower wall oil-painted green, dividing stripe, upper distemper; scuffs and a light-switch shadow
  return canvasTex(1024, 1024, (g, w, h) => {
    const r = rng(9);
    g.fillStyle = '#d9d2c2'; g.fillRect(0, 0, w, h);
    for (let i = 0; i < 3000; i++) { g.fillStyle = `rgba(120,110,95,${r() * 0.05})`; g.fillRect(r() * w, r() * h * 0.45, 2 + r() * 6, 2 + r() * 6); }
    g.fillStyle = '#3f5a4c'; g.fillRect(0, h * 0.45, w, h * 0.55);
    for (let i = 0; i < 1200; i++) { g.fillStyle = `rgba(${r() < .5 ? '20,30,25' : '120,140,125'},${r() * 0.08})`; g.fillRect(r() * w, h * 0.45 + r() * h * 0.55, 1 + r() * 30, 1 + r() * 2); }
    g.fillStyle = '#7a2e22'; g.fillRect(0, h * 0.445, w, 10);
    // scuffs at shoulder/handrail height
    for (let i = 0; i < 25; i++) { g.strokeStyle = `rgba(200,200,180,${0.05 + r() * 0.1})`; g.lineWidth = 1 + r() * 3; g.beginPath(); const x = r() * w, y = h * (0.55 + r() * 0.2); g.moveTo(x, y); g.lineTo(x + 30 + r() * 120, y + (r() - .5) * 8); g.stroke(); }
  });
}
export function tileTexture() {
  // cement tiles, two-tone checker typical for tenement stairwells, worn
  return canvasTex(512, 512, (g, w, h) => {
    const r = rng(21), n = 8, s = w / n;
    for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) { const dark = (i + j) % 2; const v = dark ? [96, 52, 40] : [196, 184, 160]; const k = (r() - .5) * 18; g.fillStyle = `rgb(${v[0] + k},${v[1] + k},${v[2] + k})`; g.fillRect(i * s, j * s, s, s); }
    for (let i = 0; i < 4000; i++) { g.fillStyle = `rgba(0,0,0,${r() * 0.06})`; g.fillRect(r() * w, r() * h, 1.5, 1.5); }
    g.strokeStyle = 'rgba(40,30,20,.5)'; g.lineWidth = 1.2; for (let i = 0; i <= n; i++) { g.beginPath(); g.moveTo(i * s, 0); g.lineTo(i * s, h); g.stroke(); g.beginPath(); g.moveTo(0, i * s); g.lineTo(w, i * s); g.stroke(); }
  });
}
export function enamelTexture(text, sub = '') {
  return canvasTex(512, 256, (g, w, h) => {
    g.fillStyle = '#1e2a33'; g.fillRect(0, 0, w, h);
    g.fillStyle = '#f3efe6'; g.beginPath(); g.roundRect(10, 10, w - 20, h - 20, 26); g.fill();
    g.fillStyle = '#1e2a33'; g.beginPath(); g.roundRect(22, 22, w - 44, h - 44, 18); g.fill();
    g.fillStyle = '#f3efe6'; g.font = '700 150px "Bona Nova"'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(text, w / 2, h / 2 + 8);
    // chips in the enamel
    g.fillStyle = '#2b2622'; [[60, 40, 14], [470, 210, 10], [455, 52, 6]].forEach(([x, y, r]) => { g.beginPath(); g.arc(x, y, r, 0, 7); g.fill(); });
  });
}

export function buildStairwell(S, M, { doorNo = '14', ajar = false } = {}) {
  const wallM = new THREE.MeshStandardMaterial({ map: lamperiaTexture(), roughness: 0.85 });
  const wall = new THREE.Mesh(new THREE.PlaneGeometry(3200, 900), wallM); wall.position.set(0, 300, -2); wall.receiveShadow = true; S.add(wall);
  const tex = tileTexture(); tex.wrapS = tex.wrapT = THREE.RepeatWrapping; tex.repeat.set(11, 3);
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(3200, 600), new THREE.MeshStandardMaterial({ map: tex, roughness: 0.7 }));
  floor.rotation.x = -Math.PI / 2; floor.position.set(0, -150, 290); floor.receiveShadow = true; S.add(floor);
  // door frame + leaf with two raised panels
  const doorM = new THREE.MeshStandardMaterial({ map: woodTexture(512, 1024, 4, [104, 62, 36]), roughness: 0.6 });
  const g = new THREE.Group(); S.add(g);
  const frame = new RoundedBoxGeometry(250, 440, 16, 2, 3); frame.translate(0, 70, 4); const fr = new THREE.Mesh(frame, doorM); fr.receiveShadow = true; g.add(fr);
  const leafPivot = new THREE.Group(); leafPivot.position.set(-105, 0, 12); g.add(leafPivot);
  const leaf = new THREE.Group(); leaf.position.set(105, 0, 0); leafPivot.add(leaf);
  const lb = new THREE.Mesh(new RoundedBoxGeometry(210, 410, 10, 2, 2), doorM); lb.position.set(0, 62, 0); lb.castShadow = lb.receiveShadow = true; leaf.add(lb);
  for (const [y, h] of [[150, 150], [-30, 170]]) { const p = new THREE.Mesh(new RoundedBoxGeometry(160, h, 8, 3, 3), doorM); p.position.set(0, y, 6); p.castShadow = true; leaf.add(p); }
  const plate = new THREE.Mesh(new THREE.BoxGeometry(56, 28, 2), new THREE.MeshStandardMaterial({ map: enamelTexture(doorNo), roughness: 0.2, metalness: 0 })); plate.position.set(0, 250, 11); leaf.add(plate);
  const esc = new THREE.Mesh(new RoundedBoxGeometry(22, 80, 4, 2, 2), M.iron); esc.position.set(80, 20, 8); esc.castShadow = true; leaf.add(esc);
  const cyl = new THREE.Mesh(new THREE.CylinderGeometry(6, 6, 4, 32).rotateX(Math.PI / 2), M.brass); cyl.position.set(80, 0, 11); leaf.add(cyl);
  const handle = new THREE.Mesh(new THREE.CylinderGeometry(3, 3, 34, 16).rotateZ(Math.PI / 2), M.iron); handle.position.set(66, 40, 18); handle.castShadow = true; leaf.add(handle);
  if (ajar) leafPivot.rotation.y = -0.5;
  // doormat
  const mat = new THREE.Mesh(new RoundedBoxGeometry(170, 3, 80, 2, 1), new THREE.MeshStandardMaterial({ color: 0x5a4632, roughness: 1 })); mat.position.set(0, -148, 50); mat.receiveShadow = true; S.add(mat);
  // stair light timer switch (minutnik) on the wall
  const sw = new THREE.Mesh(new RoundedBoxGeometry(22, 30, 6, 2, 2), new THREE.MeshStandardMaterial({ color: 0xe9e4d8, roughness: 0.5 })); sw.position.set(160, 40, 2); sw.castShadow = true; S.add(sw);
  const btn = new THREE.Mesh(new THREE.CylinderGeometry(6, 6, 3, 24).rotateX(Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0xe0b04a, emissive: 0x6b4a10, emissiveIntensity: 0.6, roughness: 0.4 })); btn.position.set(160, 40, 6); S.add(btn);
  return { leafPivot };
}
