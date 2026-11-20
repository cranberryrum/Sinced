# Sinced page for adityakolte.com/sinced

`SincedLanding.tsx` is a Framer code component that renders the whole Sinced one-pager: a sticky product nav, the hero with floating cards, the highlights rail, card themes, milestones, privacy, FAQ and the closing download section.

## Update the page in Framer

1. Open the existing `SincedLanding` code file in Framer, select everything, paste in the new `SincedLanding.tsx`, and save. The screenshot uploads you already made keep working, because the image slots have the same names.
2. Select the component on `/sinced`. Keep **Width: Fill** and **Height: Fit**.
3. In the right panel, upload the four font files from `assets/fonts/` into **Allo Regular**, **Allo Medium**, **Allo SemiBold** and **Allo Bold**. The page uses only these four weights.
4. Leave **Sticky nav** on. The Sinced bar sticks to the top once your portfolio nav scrolls away.
5. Make sure the page background is close to `#F6F5F1`, or leave it as is: the component paints its own background.

Image slots: App icon `sinced-icon.png`, Hero shot `sinced-hero.jpg`, Widgets, Runs, Reminders, Share and Anywhere use the matching `sinced-*.jpg`.

## Privacy and support pages

Each page has its own file, so there's nothing to set in Framer:

1. In Framer, add a code file named `SincedPrivacy` and paste in `SincedPrivacy.tsx`. Add another named `SincedSupport` and paste in `SincedSupport.tsx`.
2. Make a page with the path `/sinced/privacy` and drop `SincedPrivacy` on it. Make `/sinced/support` and drop `SincedSupport` on it. Set Width: Fill and Height: Fit on both.
3. Upload the four Allo font files into each, as on the landing page.
4. Paste the updated `SincedLanding.tsx` too. Its footer and nav now link to these pages instead of GitHub.
5. In App Store Connect, set the **Privacy Policy URL** to `https://adityakolte.com/sinced/privacy` and the **Support URL** to `https://adityakolte.com/sinced/support`.

Both files are generated from `SincedDoc.tsx`. To change the wording, edit `SincedDoc.tsx` and run `node build-docs.mjs`. The wording matches `PRIVACY.md` and `SUPPORT.md` in the repo; if you change the policy, update those too and bump `PRIVACY_UPDATED`.

## Editing

- Copy lives in the `HIGHLIGHTS`, `THEMES`, `MILESTONES`, `PROMISES` and `FAQ` arrays near the top of the file.
- The card patterns are the app's own SVGs (`assets/patterns/`), inlined at the bottom of the file. If they change, run `node build-patterns.mjs` from this folder.
- Allo is licensed under the SIL Open Font License (`assets/fonts/Allo-OFL.txt`), which allows using it on the web.

## Preview locally

Serve the repo root (for example `python3 -m http.server 4179 --directory ..`) and open `/website/preview.html`. `framer-shim.js` stands in for the `framer` package.
