/* Shared mock data + helpers. Mirrors Sinced2/Models/SinceEvent.swift */
(function () {
  const MIN = 6e4, HOUR = 36e5, DAY = 864e5;

  // CardTheme values from SinceEvent.swift
  const THEMES = {
    mosaic:  { name: "Mosaic",  bg: "#F1622A", badge: "#243721", badgeText: "#FFFFFF" },
    eyes:    { name: "Eyes",    bg: "#FA96A1", badge: "#F03234", badgeText: "#FA96A1" },
    circles: { name: "Circles", bg: "#4D4AFD", badge: "#2C2B45", badgeText: "#FFFFFF" },
    clouds:  { name: "Clouds",  bg: "#4B800E", badge: "#BDD47E", badgeText: "#4B800E" },
    puffs:   { name: "Puffs",   bg: "#C09CF9", badge: "#2A1C57", badgeText: "#C09CF9" },
  };
  const MILESTONES = [1, 7, 30, 90, 365];
  const UNITS = ["Hours", "Days", "Months", "Years"];
  const ASSET_ROOT = "../../Sinced2/Assets.xcassets/";

  function asset(key, shape) {
    const n = THEMES[key].name;
    return ASSET_ROOT + (shape === "tall" ? "EventCards_Themes" : "EventCardSquareSVG") + "/" + n + ".imageset/" + n + ".svg";
  }

  // ---- Mock event: 5th streak, currently a personal best ----
  const now = Date.now();
  const startedAt = now - (23 * DAY + 4 * HOUR + 17 * MIN);
  const past = [ // oldest → newest
    { days: 3,  extra: 7 * HOUR,  note: "Friday drinks with the team" },
    { days: 11, extra: 2 * HOUR,  note: null },
    { days: 6,  extra: 15 * HOUR, note: "Wedding weekend" },
    { days: 18, extra: 5 * HOUR,  note: "Deadline week, caved once" },
  ];
  const history = []; // newest first, like SinceEvent.history
  let cursor = startedAt;
  for (let i = past.length - 1; i >= 0; i--) {
    const s = past[i];
    const start = cursor - s.days * DAY - s.extra;
    history.push({ at: cursor, note: s.note, start, length: cursor - start });
    cursor = start;
  }

  const event = {
    title: "No smoking",
    createdAt: cursor,
    startedAt,
    history,
    unit: "Days",
    reminders: { enabled: true, type: "Weekly", days: ["Mon", "Thu"], time: "9:00 AM" },
  };

  // ---- Time helpers ----
  const pad = (n) => String(n).padStart(2, "0");
  function parts(ms) {
    const s = Math.max(0, Math.floor(ms / 1000));
    return { d: Math.floor(s / 86400), h: Math.floor((s % 86400) / 3600), m: Math.floor((s % 3600) / 60), s: s % 60 };
  }
  function elapsed() { return Date.now() - event.startedAt; }
  function unitValue(unit, ms) {
    const map = { Hours: [HOUR, "hour"], Days: [DAY, "day"], Months: [30 * DAY, "month"], Years: [365 * DAY, "year"] };
    const [div, word] = map[unit];
    const v = Math.floor(ms / div);
    return { value: v, word: word + (v === 1 ? "" : "s") };
  }
  function short(ms) {
    const p = parts(ms);
    if (p.d > 0) return p.d + "d" + (p.h ? " " + p.h + "h" : "");
    if (p.h > 0) return p.h + "h" + (p.m ? " " + p.m + "m" : "");
    return p.m + "m";
  }
  function days(ms) { return Math.floor(ms / DAY); }
  function nextMilestone(ms) {
    const d = ms / DAY;
    const next = MILESTONES.find((m) => m > d);
    if (!next) return null;
    const prev = [0, ...MILESTONES].filter((m) => m <= d).pop();
    return { days: next, prev, remaining: next * DAY - ms, progress: (d - prev) / (next - prev), date: event.startedAt + next * DAY };
  }
  function fmtDate(ts, opts) {
    const d = new Date(ts);
    const sameYear = d.getFullYear() === new Date().getFullYear();
    return d.toLocaleDateString("en-GB", Object.assign({ day: "numeric", month: "short" }, sameYear ? {} : { year: "numeric" }, opts || {}));
  }
  function fmtTime(ts) { return new Date(ts).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" }); }
  function stats() {
    const lengths = event.history.map((h) => h.length);
    const cur = elapsed();
    const all = lengths.concat(cur);
    return {
      current: cur,
      longestPast: Math.max(0, ...lengths),
      longest: Math.max(...all),
      isBest: cur >= Math.max(0, ...lengths),
      average: all.reduce((a, b) => a + b, 0) / all.length,
      resets: event.history.length,
      streakNo: event.history.length + 1,
      tracking: Date.now() - event.createdAt,
    };
  }

  // ---- State: theme + change events ----
  const listeners = [];
  function getTheme() {
    try { const t = localStorage.getItem("sinced-theme"); if (t && THEMES[t]) return t; } catch (e) {}
    return "mosaic";
  }
  let theme = getTheme();
  function applyThemeVars() {
    const t = THEMES[theme], r = document.documentElement.style;
    r.setProperty("--t-bg", t.bg); r.setProperty("--t-badge", t.badge); r.setProperty("--t-badge-text", t.badgeText);
  }
  function setTheme(key) {
    theme = key;
    try { localStorage.setItem("sinced-theme", key); } catch (e) {}
    applyThemeVars();
    emit();
  }
  function emit() { listeners.forEach((fn) => fn()); }
  function onChange(fn) { listeners.push(fn); }

  function reset(note) {
    const at = Date.now();
    event.history.unshift({ at, note: note || null, start: event.startedAt, length: at - event.startedAt });
    event.startedAt = at;
    emit();
  }

  function tick(fn) { fn(); setInterval(fn, 1000); }

  // ---- In-phone UI helpers ----
  function toast(screen, msg) {
    let el = screen.querySelector(".toast");
    if (!el) { el = document.createElement("div"); el.className = "toast"; screen.appendChild(el); }
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(el._t);
    el._t = setTimeout(() => el.classList.remove("show"), 2200);
  }

  function resetSheet(screen) {
    let bd = screen.querySelector(".sheet-backdrop");
    if (!bd) {
      bd = document.createElement("div"); bd.className = "sheet-backdrop";
      const sh = document.createElement("div"); sh.className = "sheet";
      sh.innerHTML =
        '<div class="grabber"></div><h3>Reset timer?</h3><p>Your current streak will be saved to history.</p>' +
        '<div class="field"><span>Reset time</span><span class="rs-time"></span></div>' +
        '<textarea placeholder="Note (optional)"></textarea>' +
        '<button class="primary">Reset</button><button class="ghost">Cancel</button>';
      screen.append(bd, sh);
      const close = () => { bd.classList.remove("open"); sh.classList.remove("open"); };
      bd.onclick = close;
      sh.querySelector(".ghost").onclick = close;
      sh.querySelector(".primary").onclick = () => {
        const len = short(elapsed());
        reset(sh.querySelector("textarea").value.trim());
        sh.querySelector("textarea").value = "";
        close();
        setTimeout(() => toast(screen, "Streak of " + len + " saved to history"), 250);
      };
    }
    const sh = screen.querySelector(".sheet");
    sh.querySelector(".rs-time").textContent = "Now, " + fmtTime(Date.now());
    bd.classList.add("open"); sh.classList.add("open");
  }

  const STATUS_ICONS =
    '<svg width="78" height="13" viewBox="0 0 78 13" fill="currentColor" aria-hidden="true">' +
    '<rect x="0" y="8" width="3.4" height="4.6" rx="1"/><rect x="5" y="5.6" width="3.4" height="7" rx="1"/><rect x="10" y="3" width="3.4" height="9.6" rx="1"/><rect x="15" y="0.4" width="3.4" height="12.2" rx="1"/>' +
    '<path d="M31.5 2.6c2.4 0 4.6.9 6.3 2.5l1.2-1.2A10.6 10.6 0 0 0 31.5 1 10.6 10.6 0 0 0 24 3.9l1.2 1.2a9 9 0 0 1 6.3-2.5Zm0 3.4c1.5 0 2.9.6 3.9 1.5l1.2-1.2a7.2 7.2 0 0 0-10.2 0l1.2 1.2c1-1 2.4-1.5 3.9-1.5Zm0 3.4c.6 0 1.1.2 1.5.6l-1.5 1.5-1.5-1.5c.4-.4.9-.6 1.5-.6Z"/>' +
    '<rect x="50.5" y="0.5" width="24" height="12" rx="3.8" fill="none" stroke="currentColor" opacity=".4"/><rect x="52.3" y="2.3" width="17" height="8.4" rx="2.3"/><path d="M76 4.4v4.2c.8-.3 1.4-1.1 1.4-2.1s-.6-1.8-1.4-2.1Z" opacity=".45"/></svg>';

  function mountFrame(screen, opts) {
    opts = opts || {};
    const sb = document.createElement("div");
    sb.className = "statusbar" + (opts.light ? " light" : "");
    sb.innerHTML = "<span>9:41</span>" + STATUS_ICONS;
    const island = document.createElement("div"); island.className = "island";
    const home = document.createElement("div"); home.className = "home-ind" + (opts.light ? " light" : "");
    screen.append(sb, island, home);
    return { statusbar: sb, home };
  }

  // ---- Page chrome (variant switcher + theme picker) ----
  const VARIANTS = [
    ["index.html", "Overview"],
    ["a-immersive-card.html", "A · Immersive card"],
    ["b-insights-dashboard.html", "B · Insights dashboard"],
    ["c-journey-tabs.html", "C · Journey tabs"],
  ];
  function mountChrome(active) {
    const el = document.getElementById("chrome");
    if (!el) return;
    el.innerHTML =
      '<a class="brand" href="index.html">Sinced <span>/ Event detail</span></a>' +
      '<nav class="vnav">' + VARIANTS.map(([h, l]) => '<a href="' + h + '"' + (h === active ? ' class="on"' : "") + ">" + l + "</a>").join("") + "</nav>" +
      '<div class="theme-picker"><span>Card theme</span>' +
      Object.keys(THEMES).map((k) => '<button data-k="' + k + '" title="' + THEMES[k].name + '" style="background:' + THEMES[k].bg + '"></button>').join("") + "</div>";
    const sync = () => el.querySelectorAll(".theme-picker button").forEach((b) => b.classList.toggle("on", b.dataset.k === theme));
    el.querySelectorAll(".theme-picker button").forEach((b) => (b.onclick = () => setTheme(b.dataset.k)));
    onChange(sync); sync();
  }

  applyThemeVars();
  window.Sinced = {
    THEMES, MILESTONES, UNITS, DAY, HOUR, event, asset, parts, pad, elapsed, unitValue, short, days,
    nextMilestone, fmtDate, fmtTime, stats, reset, tick, toast, resetSheet, mountFrame, mountChrome,
    onChange, setTheme, get theme() { return theme; }, get t() { return THEMES[theme]; },
  };
})();
