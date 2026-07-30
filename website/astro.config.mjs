// @ts-check
import sitemap from '@astrojs/sitemap';
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://floatick.pages.dev',
  output: 'static',
  i18n: {
    locales: [
      'en',
      {
        path: 'zh',
        codes: ['zh-CN', 'zh'],
      },
    ],
    defaultLocale: 'en',
    routing: {
      prefixDefaultLocale: false,
    },
  },
  integrations: [sitemap()],
});
