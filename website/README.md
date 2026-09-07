# Floatick website

The bilingual Floatick product website is built with Astro and outputs static
HTML for Cloudflare Pages.

## Local development

```bash
npm install
npm run dev
```

Astro prints the local preview URL after startup. English is served at `/` and
Simplified Chinese at `/zh/`.

## Product preview and downloads

The homepage shows the v0.4.0 menu bar app. `src/config/site-links.ts` keeps the
public version and pinned download URL together. Update it after publishing a
release, alongside the version notices in `site-copy.ts` and `changelog.ts`.
Do not label a development build as the latest published release.

The six `public/images/product-{todos,notes,editor}-{en,zh}.png` images are 2×
captures of the real React interface at 440 × 700 CSS pixels, populated with
fictional everyday tasks. Capture in the browser mock mode, never from a user's
local workspace. The showcase supports clicks, arrow keys, Home/End, and a
JavaScript-free fallback.

The menu bar uses Floatick's actual template tray icon and native SF Symbols
exported with AppKit. Regenerate the four system symbols on macOS with
`xcrun swift scripts/export-menubar-symbols.swift public/images/menubar`.
Its sample date and time match the product captures; it is a static preview.

## Production build

```bash
npm run build
npm run preview
```

The static output is written to `dist/`.

## Cloudflare Pages

Cloudflare Pages is connected to this repository. Pushes to `main` deploy the
production website; development branches receive preview deployments. GitHub
reports the result through the `Cloudflare Pages` check. The project uses:

```text
Root directory: website
Build command: npm run build
Build output directory: dist
Production branch: main
```
