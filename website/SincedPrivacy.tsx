// Sinced privacy page (adityakolte.com/sinced/privacy), as a Framer code component.
// Generated from SincedDoc.tsx by build-docs.mjs. Width: Fill, Height: Fit; upload the four Allo font files.

import * as React from "react"
import { addPropertyControls, ControlType } from "framer"

const APP_STORE_URL =
    "https://apps.apple.com/in/app/sinced-days-since-counter/id6799975298"
const FIXED_PAGE: "privacy" | "support" | null = "privacy"

const HOME = "https://adityakolte.com/sinced"
const PRIVACY = "https://adityakolte.com/sinced/privacy"
const SUPPORT = "https://adityakolte.com/sinced/support"

interface Props {
    page: "privacy" | "support"
    email: string
    alloRegular?: string
    alloMedium?: string
    alloSemiBold?: string
    alloBold?: string
    stickyNav: boolean
    style?: React.CSSProperties
}

// ─── Privacy policy (same wording as PRIVACY.md in the repo) ────────────────

const PRIVACY_UPDATED = "October 13, 2026"

const SHORT_VERSION = [
    {
        title: "everything stays on your device.",
        body: "Sinced has no accounts, no servers and no cloud sync. We never see your events.",
    },
    {
        title: "we don't track you, run ads, or sell your data.",
        body: "There are no analytics or advertising SDKs in the app.",
    },
    {
        title: "the app doesn't connect to the internet.",
        body: "The only time it opens a web page is when you tap a link, like this policy or the developer's website.",
    },
]

function PrivacyBody({ email }: { email: string }) {
    return (
        <>
            <header className="sd-head">
                <p className="sd-eyebrow">sinced</p>
                <h1>privacy policy</h1>
                <p className="sd-meta">Last updated {PRIVACY_UPDATED}</p>
                <p className="sd-lede">
                    Sinced (“the app”, “we”, “us”) is a small app for keeping track of the time since
                    moments that matter to you. This policy explains what the app stores, why, and
                    the choices you have. We've kept it plain and honest.
                </p>
            </header>

            <section className="sd-short">
                <h2>the short version</h2>
                <div className="sd-cards">
                    {SHORT_VERSION.map((s) => (
                        <div key={s.title} className="sd-card">
                            <h3>{s.title}</h3>
                            <p>{s.body}</p>
                        </div>
                    ))}
                </div>
            </section>

            <article className="sd-prose">
                <h2>what the app stores</h2>
                <p>
                    All of this is saved only on your iPhone, in storage shared between the app and
                    its Home Screen widget:
                </p>
                <ul>
                    <li>
                        <b>Your events.</b> The name of each event, when it started, its card theme,
                        how it displays on the widget, and any reset history and notes you add.
                    </li>
                    <li>
                        <b>Photos you choose for a card.</b> If you pick a custom photo, a small,
                        compressed copy is saved with that event. You choose a specific photo through
                        Apple's system picker, which does not give the app access to your whole photo
                        library.
                    </li>
                    <li>
                        <b>Your name</b>, if you enter one, and your app preferences (like whether
                        reminders are turned on).
                    </li>
                </ul>

                <h2>reminders</h2>
                <p>
                    If you turn on reminders, Sinced schedules notifications <b>on your device</b>{" "}
                    using iOS's local notifications. Nothing is sent to us or to any other server.
                </p>

                <h2>saving and sharing cards</h2>
                <ul>
                    <li>
                        <b>Save to Photos.</b> If you save a card, Sinced asks for permission to{" "}
                        <b>add</b> images to your photo library. It cannot read your existing photos.
                    </li>
                    <li>
                        <b>Share.</b> If you share a card, the image goes only to the app or person
                        you choose in the iOS share sheet.
                    </li>
                </ul>

                <h2>who can see your data</h2>
                <p>
                    Only you, on your device. Your data is not shared with us or any third party. If
                    you use iCloud or iTunes device backups, your data is included in those backups
                    under Apple's terms, as with any app.
                </p>

                <h2>retention and deletion</h2>
                <p>Your data stays on your device until you delete it:</p>
                <ul>
                    <li>Delete an individual event from inside the app.</li>
                    <li>Delete everything by deleting the Sinced app from your iPhone.</li>
                </ul>

                <h2>children</h2>
                <p>
                    Sinced is not directed to children under 13 and does not knowingly collect
                    personal information from them. In fact, it doesn't collect personal information
                    from anyone.
                </p>

                <h2>changes to this policy</h2>
                <p>
                    We may update this policy from time to time. When we do, the “last updated” date
                    above will change.
                </p>

                <h2>contact</h2>
                <p>
                    Questions or concerns: <a href={`mailto:${email}`}>{email}</a>
                </p>
            </article>
        </>
    )
}

// ─── Support (same content as SUPPORT.md in the repo) ───────────────────────

const SUPPORT_FAQ: { q: string; a: React.ReactNode }[] = [
    {
        q: "my widget isn't updating.",
        a: (
            <>
                Open Sinced once. That refreshes every widget. If a widget shows “No event”, touch
                and hold it, choose <b>Edit Widget</b>, and pick an event.
            </>
        ),
    },
    {
        q: "I'm not getting reminders.",
        a: (
            <>
                Check that notifications for Sinced are allowed in{" "}
                <b>Settings → Notifications → Sinced</b>, and that reminders are turned on for the
                event in the app.
            </>
        ),
    },
    {
        q: "can I undo a reset?",
        a: (
            <>
                Yes, for two minutes after you reset: tap <b>Undo</b> in the app or on the widget.
            </>
        ),
    },
    {
        q: "where is my data stored? can I move it to a new phone?",
        a: (
            <>
                Everything stays on your iPhone. There are no accounts or servers. Your events move
                to a new phone with an iCloud or computer backup of your device.
            </>
        ),
    },
    {
        q: "how do I delete my data?",
        a: (
            <>
                Delete individual events in the app, or delete the Sinced app to remove everything.
            </>
        ),
    },
]

function SupportBody({ email }: { email: string }) {
    const subject = encodeURIComponent("Sinced support")
    const body = encodeURIComponent(
        "\n\n—\niPhone model:\niOS version:\n"
    )
    return (
        <>
            <header className="sd-head">
                <p className="sd-eyebrow">sinced</p>
                <h1>how can we help?</h1>
                <p className="sd-lede">
                    Need a hand with Sinced, found a bug, or have an idea? Write in, and include your
                    iPhone model and iOS version if something isn't working.
                </p>
            </header>

            <section className="sd-contact">
                <div>
                    <h2>email support</h2>
                    <p>A real person reads every message.</p>
                </div>
                <a className="sd-btn" href={`mailto:${email}?subject=${subject}&body=${body}`}>
                    {email}
                </a>
            </section>

            <section className="sd-faq">
                <h2>common questions</h2>
                {SUPPORT_FAQ.map((f, i) => (
                    <details key={f.q} open={i === 0}>
                        <summary>{f.q}</summary>
                        <p>{f.a}</p>
                    </details>
                ))}
            </section>

            <p className="sd-also">
                See also the <a href={PRIVACY}>privacy policy</a>.
            </p>
        </>
    )
}

// ─── Page shell ─────────────────────────────────────────────────────────────

/**
 * @framerSupportedLayoutWidth any-prefer-fixed
 * @framerSupportedLayoutHeight auto
 * @framerIntrinsicWidth 1200
 */
export default function SincedPrivacy(props: Props) {
    const { email, stickyNav, style } = props
    const page = FIXED_PAGE ?? props.page

    const fontFaces = [
        [props.alloRegular, 400],
        [props.alloMedium, 500],
        [props.alloSemiBold, 600],
        [props.alloBold, 700],
    ]
        .filter(([src]) => src)
        .map(
            ([src, w]) =>
                `@font-face{font-family:"Allo Sinced";src:url("${src}");font-weight:${w};font-style:normal;font-display:swap}`
        )
        .join("")

    return (
        <div className="sd" style={style}>
            <style>{fontFaces + CSS}</style>

            <nav className={stickyNav ? "sd-nav sd-nav-sticky" : "sd-nav"}>
                <div className="sd-nav-in">
                    <a className="sd-nav-name" href={HOME}>
                        sinced
                    </a>
                    <div className="sd-nav-links">
                        <a href={HOME}>overview</a>
                        <a href={PRIVACY} aria-current={page === "privacy" ? "page" : undefined}>
                            privacy
                        </a>
                        <a href={SUPPORT} aria-current={page === "support" ? "page" : undefined}>
                            support
                        </a>
                    </div>
                    <a className="sd-nav-get" href={APP_STORE_URL} target="_blank" rel="noopener">
                        get the app
                    </a>
                </div>
            </nav>

            <main className="sd-main">
                {page === "support" ? <SupportBody email={email} /> : <PrivacyBody email={email} />}
            </main>

            <footer className="sd-foot">
                <a href={HOME}>sinced</a>
                <a href={PRIVACY}>privacy policy</a>
                <a href={SUPPORT}>support</a>
                <a href={`mailto:${email}`}>{email}</a>
            </footer>
        </div>
    )
}

SincedPrivacy.defaultProps = {
    page: "privacy",
    email: "adityakoltedes@gmail.com",
    stickyNav: true,
}

const fontFile = (title: string) => ({
    type: ControlType.File,
    title,
    allowedFileTypes: ["otf", "ttf", "woff", "woff2"],
})

addPropertyControls(SincedPrivacy, {
    alloRegular: fontFile("Allo Regular"),
    alloMedium: fontFile("Allo Medium"),
    alloSemiBold: fontFile("Allo SemiBold"),
    alloBold: fontFile("Allo Bold"),
    stickyNav: { type: ControlType.Boolean, title: "Sticky nav" },
    email: { type: ControlType.String, title: "Email" },
})

const CSS = `
.sd{
  --bg:#F6F5F1; --surface:#FFFFFF; --ink:#141417; --muted:#6E6E73; --hair:rgba(20,20,23,.08); --green:#488B5A;
  --gutter:max(20px, calc((100cqi - 1040px) / 2));
  container:sd/inline-size; width:100%; min-height:100%; background:var(--bg); color:var(--ink);
  font-family:"Allo Sinced","Allo",-apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif;
  -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale; box-sizing:border-box;
}
.sd *{box-sizing:border-box}
:where(.sd) :where(h1,h2,h3,p,ul){margin:0}
:where(.sd) a{color:inherit;text-decoration:none}

/* nav (matches the landing page) */
.sd-nav{z-index:20;background:rgba(246,245,241,.78);-webkit-backdrop-filter:saturate(180%) blur(20px);backdrop-filter:saturate(180%) blur(20px);border-bottom:1px solid var(--hair)}
.sd-nav-sticky{position:sticky;top:0}
.sd-nav-in{display:flex;align-items:center;gap:24px;height:52px;padding-inline:var(--gutter)}
.sd-nav-name{font-size:21px;font-weight:600;letter-spacing:-.02em;margin-right:auto}
.sd-nav-links{display:none;gap:24px;font-size:13px;color:var(--muted)}
.sd-nav-links a:hover,.sd-nav-links a[aria-current]{color:var(--ink)}
.sd-nav-get{font-size:13px;font-weight:500;background:var(--ink);color:#fff;border-radius:999px;padding:6px 14px;transition:opacity .2s}
.sd-nav-get:hover{opacity:.8}

.sd-main{max-width:760px;margin:0 auto;padding:72px 20px 0}

/* heading */
.sd-eyebrow{font-size:15px;font-weight:600;color:var(--green)}
.sd h1{font-size:clamp(44px,8cqi,72px);line-height:1;letter-spacing:-.045em;font-weight:700;margin-top:10px}
.sd-meta{font-size:14px;color:var(--muted);margin-top:16px}
.sd-lede{font-size:clamp(18px,2.1cqi,21px);line-height:1.5;color:var(--muted);margin-top:22px;text-wrap:pretty}

/* short version */
.sd-short{margin-top:56px}
.sd-short h2,.sd-faq h2{font-size:24px;letter-spacing:-.02em;font-weight:600}
.sd-cards{display:grid;gap:12px;margin-top:18px}
.sd-card{background:var(--surface);border-radius:20px;padding:22px 24px}
.sd-card h3{font-size:17px;font-weight:600;display:flex;gap:10px;align-items:baseline}
.sd-card h3::before{content:"";flex:none;width:8px;height:8px;border-radius:50%;background:var(--green);translate:0 -2px}
.sd-card p{font-size:16px;line-height:1.5;color:var(--muted);margin-top:6px;padding-left:18px}

/* policy prose */
.sd-prose{margin-top:24px}
.sd-prose h2{font-size:24px;letter-spacing:-.02em;font-weight:600;margin-top:48px;padding-top:28px;border-top:1px solid var(--hair)}
.sd-prose p,.sd-prose li{font-size:17px;line-height:1.6;color:#3a3a3e;text-wrap:pretty}
.sd-prose p{margin-top:12px}
.sd-prose ul{margin-top:12px;padding-left:20px;display:grid;gap:10px}
.sd-prose li::marker{color:var(--green)}
.sd-prose b{color:var(--ink);font-weight:600}
.sd-prose a,.sd-also a{color:var(--green);text-decoration:underline;text-underline-offset:3px}

/* support */
.sd-contact{margin-top:48px;background:var(--surface);border-radius:24px;padding:28px;display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:20px}
.sd-contact h2{font-size:22px;font-weight:600;letter-spacing:-.02em}
.sd-contact p{font-size:16px;color:var(--muted);margin-top:4px}
.sd-btn{background:var(--ink);color:#fff;border-radius:999px;padding:12px 20px;font-size:15px;font-weight:500;transition:opacity .2s,transform .15s;word-break:break-all}
.sd-btn:hover{opacity:.85}
.sd-btn:active{transform:scale(.97)}
.sd-faq{margin-top:64px}
.sd-faq details{border-bottom:1px solid var(--hair)}
.sd-faq h2{margin-bottom:8px}
.sd-faq summary{list-style:none;cursor:pointer;padding:20px 40px 20px 0;font-size:18px;font-weight:500;position:relative}
.sd-faq summary::-webkit-details-marker{display:none}
.sd-faq summary::after{content:"";position:absolute;right:8px;top:50%;width:10px;height:10px;border-right:2px solid var(--muted);border-bottom:2px solid var(--muted);transform:translateY(-70%) rotate(45deg);transition:transform .25s ease}
.sd-faq details[open] summary::after{transform:translateY(-30%) rotate(-135deg)}
.sd-faq details p{font-size:17px;line-height:1.6;color:#3a3a3e;padding:0 40px 22px 0}
.sd-faq b{font-weight:600;color:var(--ink)}
.sd-also{font-size:16px;color:var(--muted);margin-top:28px}

.sd-foot{display:flex;flex-wrap:wrap;justify-content:center;gap:8px 28px;max-width:760px;margin:96px auto 0;padding:24px 20px 48px;border-top:1px solid var(--hair);font-size:14px;color:var(--muted)}
.sd-foot a:hover{color:var(--ink)}

@container sd (min-width:760px){
  .sd-nav-links{display:flex}
  .sd-main{padding-top:104px}
  .sd-cards{grid-template-columns:repeat(3,1fr)}
  .sd-card p{padding-left:0}
  .sd-card h3{display:block}
  .sd-card h3::before{display:block;margin-bottom:14px;translate:none}
}
@media (prefers-reduced-motion:reduce){.sd *{transition:none!important}}
`
