/* Widget nudge explorations: the home screen right after the first counter
   is added, then each direction's nudge. Replay and Slow ×4 in the chrome. */
(function () {
  const P = "../../website/assets/patterns/";
  const THEMES = ["Circles", "Waves", "Mosaic", "Eyes", "Clouds", "Puffs", "Blooms", "Steps"];
  const VARIANTS = [
    ["a-window.html", "A · Window"],
    ["b-callout.html", "B · Callout"],
    ["c-lock.html", "C · Lock Screen"],
    ["d-sentence.html", "D · Sentence"],
    ["e-steps.html", "E · Steps inline"],
  ];
  const EASE_OUT = "cubic-bezier(.23, 1, .32, 1)";
  const EASE_IN_OUT = "cubic-bezier(.77, 0, .175, 1)";
  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const event = { title: "No sugar", days: 0 };
  let SLOW = 1, theme = "Circles", screen, slot, card, runId = 0, onPlay, onReset;

  const ms = (n) => n * SLOW;
  const wait = (n) => new Promise((r) => setTimeout(r, ms(n)));
  const X = '<svg viewBox="0 0 10 10" fill="none" stroke="#8a888a" stroke-width="1.8" stroke-linecap="round"><path d="M1.5 1.5l7 7M8.5 1.5l-7 7"/></svg>';
  const STATUS = '<svg width="78" height="13" viewBox="0 0 78 13" fill="currentColor" aria-hidden="true"><rect x="0" y="8" width="3.4" height="4.6" rx="1"/><rect x="5" y="5.6" width="3.4" height="7" rx="1"/><rect x="10" y="3" width="3.4" height="9.6" rx="1"/><rect x="15" y="0.4" width="3.4" height="12.2" rx="1"/><rect x="50.5" y="0.5" width="24" height="12" rx="3.8" fill="none" stroke="currentColor" opacity=".4"/><rect x="52.3" y="2.3" width="17" height="8.4" rx="2.3"/></svg>';

  function setTheme(t) {
    theme = t;
    document.documentElement.style.setProperty("--pat", "url(" + P + t + ".svg)");
    document.querySelectorAll(".swatches button").forEach((b) => b.classList.toggle("on", b.dataset.t === t));
  }

  const count = () => '<b>' + event.days + '<small>d</small></b>';
  const smallWidget = () => '<div class="wsmall">' + count() + "<span>Since " + event.title + "</span></div>";
  const medWidget = () => '<div class="wmed">' + count() + "<span>Since " + event.title + "</span></div>";

  function mount(active, opts) {
    onPlay = opts.play; onReset = opts.reset;
    const chrome = document.getElementById("chrome");
    chrome.innerHTML =
      '<a class="brand" href="index.html">Sinced <span>/ Widget nudge</span></a>' +
      '<nav class="vnav">' + VARIANTS.map(([h, l]) => '<a href="' + h + '"' + (h === active ? ' class="on"' : "") + ">" + l + "</a>").join("") + "</nav>" +
      '<div class="chrome-right"><div class="swatches">' + THEMES.map((t) => '<button title="' + t + '" data-t="' + t + '" style="background-image:url(' + P + t + '.svg)"></button>').join("") +
      '</div><label class="slow"><input type="checkbox" id="slowmo"> Slow ×4</label><button class="replay" id="replay">Replay</button></div>';
    chrome.querySelectorAll(".swatches button").forEach((b) => b.addEventListener("click", () => setTheme(b.dataset.t)));
    chrome.querySelector("#slowmo").addEventListener("change", (e) => { SLOW = e.target.checked ? 4 : 1; });
    chrome.querySelector("#replay").addEventListener("click", play);

    screen = document.getElementById("screen");
    screen.innerHTML =
      '<div class="statusbar"><span>9:41</span>' + STATUS + '</div><div class="island"></div><div class="home-ind"></div>' +
      '<div class="home"><div class="slot" id="slot"><div class="inner" id="slotInner"></div></div>' +
      '<div class="grid" id="grid"><div class="ev card-new" id="card">' + count() + "<span>Since " + event.title + '</span></div><div class="addtile">+</div></div></div>' +
      '<div class="tabbar"><div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3 2.5 11h2.7v9h5.3v-5.5h3V20h5.3v-9h2.7z"/></svg>Home</div>' +
      '<div><svg viewBox="0 0 24 24" fill="currentColor"><path d="M19.4 13a7.6 7.6 0 0 0 0-2l2.1-1.6-2-3.4-2.5 1a7.4 7.4 0 0 0-1.7-1L15 3.3h-4L10.6 6a7.4 7.4 0 0 0-1.7 1l-2.5-1-2 3.4L6.5 11a7.6 7.6 0 0 0 0 2l-2.1 1.6 2 3.4 2.5-1c.5.4 1.1.8 1.7 1l.4 2.7h4l.4-2.7c.6-.2 1.2-.6 1.7-1l2.5 1 2-3.4zM13 15.5a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7z"/></svg>Settings</div></div>' +
      '<div class="mtoast" id="mtoast"></div>';
    slot = document.getElementById("slot");
    card = document.getElementById("card");
    setTheme(theme);
    fit(); addEventListener("resize", fit);
    play();
  }

  function fit() {
    const dev = document.querySelector(".device"), wrap = document.querySelector(".device-wrap");
    if (!dev || matchMedia("(max-width:560px)").matches) { if (dev) dev.style.transform = ""; return; }
    const top = document.getElementById("chrome").offsetHeight;
    const k = Math.min(1, (innerHeight - top - 48) / 876);
    dev.style.transform = k < 1 ? "scale(" + k + ")" : "";
    wrap.style.width = 417 * k + "px"; wrap.style.height = 876 * k + "px";
  }

  // The counter has just been added: its card settles in, then the nudge arrives
  async function play() {
    const id = ++runId;
    slot.classList.remove("open");
    slot.style.transitionDuration = "0s";
    document.getElementById("slotInner").innerHTML = "";
    card.classList.remove("in");
    if (onReset) onReset();
    await wait(250); if (id !== runId) return;
    slot.style.transitionDuration = "";
    card.style.transitionDuration = ms(300) / 1000 + "s, " + ms(450) / 1000 + "s";
    card.classList.add("in");
    await wait(800); if (id !== runId) return;
    onPlay(document.getElementById("slotInner"), () => id !== runId);
  }

  /** Opens the slot above the grid and brings a nudge in */
  function openSlot(el) {
    const inner = document.getElementById("slotInner");
    inner.innerHTML = ""; inner.append(el);
    slot.style.transitionDuration = ms(420) / 1000 + "s";
    requestAnimationFrame(() => {
      slot.classList.add("open");
      el.style.transitionDuration = ms(300) / 1000 + "s, " + ms(420) / 1000 + "s";
      el.style.transitionDelay = ms(60) / 1000 + "s";
      requestAnimationFrame(() => el.classList.add("on"));
    });
  }

  /** The way it came in, a little quicker */
  function closeSlot() {
    const el = document.getElementById("slotInner").firstElementChild;
    if (el) { el.style.transitionDuration = ms(160) / 1000 + "s"; el.style.transitionDelay = "0s"; el.classList.remove("on"); }
    slot.style.transitionDuration = ms(320) / 1000 + "s";
    setTimeout(() => slot.classList.remove("open"), ms(60));
  }

  let toastTimer;
  function toast(text) {
    const t = document.getElementById("mtoast");
    t.textContent = text; t.style.transitionDuration = ms(320) / 1000 + "s, " + ms(200) / 1000 + "s";
    t.classList.add("on");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.classList.remove("on"), ms(1800));
  }

  /** Where an element sits inside the screen, in screen pixels */
  function rel(el) {
    const s = screen.getBoundingClientRect(), r = el.getBoundingClientRect(), k = s.width / screen.offsetWidth || 1;
    return { x: (r.left - s.left) / k, y: (r.top - s.top) / k, w: r.width / k, h: r.height / k };
  }

  function html(s) { const d = document.createElement("div"); d.innerHTML = s.trim(); return d.firstElementChild; }

  window.Nudge = { mount, openSlot, closeSlot, toast, rel, html, wait, ms, event, smallWidget, medWidget, X, EASE_OUT, EASE_IN_OUT, reduced,
    get screen() { return screen; }, get card() { return card; }, get theme() { return theme; } };
})();
