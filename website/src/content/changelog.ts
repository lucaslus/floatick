import type { Locale } from './site-copy';

export type ChangelogEntry = {
  version: string;
  date: string;
  dateTime: string;
  title: string;
  summary: string;
  highlights: string[];
  releaseUrl: string;
  compareUrl?: string;
};

type ChangelogCopy = {
  meta: {
    title: string;
    description: string;
    canonicalPath: string;
    alternatePath: string;
  };
  nav: {
    home: string;
    download: string;
    languageLabel: string;
  };
  hero: {
    eyebrow: string;
    title: string;
    body: string;
  };
  releaseLink: string;
  compareLink: string;
  footer: string;
};

export const changelogCopy: Record<Locale, ChangelogCopy> = {
  en: {
    meta: {
      title: 'Floatick Changelog — Product Updates for macOS',
      description:
        'Read Floatick release notes, new features, fixes, and behavior changes.',
      canonicalPath: '/changelog/',
      alternatePath: '/zh/changelog/',
    },
    nav: {
      home: 'Back to Floatick',
      download: 'Download',
      languageLabel: '阅读中文更新日志',
    },
    hero: {
      eyebrow: 'Changelog',
      title: 'What changed.',
      body: 'New features, fixes, and behavior changes in each Floatick release.',
    },
    releaseLink: 'View GitHub release',
    compareLink: 'Compare changes',
    footer: 'Free and open source on GitHub.',
  },
  zh: {
    meta: {
      title: 'Floatick 更新日志 — macOS 产品更新',
      description: '查看 Floatick 各版本的新增功能、问题修复与行为变化。',
      canonicalPath: '/zh/changelog/',
      alternatePath: '/changelog/',
    },
    nav: {
      home: '返回 Floatick',
      download: '下载',
      languageLabel: 'Read the changelog in English',
    },
    hero: {
      eyebrow: '更新日志',
      title: '这次改了什么。',
      body: '记录每个 Floatick 版本的新增功能、问题修复和行为变化。',
    },
    releaseLink: '查看 GitHub Release',
    compareLink: '对比完整改动',
    footer: 'Floatick 在 GitHub 免费开源。',
  },
};

export const changelogEntries: Record<Locale, ChangelogEntry[]> = {
  en: [
    {
      version: 'v0.3.0',
      date: 'July 29, 2026',
      dateTime: '2026-07-29',
      title: 'Markdown copy and smoother long lists',
      summary:
        'This release adds complete Markdown copy and improves actions, floating-window behavior, and list performance.',
      highlights: [
        'Copy a todo title and notes together as Markdown.',
        'Use a consistent bottom sheet for todo actions throughout the app.',
        'Optionally collapse the main panel after clicking outside it.',
        'Keep scrolling responsive in local workspaces with up to 10,000 todos.',
      ],
      releaseUrl: 'https://github.com/lucaslushuo/floatick/releases/tag/v0.3.0',
      compareUrl: 'https://github.com/lucaslushuo/floatick/compare/v0.2.0...v0.3.0',
    },
    {
      version: 'v0.2.0',
      date: 'July 28, 2026',
      dateTime: '2026-07-28',
      title: 'Sticky Boards, details, and reusable tags',
      summary:
        'This release adds desktop boards, Markdown details, and reusable colored tags.',
      highlights: [
        'Create and pin color-coded Sticky Boards without duplicating todos.',
        'Add Markdown content and open todo details with a double click.',
        'Create, edit, search, and combine multiple color-coded tags.',
        'Choose appearance, always-on-top behavior, and open-at-login settings.',
      ],
      releaseUrl: 'https://github.com/lucaslushuo/floatick/releases/tag/v0.2.0',
      compareUrl: 'https://github.com/lucaslushuo/floatick/compare/v0.1.0...v0.2.0',
    },
    {
      version: 'v0.1.0',
      date: 'July 24, 2026',
      dateTime: '2026-07-24',
      title: 'First public release',
      summary:
        'The first version of Floatick ships its local-first floating todo list for macOS.',
      highlights: [
        'Keep todos locally in ~/.floatick with no account required.',
        'Run one Universal build on Apple silicon and Intel Macs.',
        'Switch between English and Simplified Chinese.',
        'Check for updates through Sparkle with EdDSA verification.',
      ],
      releaseUrl: 'https://github.com/lucaslushuo/floatick/releases/tag/v0.1.0',
    },
  ],
  zh: [
    {
      version: 'v0.3.0',
      date: '2026 年 7 月 29 日',
      dateTime: '2026-07-29',
      title: 'Markdown 复制与更顺滑的长列表',
      summary:
        '这个版本增加了完整的 Markdown 复制，并优化操作方式、悬浮窗口和列表性能。',
      highlights: [
        '将 Todo 标题和内容一起复制为 Markdown。',
        '在应用内统一使用底部抽屉处理 Todo 操作。',
        '支持点击窗口外部后自动收起主容器。',
        '在多达 10,000 条本地 Todo 下保持列表滚动响应。',
      ],
      releaseUrl: 'https://github.com/lucaslushuo/floatick/releases/tag/v0.3.0',
      compareUrl: 'https://github.com/lucaslushuo/floatick/compare/v0.2.0...v0.3.0',
    },
    {
      version: 'v0.2.0',
      date: '2026 年 7 月 28 日',
      dateTime: '2026-07-28',
      title: '便利板、Todo 详情与可复用标签',
      summary:
        '这个版本增加了桌面便利板、Markdown 详情和彩色标签。',
      highlights: [
        '创建并固定彩色便利板，同时不复制 Todo 数据。',
        '为 Todo 添加 Markdown 内容，并通过双击查看详情。',
        '创建、编辑、搜索并组合多个彩色标签。',
        '设置外观、始终置顶与登录时启动。',
      ],
      releaseUrl: 'https://github.com/lucaslushuo/floatick/releases/tag/v0.2.0',
      compareUrl: 'https://github.com/lucaslushuo/floatick/compare/v0.1.0...v0.2.0',
    },
    {
      version: 'v0.1.0',
      date: '2026 年 7 月 24 日',
      dateTime: '2026-07-24',
      title: '首个公开版本',
      summary:
        'Floatick 首次发布面向 macOS 的本地悬浮 Todo 清单。',
      highlights: [
        'Todo 保存在 ~/.floatick，无需注册账号。',
        '一个 Universal 安装包同时支持 Apple 芯片和 Intel Mac。',
        '支持英文与简体中文切换。',
        '通过 Sparkle 与 EdDSA 验证应用更新。',
      ],
      releaseUrl: 'https://github.com/lucaslushuo/floatick/releases/tag/v0.1.0',
    },
  ],
};
