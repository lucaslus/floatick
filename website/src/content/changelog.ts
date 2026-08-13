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
      version: 'v0.3.3',
      date: 'August 5, 2026',
      dateTime: '2026-08-05',
      title: 'Lightweight notes beside your todos',
      summary:
        'This release adds a focused Notes workspace for ideas, logs, snippets, and other details that are not tasks.',
      highlights: [
        'Switch between Todos and Notes inside the same floating panel.',
        'Search, pin, archive, restore, and automatically save local notes.',
        'Reuse the same colored tags across todos and notes.',
        'Edit titles and Markdown content in one continuous document surface.',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.3',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.2...v0.3.3',
    },
    {
      version: 'v0.3.2',
      date: 'July 31, 2026',
      dateTime: '2026-07-31',
      title: 'Update checks restored',
      summary:
        'This hotfix restores the Sparkle update feed after the GitHub account address changed.',
      highlights: [
        'Point in-app update checks to the active GitHub Pages feed.',
        'Verify the built app feed address and live appcast before publishing a release.',
        'Users on v0.3.0 or v0.3.1 need to install this update manually once.',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.2',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.1...v0.3.2',
    },
    {
      version: 'v0.3.1',
      date: 'July 31, 2026',
      dateTime: '2026-07-31',
      title: 'Clearer Settings and mobile preview',
      summary:
        'This patch keeps long Settings labels readable and improves the mobile product showcase.',
      highlights: [
        'Show compact Settings labels on up to two lines instead of truncating them.',
        'Render a sharper, closer 3D product view on mobile.',
        'Remove the oversized 3D backdrop on narrow screens so the app panels stay in focus.',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.1',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.0...v0.3.1',
    },
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
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.0',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.2.0...v0.3.0',
    },
    {
      version: 'v0.2.0',
      date: 'July 28, 2026',
      dateTime: '2026-07-28',
      title: 'Todo details and reusable tags',
      summary:
        'This release adds Markdown details, reusable colored tags, and more macOS controls.',
      highlights: [
        'Add Markdown content and open todo details with a double click.',
        'Create, edit, search, and combine multiple color-coded tags.',
        'Choose appearance, always-on-top behavior, and open-at-login settings.',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.2.0',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.1.0...v0.2.0',
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
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.1.0',
    },
  ],
  zh: [
    {
      version: 'v0.3.3',
      date: '2026 年 8 月 5 日',
      dateTime: '2026-08-05',
      title: 'Todo 旁边的轻量笔记',
      summary:
        '这个版本新增独立的 Notes 空间，用来记录灵感、日志、片段，以及那些并不是任务的内容。',
      highlights: [
        '在同一个悬浮面板中随时切换 Todo 与 Notes。',
        '搜索、置顶、归档、恢复并自动保存本地笔记。',
        'Todo 与笔记复用同一套彩色标签。',
        '在一体式文档区域中编辑标题与 Markdown 内容。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.3',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.2...v0.3.3',
    },
    {
      version: 'v0.3.2',
      date: '2026 年 7 月 31 日',
      dateTime: '2026-07-31',
      title: '恢复应用更新检查',
      summary:
        '这个热修复解决 GitHub 账号地址变更后 Sparkle 更新源不可用的问题。',
      highlights: [
        '将应用内更新检查切换到当前有效的 GitHub Pages 地址。',
        '发布前校验构建产物中的更新地址和线上 appcast。',
        'v0.3.0 或 v0.3.1 用户需要手动安装一次这个版本。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.2',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.1...v0.3.2',
    },
    {
      version: 'v0.3.1',
      date: '2026 年 7 月 31 日',
      dateTime: '2026-07-31',
      title: '更清晰的设置项与移动端预览',
      summary:
        '这个补丁让较长的设置项文案保持可读，并优化移动端产品展示。',
      highlights: [
        '紧凑设置项最多显示两行，不再过早截断。',
        '移动端使用更清晰、更聚焦的 3D 产品视图。',
        '窄屏隐藏过大的 3D 背景板，让应用面板成为视觉焦点。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.1',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.0...v0.3.1',
    },
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
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.0',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.2.0...v0.3.0',
    },
    {
      version: 'v0.2.0',
      date: '2026 年 7 月 28 日',
      dateTime: '2026-07-28',
      title: 'Todo 详情与可复用标签',
      summary:
        '这个版本增加了 Markdown 详情、可复用彩色标签和更多 macOS 设置。',
      highlights: [
        '为 Todo 添加 Markdown 内容，并通过双击查看详情。',
        '创建、编辑、搜索并组合多个彩色标签。',
        '设置外观、始终置顶与登录时启动。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.2.0',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.1.0...v0.2.0',
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
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.1.0',
    },
  ],
};
