/* Shared kit for the event page explorations. Mirrors SinceEvent, the add
   card's motion (springs, blur swaps, Torph-style text morph) and its look. */
(function () {
  const HOUR = 36e5, DAY = 864e5;
  const P = "../../website/assets/patterns/";
  const THEMES = {
    Mosaic:  { bg: "#F1622A", accent: "#243721" },
    Eyes:    { bg: "#FA96A1", accent: "#F03234" },
    Circles: { bg: "#4D4AFD", accent: "#2C2B45" },
    Clouds:  { bg: "#4B800E", accent: "#BDD47E" },
    Puffs:   { bg: "#C09CF9", accent: "#2A1C57" },
    Waves:   { bg: "#0E7C7B", accent: "#8FE3CF" },
    Blooms:  { bg: "#D23C77", accent: "#FFD45E" },
    Steps:   { bg: "#1F1F24", accent: "#FF7A2F" },
  };
  const MILESTONES = [1, 7, 14, 30, 60, 90, 100, 180, 365, 500, 730];
  const GOALS = [0, 7, 14, 30, 60, 90, 100, 180, 365, 500, 730];
  const UNITS = ["days", "hours", "months", "years"];

  let SLOW = 1;
  const listeners = [];
  const emit = () => listeners.forEach((f) => f());

  // ---------- Mock event: fifth run, and currently the longest ----------
  const now0 = Date.now();
  const past = [ // oldest → newest
    { days: 3, extra: 7 * HOUR, note: "Friday drinks with the team" },
    { days: 11, extra: 2 * HOUR, note: null },
    { days: 6, extra: 15 * HOUR, note: "Wedding weekend" },
    { days: 18, extra: 5 * HOUR, note: "Deadline week" },
  ];
  const event = {
    title: "No caffeine",
    startedAt: now0 - (23 * DAY + 4 * HOUR + 17 * 6e4),
    goal: 30,
    unit: "days",
    reminder: { on: true, every: "day", time: "9:00 am" },
    runs: [], // newest first: { start, end, note }
    theme: "Waves",
  };
  (function buildRuns() {
    let cursor = event.startedAt;
    for (let i = past.length - 1; i >= 0; i--) {
      const s = past[i];
      const start = cursor - s.days * DAY - s.extra;
      event.runs.push({ start, end: cursor, note: s.note });
      cursor = start;
    }
    event.firstStartedAt = cursor;
  })();
  try { const t = localStorage.getItem("sinced-dv2-theme"); if (t && THEMES[t]) event.theme = t; } catch (e) {}

  // ---------- Time helpers ----------
  const elapsed = () => Date.now() - event.startedAt;
  function unitValue(unit, ms = elapsed()) {
    const d = ms / DAY;
    const v = unit === "hours" ? Math.floor(ms / HOUR) : unit === "months" ? Math.floor(d / 30) : unit === "years" ? Math.floor(d / 365) : Math.floor(d);
    const word = unit.slice(0, -1);
    return { v, word: v === 1 ? word : word + "s", text: v.toLocaleString("en-GB") + " " + (v === 1 ? word : word + "s") };
  }
  const days = (ms) => Math.floor(ms / DAY);
  function daysText(ms) { const n = days(ms); return n + (n === 1 ? " day" : " days"); }
  function fmt(ts, withYear) {
    const d = new Date(ts), same = d.getFullYear() === new Date().getFullYear();
    return d.toLocaleDateString("en-GB", Object.assign({ day: "numeric", month: "short" }, withYear || !same ? { year: "numeric" } : {}));
  }
  function monthShort(ts) { return new Date(ts).toLocaleDateString("en-GB", { month: "short" }); }
  function stats() {
    const lens = event.runs.map((r) => r.end - r.start);
    const cur = elapsed();
    const bestPast = Math.max(0, ...lens);
    return {
      current: cur, bestPast, best: Math.max(cur, bestPast), isBest: cur >= bestPast && lens.length > 0,
      average: (lens.reduce((a, b) => a + b, 0) + cur) / (lens.length + 1),
      resets: lens.length, runNo: lens.length + 1,
    };
  }
  function target() {
    const d = elapsed() / DAY;
    if (event.goal > d) return { kind: "goal", days: event.goal, left: Math.ceil(event.goal - d), progress: d / event.goal, date: event.startedAt + event.goal * DAY };
    const next = MILESTONES.find((m) => m > d) || 730;
    const prev = [0, ...MILESTONES].filter((m) => m <= d).pop();
    return { kind: event.goal ? "reached" : "milestone", days: next, left: Math.ceil(next - d), progress: (d - prev) / (next - prev), date: event.startedAt + next * DAY };
  }
  function reset(note, at = Date.now()) {
    const prevStart = event.startedAt;
    event.runs.unshift({ start: prevStart, end: at, note: note || null });
    event.startedAt = at;
    event.lastReset = { at, prevStart };
    emit();
  }
  function undoReset() {
    if (!event.lastReset) return false;
    event.runs.shift();
    event.startedAt = event.lastReset.prevStart;
    event.lastReset = null;
    emit();
    return true;
  }
  function setTheme(t) {
    event.theme = t;
    try { localStorage.setItem("sinced-dv2-theme", t); } catch (e) {}
    applyTheme(); emit();
  }
  function applyTheme() {
    const r = document.documentElement.style, t = THEMES[event.theme];
    r.setProperty("--t-bg", t.bg); r.setProperty("--t-accent", t.accent);
    r.setProperty("--t-pattern", "url(" + P + event.theme + ".svg)");
  }
  const pattern = (t = event.theme) => P + t + ".svg";

  // ---------- Motion ----------
  const cache = {};
  function spring(response = 0.5, damping = 0.86) {
    const key = response + "/" + damping + "/" + SLOW;
    if (cache[key]) return cache[key];
    const w0 = 2 * Math.PI / response, z = damping, wd = w0 * Math.sqrt(Math.max(1e-6, 1 - z * z));
    const f = (t) => z < 1 ? 1 - Math.exp(-z * w0 * t) * (Math.cos(wd * t) + (z * w0 / wd) * Math.sin(wd * t)) : 1 - (1 + w0 * t) * Math.exp(-w0 * t);
    let T = 0;
    for (let t = 0; t < 3; t += 1 / 240) if (Math.abs(1 - f(t)) > 0.002) T = t;
    T = Math.max(T, 0.1);
    const pts = [];
    for (let i = 0; i <= 48; i++) pts.push(+f((i / 48) * T).toFixed(4));
    pts[48] = 1;
    return (cache[key] = { easing: "linear(" + pts.join(", ") + ")", duration: T * 1000 * SLOW });
  }
  const EASE_OUT = "cubic-bezier(.23, 1, .32, 1)";
  const TORPH = "cubic-bezier(0.19, 1, 0.22, 1)";
  const ms = (n) => n * SLOW;
  const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches;
  function haptic(n = 6) {
    try { navigator.userActivation && navigator.userActivation.hasBeenActive && navigator.vibrate && navigator.vibrate(n); } catch (e) {}
  }

  // ---------- Torph-style text morph ----------
  // Words when there are spaces, letters when not; each piece keyed by its own
  // string (repeats get ~1, ~2). Kept pieces slide, new ones fade up from
  // 95%, leaving ones fade out where they stood.
  function segments(text) {
    const taken = new Set();
    const take = (k) => { if (!taken.has(k)) { taken.add(k); return k; } let n = 1; while (taken.has(k + "~" + n)) n++; taken.add(k + "~" + n); return k + "~" + n; };
    if (!text.includes(" ")) return [...text].map((c) => ({ id: take(c), text: c }));
    const out = []; let off = 0;
    text.split(" ").forEach((w, i) => {
      if (i > 0) { out.push({ id: take("space-" + off), text: " " }); off++; }
      if (w) out.push({ id: take(w), text: w });
      off += w.length;
    });
    return out;
  }
  function morph(el, text, opts = {}) {
    const dur = ms(opts.duration || 400);
    if (!el.classList.contains("morph")) el.classList.add("morph");
    if (el._text === undefined) {
      el.textContent = "";
      segments(text).forEach((s) => { const n = document.createElement("span"); n.dataset.id = s.id; n.textContent = s.text; el.appendChild(n); });
      el._text = text; return;
    }
    if (el._text === text) return;
    const box0 = el.getBoundingClientRect();
    const old = [...el.children].filter((c) => !c._leaving);
    const first = new Map(old.map((c) => [c.dataset.id, c.getBoundingClientRect()]));
    const pool = new Map(old.map((c) => [c.dataset.id, c]));
    const nodes = segments(text).map((s) => {
      let n = pool.get(s.id);
      if (n) pool.delete(s.id); else { n = document.createElement("span"); n.dataset.id = s.id; n.textContent = s.text; n._new = true; }
      return n;
    });
    old.forEach((c) => c.remove());
    nodes.forEach((n) => el.appendChild(n));
    const box1 = el.getBoundingClientRect();
    // Rects are in window pixels; the phone frame may be scaled down to fit
    const k = screenEl && screenEl.contains(el) ? scale() : 1;
    // Leaving pieces stay where they were, fading out
    for (const [id, n] of pool) {
      const r = first.get(id);
      n._leaving = true;
      n.style.position = "absolute"; n.style.left = (r.left - box1.left) / k + "px"; n.style.top = (r.top - box1.top) / k + "px";
      el.appendChild(n);
      n.animate([{ transform: "none" }, { transform: "scale(.95)" }], { duration: dur, easing: TORPH, fill: "forwards" });
      n.animate([{ opacity: 1 }, { opacity: 0 }], { duration: dur * 0.25, easing: "linear", fill: "forwards" }).finished.then(() => n.remove());
    }
    nodes.forEach((n) => {
      if (n._new) {
        n._new = false;
        n.animate([{ opacity: 0, transform: "scale(.95)", filter: "blur(2px)" }, { opacity: 1, transform: "none", filter: "blur(0)" }],
          { duration: dur * 0.5, delay: dur * 0.25, easing: "linear", fill: "backwards" });
        return;
      }
      const f = first.get(n.dataset.id), r = n.getBoundingClientRect();
      const dx = ((f.left - box0.left) - (r.left - box1.left)) / k, dy = ((f.top - box0.top) - (r.top - box1.top)) / k;
      if (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5) n.animate([{ transform: `translate(${dx}px, ${dy}px)` }, { transform: "none" }], { duration: dur, easing: TORPH });
    });
    // The box itself eases to its new width, so what follows doesn't jump
    if (Math.abs(box0.width - box1.width) > 0.5 && !opts.noWidth) {
      el.animate([{ width: box0.width / k + "px" }, { width: box1.width / k + "px" }], { duration: dur, easing: TORPH });
    }
    el._text = text;
  }

  /// Text that blurs out and back in (for things that aren't worth a morph)
  function blurSwap(el, html) {
    if (el.innerHTML === html) return;
    el.animate([{ opacity: 1, filter: "blur(0)" }, { opacity: 0, filter: "blur(4px)" }], { duration: ms(100), easing: "ease-out" }).finished.then(() => {
      el.innerHTML = html;
      el.animate([{ opacity: 0, filter: "blur(4px)", transform: "translateY(3px)" }, { opacity: 1, filter: "blur(0)", transform: "none" }], { duration: ms(220), easing: EASE_OUT });
    });
  }

  function countUp(el, to, fmtFn = (v) => v.toLocaleString("en-GB"), dur = 900) {
    if (reduced()) { el.textContent = fmtFn(to); return; }
    const t0 = performance.now(), d = ms(dur);
    const step = (now) => {
      const p = Math.min(1, (now - t0) / d), e = 1 - Math.pow(1 - p, 3);
      el.textContent = fmtFn(Math.round(to * e));
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }

  /// Parts of a view arriving one after another: faded, blurred, a touch low
  function enter(nodes, base = 60, gap = 30) {
    if (reduced()) return;
    [...nodes].forEach((n, i) => n.animate(
      [{ opacity: 0, filter: "blur(6px)", transform: "translateY(10px) scale(.985)" }, { opacity: 1, filter: "blur(0)", transform: "none" }],
      { duration: ms(420), delay: ms(base + Math.min(i * gap, 360)), easing: EASE_OUT, fill: "backwards" }));
  }

  // ---------- Geometry ----------
  let screenEl = null;
  function scale() { return screenEl.getBoundingClientRect().width / screenEl.offsetWidth || 1; }
  function rel(el) {
    const s = screenEl.getBoundingClientRect(), r = el.getBoundingClientRect(), k = scale();
    return { left: (r.left - s.left) / k, top: (r.top - s.top) / k, width: r.width / k, height: r.height / k };
  }
  /// The card follows the screen's own corners, 8pt in
  function cornerRadius() { return matchMedia("(max-width:560px)").matches ? 40 : 44; }

  // ---------- Floating card (the add card's language) ----------
  class FloatingCard {
    constructor() {
      this.scrim = document.createElement("div"); this.scrim.className = "scrim";
      this.el = document.createElement("div"); this.el.className = "fcard"; this.el.style.display = "none";
      this.body = document.createElement("div"); this.body.className = "fbody";
      this.foot = document.createElement("div"); this.foot.className = "ffoot";
      this.el.append(this.body, this.foot);
      screenEl.append(this.scrim, this.el);
      this.scrim.addEventListener("click", () => this.close());
      this.ro = new ResizeObserver(() => { if (this.isOpen && !this.busy) this.fit(spring(0.36, 0.9)); });
    }
    target() {
      const W = screenEl.clientWidth, H = screenEl.clientHeight;
      const h = 30 + this.body.offsetHeight + 22 + 52 + 24;
      return { left: 8, top: H - 8 - h, width: W - 16, height: h, radius: cornerRadius() };
    }
    current() {
      const cs = getComputedStyle(this.el);
      return { left: parseFloat(cs.left), top: parseFloat(cs.top), width: parseFloat(cs.width), height: parseFloat(cs.height), radius: parseFloat(cs.borderTopLeftRadius) };
    }
    px(r) { return { left: r.left + "px", top: r.top + "px", width: r.width + "px", height: r.height + "px", borderRadius: r.radius + "px" }; }
    animateTo(to, spr, from) {
      from = from || this.current();
      this.el.getAnimations().forEach((a) => a.cancel());
      Object.assign(this.el.style, this.px(to));
      return this.el.animate([this.px(from), this.px(to)], { duration: spr.duration, easing: spr.easing });
    }
    fit(spr) { this.animateTo(this.target(), spr || spring(0.42, 0.9)); }
    /// render(body) fills the card; actions: [{ label, kind, onClick }]
    open(source, render, actions, opts = {}) {
      if (this.isOpen) return;
      this.isOpen = true; this.source = source; this.opts = opts;
      this.body.style.width = (screenEl.clientWidth - 16 - 52) + "px";
      this.body.innerHTML = ""; render(this.body);
      this.setActions(actions);
      this.el.style.display = "block";
      const from = Object.assign(rel(source), { radius: opts.sourceRadius || 20 });
      const to = this.target();
      if (reduced()) { Object.assign(this.el.style, this.px(to)); }
      else this.animateTo(to, spring(0.5, 0.84), from);
      this.el.animate([{ opacity: opts.fadeIn ? 0 : 1 }, { opacity: 1 }], { duration: ms(180), easing: EASE_OUT });
      enter(this.body.querySelectorAll(".fx"), 90);
      this.foot.animate([{ opacity: 0, transform: "translateY(10px)" }, { opacity: 1, transform: "none" }], { duration: ms(360), delay: ms(140), easing: EASE_OUT, fill: "backwards" });
      this.fadeScrim(true);
      this.ro.observe(this.body);
      haptic();
    }
    setActions(actions) {
      this.foot.innerHTML = "";
      actions.forEach((a) => {
        const b = document.createElement("button");
        b.className = "cta" + (a.kind ? " " + a.kind : "");
        b.innerHTML = a.label;
        b.addEventListener("click", () => a.onClick(b));
        this.foot.appendChild(b);
      });
    }
    /// Swap the contents with a blur, the card springing to the new height
    swap(render, actions) {
      const old = this.body.cloneNode(true);
      old.style.pointerEvents = "none"; old.classList.add("ghost");
      this.el.insertBefore(old, this.foot);
      old.animate([{ opacity: 1, filter: "blur(0)" }, { opacity: 0, filter: "blur(6px)", transform: "scale(.97)" }], { duration: ms(170), easing: "ease-out", fill: "forwards" }).finished.then(() => old.remove());
      this.body.innerHTML = ""; render(this.body);
      if (actions) this.setActions(actions);
      enter(this.body.querySelectorAll(".fx"), 70);
      this.fit(spring(0.42, 0.9));
    }
    close(toSource = true, done) {
      if (!this.isOpen) return;
      this.isOpen = false; this.ro.disconnect();
      const fade = { duration: ms(140), easing: "ease-out", fill: "forwards" };
      this.body.animate([{ opacity: 1 }, { opacity: 0, filter: "blur(4px)" }], fade);
      this.foot.animate([{ opacity: 1 }, { opacity: 0 }], fade);
      this.fadeScrim(false);
      const finish = () => { this.el.style.display = "none"; this.el.getAnimations().forEach((a) => a.cancel()); done && done(); };
      if (toSource && this.source && !reduced()) {
        const to = Object.assign(rel(this.source), { radius: this.opts.sourceRadius || 20 });
        this.animateTo(to, spring(0.38, 1)).finished.then(finish);
        this.el.animate([{ opacity: 1 }, { opacity: 0 }], { duration: ms(220), delay: ms(140), easing: "ease-out", fill: "forwards" });
      } else {
        this.el.animate([{ opacity: 1, transform: "none" }, { opacity: 0, transform: "scale(.97)" }], { duration: ms(200), easing: "ease-out", fill: "forwards" }).finished.then(finish);
      }
    }
    fadeScrim(on) {
      const from = getComputedStyle(this.scrim).opacity;
      this.scrim.getAnimations().forEach((a) => a.cancel());
      this.scrim.style.opacity = on ? 1 : 0; this.scrim.classList.toggle("on", on);
      this.scrim.animate([{ opacity: from }, { opacity: on ? 1 : 0 }], { duration: ms(on ? 320 : 240), easing: EASE_OUT });
    }
  }

  // ---------- Hold to reset ----------
  // Slow and linear while the finger decides; snaps back fast on release
  function holdButton(el, { duration = 1400, onComplete, onStart }) {
    const fill = el.querySelector(".fill");
    let anim = null, ticks = null, done = false;
    const start = (e) => {
      if (e.button > 0) return;
      done = false; onStart && onStart();
      el.setPointerCapture && e.pointerId !== undefined && el.setPointerCapture(e.pointerId);
      const from = getComputedStyle(fill).clipPath;
      fill.getAnimations().forEach((a) => a.cancel());
      anim = fill.animate([{ clipPath: from && from !== "none" ? from : "inset(0 100% 0 0)" }, { clipPath: "inset(0 0 0 0)" }], { duration: ms(duration), easing: "linear", fill: "forwards" });
      el.animate([{ transform: "scale(1)" }, { transform: "scale(.975)" }], { duration: ms(duration), easing: "linear", fill: "forwards" });
      let n = 0;
      ticks = setInterval(() => haptic(4 + n++ * 3), ms(duration) / 6);
      anim.finished.then(() => {
        if (done) return;
        done = true; clearInterval(ticks); haptic(30);
        el.getAnimations().forEach((a) => a.cancel());
        el.animate([{ transform: "scale(.975)" }, { transform: "scale(1.02)" }, { transform: "scale(1)" }], { duration: ms(380), easing: EASE_OUT });
        onComplete && onComplete();
        setTimeout(() => release(true), ms(320));
      }).catch(() => {});
    };
    const release = (afterDone) => {
      clearInterval(ticks);
      if (!anim) return;
      if (!done || afterDone === true) {
        const from = getComputedStyle(fill).clipPath;
        fill.getAnimations().forEach((a) => a.cancel());
        fill.animate([{ clipPath: from }, { clipPath: "inset(0 100% 0 0)" }], { duration: ms(220), easing: EASE_OUT, fill: "forwards" });
        el.getAnimations().forEach((a) => a.cancel());
        if (!done) el.animate([{ transform: "scale(.975)" }, { transform: "scale(1)" }], { duration: ms(200), easing: EASE_OUT });
        anim = null;
      }
    };
    el.addEventListener("pointerdown", start);
    el.addEventListener("pointerup", () => release());
    el.addEventListener("pointercancel", () => release());
    el.addEventListener("keydown", (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); onComplete && onComplete(); } });
  }

  // ---------- Island toast ----------
  function toast(text, actionLabel, onAction, duration = 5000) {
    let t = screenEl.querySelector(".toast");
    if (!t) { t = document.createElement("div"); t.className = "toast"; screenEl.appendChild(t); }
    t.innerHTML = "<span>" + text + "</span>" + (actionLabel ? "<button>" + actionLabel + "</button>" : "");
    t.style.pointerEvents = "auto";
    const s = spring(0.45, 0.78);
    t.getAnimations().forEach((a) => a.cancel());
    t.style.opacity = 1;
    t.animate([{ opacity: 1, width: "124px", height: "36px", top: "11px", transform: "translateX(-50%) scale(1)", color: "transparent" },
               { opacity: 1, width: t.scrollWidth + 8 + "px", height: "44px", top: "8px", transform: "translateX(-50%)", color: "#fff" }],
      { duration: s.duration, easing: s.easing, fill: "forwards" });
    if (actionLabel) t.querySelector("button").onclick = () => { onAction && onAction(); hide(); };
    clearTimeout(t._h);
    const hide = () => {
      t.style.pointerEvents = "none";
      t.animate([{ opacity: 1 }, { opacity: 0, transform: "translateX(-50%) scale(.9)" }], { duration: ms(220), easing: "ease-out", fill: "forwards" });
    };
    t._h = setTimeout(hide, ms(duration));
  }

  // ---------- Frame + chrome ----------
  const VARIANTS = [
    ["index.html", "Overview"],
    ["a-card.html", "A · The card"],
    ["b-sentence.html", "B · The sentence"],
    ["c-journey.html", "C · The journey"],
    ["d-bold.html", "D · Bold"],
    ["e-mix.html", "E · Mix ★"],
    ["f-reset.html", "F · Reset"],
    ["g-runs.html", "G · Runs"],
    ["h-empty.html", "H · Empty home"],
    ["i-celebrate.html", "I · Milestones"],
    ["j-calendar.html", "J · Calendar"],
    ["k-share.html", "K · Share"],
  ];
  const STATUS = '<svg width="78" height="13" viewBox="0 0 78 13" fill="currentColor" aria-hidden="true"><rect x="0" y="8" width="3.4" height="4.6" rx="1"/><rect x="5" y="5.6" width="3.4" height="7" rx="1"/><rect x="10" y="3" width="3.4" height="9.6" rx="1"/><rect x="15" y="0.4" width="3.4" height="12.2" rx="1"/><path d="M31.5 2.6c2.4 0 4.6.9 6.3 2.5l1.2-1.2A10.6 10.6 0 0 0 31.5 1 10.6 10.6 0 0 0 24 3.9l1.2 1.2a9 9 0 0 1 6.3-2.5Zm0 3.4c1.5 0 2.9.6 3.9 1.5l1.2-1.2a7.2 7.2 0 0 0-10.2 0l1.2 1.2c1-1 2.4-1.5 3.9-1.5Zm0 3.4c.6 0 1.1.2 1.5.6l-1.5 1.5-1.5-1.5c.4-.4.9-.6 1.5-.6Z"/><rect x="50.5" y="0.5" width="24" height="12" rx="3.8" fill="none" stroke="currentColor" opacity=".4"/><rect x="52.3" y="2.3" width="17" height="8.4" rx="2.3"/></svg>';

  function mount(active, opts = {}) {
    applyTheme();
    screenEl = document.getElementById("screen");
    if (screenEl) {
      const sb = document.createElement("div"); sb.className = "statusbar" + (opts.lightStatus ? " light" : ""); sb.innerHTML = "<span>9:41</span>" + STATUS;
      const island = document.createElement("div"); island.className = "island";
      const home = document.createElement("div"); home.className = "home-ind";
      screenEl.append(sb, island, home);
    }
    const chrome = document.getElementById("chrome");
    if (chrome) {
      chrome.innerHTML =
        '<a class="brand" href="index.html">Sinced <span>/ Event page</span></a>' +
        '<nav class="vnav">' + VARIANTS.map(([h, l]) => '<a href="' + h + '"' + (h === active ? ' class="on"' : "") + ">" + l + "</a>").join("") + "</nav>" +
        '<div class="chrome-right"><div class="swatches">' + Object.keys(THEMES).map((t) => '<button title="' + t + '" data-t="' + t + '" style="background-image:url(' + P + t + '.svg)"></button>').join("") +
        '</div><label class="slow"><input type="checkbox" id="slowmo"> Slow ×4</label></div>';
      const sync = () => chrome.querySelectorAll(".swatches button").forEach((b) => b.classList.toggle("on", b.dataset.t === event.theme));
      chrome.querySelectorAll(".swatches button").forEach((b) => b.addEventListener("click", () => setTheme(b.dataset.t)));
      const slow = chrome.querySelector("#slowmo");
      if (slow) slow.addEventListener("change", () => { SLOW = slow.checked ? 4 : 1; });
      listeners.push(sync); sync();
    }
    const fit = () => {
      const dev = document.querySelector(".device"), wrap = document.querySelector(".device-wrap");
      if (!dev || matchMedia("(max-width:560px)").matches) { if (dev) dev.style.transform = ""; return; }
      const top = (document.getElementById("chrome") || { offsetHeight: 0 }).offsetHeight + ((document.querySelector(".vbar") || { offsetHeight: 0 }).offsetHeight);
      const k = Math.min(1, (innerHeight - top - 48) / 876);
      dev.style.transform = k < 1 ? "scale(" + k + ")" : "";
      wrap.style.width = 417 * k + "px"; wrap.style.height = 876 * k + "px";
    };
    addEventListener("resize", fit); fit();
  }

  function tick(fn) { fn(); setInterval(fn, 60000); }

  window.Kit = {
    THEMES, GOALS, MILESTONES, UNITS, HOUR, DAY, event, elapsed, unitValue, days, daysText, fmt, monthShort, stats, target, reset, undoReset,
    setTheme, pattern, spring, EASE_OUT, TORPH, ms, reduced, haptic, morph, blurSwap, countUp, enter, rel, FloatingCard, holdButton, toast,
    mount, tick, onChange: (f) => listeners.push(f), get screen() { return screenEl; },
  };
})();
