// Pins diegetic text onto surfaces of a photoreal render.
// The Blender scene exports, next to the render, the projected corners (0..1, top-left origin) of every writable
// surface (slip, tag, card, phone screen). Each [data-anchor] element is laid out flat in "paper millimetres"
// (data-w x data-h CSS px) and mapped onto its quad with a projective matrix3d, so the text sits in the photo's
// perspective. [data-hit] elements become invisible touch targets over a quad's bounding box (min 48 x 48 px).
// The image is placed like CSS background-size: cover (portrait) / contain (landscape).
(function () {
  const stage = document.querySelector('[data-scene]');
  const img = stage.dataset.scene, meta = stage.dataset.anchors;
  window.__ready = false;

  // square [0,1]^2 -> quad (p0..p3: tl, tr, br, bl); returns 3x3 [a b c; d e f; g h 1] (column vector convention)
  function squareToQuad(p) {
    const [x0, y0] = p[0], [x1, y1] = p[1], [x2, y2] = p[2], [x3, y3] = p[3];
    const dx1 = x1 - x2, dx2 = x3 - x2, dy1 = y1 - y2, dy2 = y3 - y2;
    const sx = x0 - x1 + x2 - x3, sy = y0 - y1 + y2 - y3;
    const den = dx1 * dy2 - dx2 * dy1;
    const g = (sx * dy2 - dx2 * sy) / den, h = (dx1 * sy - sx * dy1) / den;
    return [x1 - x0 + g * x1, x3 - x0 + h * x3, x0, y1 - y0 + g * y1, y3 - y0 + h * y3, y0, g, h, 1];
  }
  function matrix3d(w, h, quad) {
    const [a, b, c, d, e, f, g, hh] = squareToQuad(quad);
    // pre-scale the element box (w x h) to the unit square
    const A = a / w, B = b / h, D = d / w, E = e / h, G = g / w, H = hh / h;
    return `matrix3d(${A},${D},0,${G},${B},${E},0,${H},0,0,1,0,${c},${f},0,1)`;
  }

  fetch(meta).then(r => r.json()).then(data => {
    const iw = data.width, ih = data.height;
    stage.style.backgroundImage = `url(${img})`;
    function layout() {
      const W = stage.clientWidth, H = stage.clientHeight;
      const s = (W > H ? Math.min : Math.max)(W / iw, H / ih);
      const ox = (W - iw * s) / 2, oy = (H - ih * s) / 2;
      stage.style.backgroundSize = `${iw * s}px ${ih * s}px`;
      stage.style.backgroundPosition = `${ox}px ${oy}px`;
      const px = ([u, v]) => [ox + u * iw * s, oy + v * ih * s];
      stage.querySelectorAll('[data-anchor]').forEach(el => {
        const q = data.anchors[el.dataset.anchor]; if (!q) return;
        const w = +el.dataset.w, h = +el.dataset.h;
        el.style.width = w + 'px'; el.style.height = h + 'px';
        el.style.transform = matrix3d(w, h, q.map(px));
      });
      stage.querySelectorAll('[data-hit]').forEach(el => {
        let q = data.anchors[el.dataset.hit]; if (!q) return;
        if (el.dataset.sub) {  // sub-rectangle of the quad in its own (u, v) units, bilinear
          const [u0, v0, u1, v1] = el.dataset.sub.split(',').map(Number);
          const at = (u, v) => [0, 1].map(i => (1 - u) * (1 - v) * q[0][i] + u * (1 - v) * q[1][i] + u * v * q[2][i] + (1 - u) * v * q[3][i]);
          q = [at(u0, v0), at(u1, v0), at(u1, v1), at(u0, v1)];
        }
        const P = q.map(px), xs = P.map(p => p[0]), ys = P.map(p => p[1]);
        const pad = +(el.dataset.pad || 0);
        let x0 = Math.min(...xs) - pad, x1 = Math.max(...xs) + pad, y0 = Math.min(...ys) - pad, y1 = Math.max(...ys) + pad;
        if (el.dataset.extend === 'down') y1 = Math.max(y1, Math.min(H, y1 + 48));
        const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2, w = Math.max(48, x1 - x0), h = Math.max(48, y1 - y0);
        Object.assign(el.style, { left: cx - w / 2 + 'px', top: cy - h / 2 + 'px', width: w + 'px', height: h + 'px' });
      });
    }
    layout(); addEventListener('resize', layout);
    const probe = new Image(); probe.onload = () => { window.__ready = true; }; probe.onerror = () => { window.__ready = true; }; probe.src = img;
  }).catch(() => { window.__ready = true; });
})();
