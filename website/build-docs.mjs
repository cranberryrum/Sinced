// Generates SincedPrivacy.tsx and SincedSupport.tsx from SincedDoc.tsx,
// each locked to one page with no Page control. Run from website/: node build-docs.mjs
import { readFileSync, writeFileSync } from "node:fs"
const src = readFileSync(new URL("./SincedDoc.tsx", import.meta.url), "utf8")
for (const [page, name] of [["privacy", "SincedPrivacy"], ["support", "SincedSupport"]]) {
  let out = src
    .replace('const FIXED_PAGE: "privacy" | "support" | null = null', `const FIXED_PAGE: "privacy" | "support" | null = "${page}"`)
    .replace(/\/\/ Set by build-docs\.mjs.*\n/, "")
    .replace(/\bSincedDoc\b/g, name)
    .replace(/^\/\/ Sinced privacy policy and support pages[\s\S]*?\n\n/, `// Sinced ${page} page (adityakolte.com/sinced/${page}), as a Framer code component.\n// Generated from SincedDoc.tsx by build-docs.mjs. Width: Fill, Height: Fit; upload the four Allo font files.\n\n`)
    .replace(/    page: \{\n[\s\S]*?\n    \},\n/, "")
  if (out.includes("ControlType.Enum")) throw new Error("page control not removed")
  writeFileSync(new URL(`./${name}.tsx`, import.meta.url), out)
  console.log(name)
}
