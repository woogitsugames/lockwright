// Lockwright haptics preview. No frameworks; data from out/preview_data.js (window.LW_HAPTICS).
(function () {
  "use strict";
  const D = window.LW_HAPTICS;
  const $ = (id) => document.getElementById(id);
  const css = getComputedStyle(document.documentElement);
  const C = {
    text: css.getPropertyValue("--text").trim(), muted: css.getPropertyValue("--muted").trim(),
    line: css.getPropertyValue("--line").trim(), accent: css.getPropertyValue("--accent").trim(),
    play: css.getPropertyValue("--accent-2").trim(),
  };
  const TIER_LABEL = { a4: "A4 Builder", a3: "A3 Envelope", a2: "A2 Composition", a1: "A1 Amplituda", a0: "A0 on/off" };
  if (!D) { $("status").textContent = "Brak out/preview_data.js: uruchom python3 haptics/build.py"; return; }

  let audioCtx = null;
  const bufferCache = new Map();
  let playStart = null, playSpan = 0, rafId = 0;

  // ---------- helpers
  function opt(sel, values, labels) {
    sel.innerHTML = "";
    values.forEach((v, i) => { const o = document.createElement("option"); o.value = v; o.textContent = labels ? labels[i] : v; sel.appendChild(o); });
  }
  function fitCanvas(cv) {
    const dpr = window.devicePixelRatio || 1;
    const w = cv.clientWidth, h = cv.clientHeight || cv.height;
    cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr);
    const g = cv.getContext("2d"); g.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { g, w, h };
  }
  function param(ev, id) { const p = (ev.EventParameters || []).find((x) => x.ParameterID === id); return p ? p.ParameterValue : null; }
  function curveAt(curves, id, tSec, dflt) {
    let v = dflt;
    for (const c of curves) {
      if (c.ParameterID !== id) continue;
      const pts = c.ParameterCurveControlPoints, t = tSec - c.Time;
      if (t < pts[0].Time) continue;
      v = pts[pts.length - 1].ParameterValue;
      for (let i = 0; i < pts.length - 1; i++) {
        if (t >= pts[i].Time && t <= pts[i + 1].Time) {
          const f = (t - pts[i].Time) / Math.max(1e-6, pts[i + 1].Time - pts[i].Time);
          v = pts[i].ParameterValue + f * (pts[i + 1].ParameterValue - pts[i].ParameterValue);
          break;
        }
      }
    }
    return v;
  }
  function ahapSpanMs(ahap) {
    let end = 0;
    for (const it of ahap.Pattern) {
      if (it.Event) end = Math.max(end, (it.Event.Time + (it.Event.EventDuration || 0.012)) * 1000);
      if (it.ParameterCurve) { const p = it.ParameterCurve.ParameterCurveControlPoints; end = Math.max(end, (it.ParameterCurve.Time + p[p.length - 1].Time) * 1000); }
    }
    return end;
  }

  // ---------- drawing
  function axes(g, w, h, spanMs, pad) {
    g.fillStyle = "#201b16"; g.fillRect(0, 0, w, h);
    g.strokeStyle = C.line; g.lineWidth = 2;
    g.beginPath(); g.moveTo(pad.l, h - pad.b); g.lineTo(w - pad.r, h - pad.b); g.moveTo(pad.l, pad.t); g.lineTo(pad.l, h - pad.b); g.stroke();
    g.fillStyle = C.muted; g.font = "13px ui-monospace, Menlo, monospace";
    const step = spanMs > 1500 ? 250 : spanMs > 600 ? 100 : 50;
    for (let t = 0; t <= spanMs; t += step) {
      const x = pad.l + (t / spanMs) * (w - pad.l - pad.r);
      g.fillText(String(t), x - 8, h - pad.b + 16);
      g.strokeStyle = "rgba(239,230,216,0.08)"; g.lineWidth = 1; g.beginPath(); g.moveTo(x, pad.t); g.lineTo(x, h - pad.b); g.stroke();
    }
    g.fillText("ms", w - pad.r - 18, h - 4);
    [0, 0.5, 1].forEach((v) => { const y = h - pad.b - v * (h - pad.t - pad.b); g.fillText(v.toFixed(1), 4, y + 4); });
  }

  function drawAhap(cv, ahap, spanMs, head) {
    const { g, w, h } = fitCanvas(cv);
    const pad = { l: 34, r: 12, t: 12, b: 26 };
    axes(g, w, h, spanMs, pad);
    const X = (ms) => pad.l + (ms / spanMs) * (w - pad.l - pad.r);
    const Y = (v) => h - pad.b - v * (h - pad.t - pad.b);
    const curves = ahap.Pattern.filter((p) => p.ParameterCurve).map((p) => p.ParameterCurve);
    const sharp = [];
    for (const it of ahap.Pattern) {
      if (!it.Event) continue;
      const e = it.Event, I = param(e, "HapticIntensity") || 0, S = param(e, "HapticSharpness") || 0, t0 = e.Time * 1000;
      if (e.EventType === "HapticContinuous") {
        const dur = e.EventDuration * 1000;
        g.fillStyle = "rgba(217,163,95,0.55)"; g.strokeStyle = C.accent; g.lineWidth = 2;
        g.beginPath(); g.moveTo(X(t0), Y(0));
        for (let k = 0; k <= 60; k++) { const t = t0 + (dur * k) / 60; g.lineTo(X(t), Y(I * curveAt(curves, "HapticIntensityControl", t / 1000, 1))); }
        g.lineTo(X(t0 + dur), Y(0)); g.closePath(); g.fill(); g.stroke();
        for (let k = 0; k <= 20; k++) { const t = t0 + (dur * k) / 20; sharp.push([t, Math.min(1, Math.max(0, S + curveAt(curves, "HapticSharpnessControl", t / 1000, 0)))]); }
      } else {
        const bw = Math.max(4, X(10) - X(0));
        g.fillStyle = C.accent; g.fillRect(X(t0) - bw / 2, Y(I), bw, Y(0) - Y(I));
        g.strokeStyle = C.text; g.lineWidth = 2; g.beginPath(); g.arc(X(t0), Y(S), 5, 0, Math.PI * 2); g.stroke();
        sharp.push([t0, S]);
      }
    }
    sharp.sort((a, b) => a[0] - b[0]);
    if (sharp.length > 1) {
      g.setLineDash([6, 5]); g.strokeStyle = C.text; g.lineWidth = 2; g.beginPath();
      sharp.forEach(([t, s], i) => (i ? g.lineTo(X(t), Y(s)) : g.moveTo(X(t), Y(s)))); g.stroke(); g.setLineDash([]);
    }
    if (head != null) { g.fillStyle = C.play; g.fillRect(X(head) - 2, pad.t, 4, h - pad.t - pad.b); }
  }

  function entryShapes(e) {
    // -> {bars: [[t, dur, I, label]], env: [[t, I]], note}
    const out = { bars: [], env: [], note: "" };
    if (!e) { out.note = "brak"; return out; }
    if (e.skip) { out.note = "pominięte: dźwięk + obraz"; return out; }
    if (e.folded) { out.note = "w ramach wzorca bazowego"; return out; }
    if (e.envelope) out.env = e.envelope.map((p) => [p[0], p[1]]);
    if (e.composition) e.composition.forEach((c, i) => out.bars.push([e.onset_ms[i], 12, c[1], c[0]]));
    if (e.tick) out.bars.push([0, 12, e.tick[1], e.tick[0]]);
    if (e.then) out.bars.push([e.envelope ? e.envelope[e.envelope.length - 1][0] : 0, 12, e.then[1], e.then[0]]);
    if (e.waveform) { let t = 0; e.waveform.timings.forEach((d, i) => { if (e.waveform.amps[i] > 0) out.bars.push([t, d, e.waveform.amps[i] / 255, "amp " + e.waveform.amps[i]]); t += d; }); }
    if (e.effect) out.bars.push([0, 12, e.effect === "EFFECT_CLICK" ? 0.9 : 0.3, e.effect]);
    if (e.on_ms) { out.bars.push([0, e.on_ms, 1, "on"]); if (e.second_on_ms) out.bars.push([e.on_ms + e.second_gap_ms, e.second_on_ms, 1, "on"]); }
    if (e.pattern_ms) { let t = 0; e.pattern_ms.forEach((d, i) => { if (i % 2 === 0) out.bars.push([t, d, 1, "on"]); t += d; }); }
    if (e.micro) out.bars.push([0, 10, e.micro[1], e.micro[0]]);
    const rep = e.repeat_interval_ms || e.tick_interval_ms || e.interval_ms;
    if (rep) out.note = "powtarzane co " + rep + " ms";
    if (e.limit_per_s) out.note += (out.note ? ", " : "") + "≤ " + e.limit_per_s + "/s";
    if (e.resistance_amp_boost_pct) out.note = "amplituda oporu +" + e.resistance_amp_boost_pct + "%";
    return out;
  }

  function drawEntry(cv, e, spanMs, head) {
    const { g, w, h } = fitCanvas(cv);
    g.fillStyle = "#201b16"; g.fillRect(0, 0, w, h);
    const pad = 6, X = (ms) => pad + (ms / spanMs) * (w - 2 * pad), Y = (v) => h - pad - v * (h - 2 * pad - 12);
    const s = entryShapes(e);
    g.strokeStyle = C.line; g.lineWidth = 2; g.beginPath(); g.moveTo(pad, h - pad); g.lineTo(w - pad, h - pad); g.stroke();
    if (s.env.length) {
      g.fillStyle = "rgba(217,163,95,0.45)"; g.beginPath(); g.moveTo(X(s.env[0][0]), Y(0));
      s.env.forEach(([t, i]) => g.lineTo(X(t), Y(i))); g.lineTo(X(s.env[s.env.length - 1][0]), Y(0)); g.closePath(); g.fill();
    }
    g.font = "12px ui-monospace, Menlo, monospace";
    const seen = {};
    s.bars.forEach(([t, d, i, lab]) => {
      const bw = Math.max(4, X(t + d) - X(t));
      g.fillStyle = C.accent; g.fillRect(X(t), Y(i), bw, Y(0) - Y(i));
      const row = (seen[t] = (seen[t] || 0) + 1) - 1;  // stack labels of primitives starting together
      g.fillStyle = C.text; g.fillText(lab, Math.min(X(t) + 2 + row * 4, w - 70), 12 + row * 12);
    });
    if (s.note) { g.fillStyle = C.muted; g.fillText(s.note, w - Math.min(w - 8, 8 + g.measureText(s.note).width), h - 10); }
    if (head != null) { g.fillStyle = C.play; g.fillRect(X(head) - 1, 0, 3, h); }
  }

  // ---------- state
  const famSel = $("family"), evSel = $("event"), varSel = $("variant"), nSel = $("sfxn");
  function cur() {
    const fam = D.families[famSel.value];
    const ev = fam.events[evSel.value];
    return { fam, ev, file: ev.ios[varSel.selectedIndex] || null };
  }
  function spanFor(c) {
    let s = c.file ? ahapSpanMs(c.file.ahap) : 0;
    (c.ev.sound || []).forEach((l) => { s = Math.max(s, l.delay_ms + (l.duration_ms || 120)); });
    return Math.max(300, Math.ceil((s + 60) / 50) * 50);
  }

  function renderAll(head) {
    const c = cur();
    playSpan = playSpan || spanFor(c);
    const span = playSpan;
    $("iosTitle").textContent = "iOS Core Haptics: " + famSel.value + " / " + evSel.value + (c.file ? "" : " (brak AHAP)");
    if (c.file) {
      drawAhap($("ios"), c.file.ahap, span, head);
      $("iosMeta").textContent = c.file.file + ": " + c.file.role + "\n" + (c.file.ahap.Metadata || {}).Description;
    } else {
      const { g, w, h } = fitCanvas($("ios")); g.fillStyle = "#201b16"; g.fillRect(0, 0, w, h);
      g.fillStyle = C.muted; g.font = "16px Georgia, serif";
      g.fillText(c.ev.status.startsWith("fold:") ? "Złożone we wzorzec „" + c.ev.status.slice(5) + "” (FEEL F-05): tylko dźwięk i obraz" : "Brak haptyki w trakcie zamka (dźwięk L4)", 16, 40);
      $("iosMeta").textContent = "";
    }
    // android
    const tb = $("android"), ch = $("chain");
    if (c.ev.android) {
      if (head == null) {
        tb.innerHTML = "<tr><th>Poziom</th><th>Wszystkie prymitywy</th><th>Tylko CLICK+TICK</th></tr>";
        D.tiers.forEach((t) => {
          const tr = document.createElement("tr");
          const sel = c.ev.android.selection[t], mn = c.ev.android.selection_min_primitives[t];
          tr.innerHTML = "<td>" + TIER_LABEL[t] + "</td><td><canvas data-t='" + t + "' data-k='full'></canvas><div class='mono muted'>#" + sel.index + " (" + sel.entry_tier + "): " + sel.summary + "</div></td><td><canvas data-t='" + t + "' data-k='min'></canvas><div class='mono muted'>#" + mn.index + " (" + mn.entry_tier + "): " + mn.summary + "</div></td>";
          tb.appendChild(tr);
        });
        ch.innerHTML = "<tr><th>#</th><th>tier</th><th>wpis</th></tr>";
        c.ev.android.chain.forEach((e, i) => {
          const tr = document.createElement("tr");
          tr.innerHTML = "<td class='mono'>" + i + "</td><td class='mono'>" + e.tier + "</td><td class='mono'>" + JSON.stringify(e) + "</td>";
          ch.appendChild(tr);
        });
      }
      tb.querySelectorAll("canvas").forEach((cv) => {
        const s = c.ev.android[cv.dataset.k === "full" ? "selection" : "selection_min_primitives"][cv.dataset.t];
        drawEntry(cv, s.index == null ? null : c.ev.android.chain[s.index], span, head);
      });
    } else if (head == null) {
      tb.innerHTML = "<tr><td class='muted'>Brak osobnego łańcucha (" + c.ev.status + ")</td></tr>"; ch.innerHTML = "";
    }
    if (head == null) {
      $("mod").textContent = c.ev.mod ? JSON.stringify(c.ev.mod, null, 1) : "brak (zdarzenie nie zmienia oporu)";
      $("sound").textContent = (c.ev.sound || []).map((l) => l.id + " / " + l.material + (l.material !== l.wanted_material ? " (zamiast " + l.wanted_material + ")" : "") + "  +" + l.delay_ms + " ms  " + l.gain_db + " dB" + (l.rate !== 1 ? "  pitch ×" + l.rate : "")).join("\n") || "brak";
    }
  }

  function onFamily() {
    const fam = D.families[famSel.value];
    const evs = Object.keys(fam.events).sort();
    opt(evSel, evs, evs.map((e) => e + (fam.events[e].essential ? "  (essential)" : "") + (fam.events[e].status !== "play" ? "  [" + fam.events[e].status + "]" : "")));
    onEvent();
  }
  function onEvent() {
    const c = cur();
    opt(varSel, c.ev.ios.map((f) => f.file.split("/").pop()));
    varSel.disabled = !c.ev.ios.length;
    const nmax = Math.max(1, ...(c.ev.sound || []).map((l) => l.variants));
    opt(nSel, Array.from({ length: nmax }, (_, i) => String(i + 1)));
    playSpan = 0; renderAll(null);
  }

  // ---------- audio
  async function loadBuffer(url) {
    if (bufferCache.has(url)) return bufferCache.get(url);
    const res = await fetch(url);
    if (!res.ok) throw new Error(res.status + " " + url);
    const buf = await audioCtx.decodeAudioData(await res.arrayBuffer());
    bufferCache.set(url, buf);
    return buf;
  }
  async function play() {
    const c = cur();
    $("status").textContent = "";
    const n = Number(nSel.value || 1);
    let scheduled = false;
    playSpan = spanFor(c);
    if (location.protocol === "file:") {
      $("status").textContent = "file://: dźwięk wymaga serwera (python3 -m http.server w katalogu repo). Animacja bez dźwięku.";
    } else {
      try {
        audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
        await audioCtx.resume();
        const layers = await Promise.all((c.ev.sound || []).map(async (l) => ({ l, buf: await loadBuffer(l.path.replace("{n}", String(Math.min(n, l.variants)))) })));
        layers.forEach(({ l, buf }) => { l.duration_ms = (buf.duration * 1000) / (l.rate || 1); });
        playSpan = spanFor(c);
        const t0 = audioCtx.currentTime + 0.05;
        layers.forEach(({ l, buf }) => {
          const src = audioCtx.createBufferSource(); src.buffer = buf; src.playbackRate.value = l.rate || 1;
          const gn = audioCtx.createGain(); gn.gain.value = Math.pow(10, (l.gain_db || 0) / 20);
          src.connect(gn).connect(audioCtx.destination); src.start(t0 + l.delay_ms / 1000);
        });
        scheduled = true;
        playStart = { kind: "audio", t0 };
      } catch (err) {
        $("status").textContent = "Dźwięk niedostępny (" + err.message + "). Animacja bez dźwięku.";
      }
    }
    if (!scheduled) playStart = { kind: "clock", t0: performance.now() + 50 };
    cancelAnimationFrame(rafId);
    const tick = () => {
      const ms = playStart.kind === "audio" ? (audioCtx.currentTime - playStart.t0) * 1000 : performance.now() - playStart.t0;
      if (ms > playSpan) { renderAll(null); return; }
      renderAll(Math.max(0, ms));
      rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);
  }

  // ---------- init
  const fams = Object.keys(D.families);
  opt(famSel, fams, fams.map((f) => f + " (" + D.families[f].material + ")"));
  famSel.addEventListener("change", onFamily);
  evSel.addEventListener("change", onEvent);
  varSel.addEventListener("change", () => { playSpan = 0; renderAll(null); });
  $("play").addEventListener("click", play);
  window.addEventListener("resize", () => renderAll(null));
  const q = new URLSearchParams(location.search);
  if (q.get("family") && D.families[q.get("family")]) famSel.value = q.get("family");
  onFamily();
  if (q.get("event") && D.families[famSel.value].events[q.get("event")]) { evSel.value = q.get("event"); onEvent(); }
})();
