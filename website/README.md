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

## Production build

```bash
npm run build
npm run preview
```

The static output is written to `dist/`.

## Cloudflare Pages

Deployment is intentionally deferred while the website is developed locally.
When enabled, configure Pages with:

```text
Root directory: website
Build command: npm run build
Build output directory: dist
Production branch: main
```
