// Inlines the app's card pattern SVGs into SincedLanding.tsx as data URIs.
// Run from website/: node build-patterns.mjs
import { readFileSync, writeFileSync, readdirSync } from "node:fs"
const dir = new URL("./assets/patterns/", import.meta.url)
const entries = readdirSync(dir).filter((f) => f.endsWith(".svg")).sort().map((f) => {
  const svg = readFileSync(new URL(f, dir), "utf8").replace(/>\s+</g, "><").trim()
  const uri = "data:image/svg+xml," + encodeURIComponent(svg).replace(/%20/g, " ").replace(/%3D/g, "=").replace(/%3A/g, ":").replace(/%2F/g, "/").replace(/%22/g, "'")
  return `    ${f.replace(".svg", "").toLowerCase()}: ${JSON.stringify(uri.replace(/'/g, "%27"))},`
})
const file = new URL("./SincedLanding.tsx", import.meta.url)
const src = readFileSync(file, "utf8")
const block = `// BEGIN PATTERNS\nconst PATTERNS = {\n${entries.join("\n")}\n}\n// END PATTERNS`
writeFileSync(file, src.replace(/\/\/ BEGIN PATTERNS[\s\S]*\/\/ END PATTERNS/, block))
console.log("patterns:", entries.length)
