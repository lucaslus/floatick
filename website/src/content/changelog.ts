import type { Locale } from './site-copy';
import { previewRelease, repositoryUrl } from '../config/site-links';

export type ChangelogEntry = {
  version: string;
  date: string;
  dateTime: string;
  title: string;
  summary: string;
  highlights: string[];
  status?: 'preview';
  releaseUrl?: string;
  sourceUrl?: string;
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
      description: '看看 Floatick 每个版本新增了什么、修好了什么。',
      canonicalPath: '/zh/changelog/',
      alternatePath: '/changelog/',
    },
    nav: {
      home: '返回 Floatick',
      download: '下载',
      languageLabel: '查看英文更新日志',
    },
    hero: {
      eyebrow: '更新日志',
      title: '每个版本都改了什么。',
      body: '新功能、问题修复和使用上的变化，都会记在这里。',
    },
    releaseLink: '查看 GitHub 发布页',
    compareLink: '查看完整改动',
    footer: 'Floatick 在 GitHub 免费开源。',
  },
};

export const changelogEntries: Record<Locale, ChangelogEntry[]> = {
  en: [
    {
      version: `v${previewRelease.version}`,
      status: 'preview',
      date: 'September 4, 2026',
      dateTime: '2026-09-04',
      title: 'A new home in your menu bar',
      summary:
        'In development: a menu bar app with a new editor for todos and notes. The current download is still v0.3.4.',
      highlights: [
        'Open from the menu bar and see how many tasks are left.',
        'Switch between reading and editing, with checklists, headings, and Markdown copy.',
        'Find tasks and notes with shared tags and combined filters.',
        'See due dates and overdue tasks in the list. Reminder delivery is not available in this preview yet.',
      ],
      sourceUrl: previewRelease.sourceUrl,
      compareUrl: `${repositoryUrl}/compare/v0.3.4...refactor/tauri`,
    },
    {
      version: 'v0.3.4',
      date: 'August 13, 2026',
      dateTime: '2026-08-13',
      title: 'Focused todos, deadlines, and reminders',
      summary:
        'This release adds a clear Doing state and a lightweight deadline workflow that keeps active and overdue tasks visible without system notification noise.',
      highlights: [
        'Move tasks through Todo, Doing, and Done, and filter the list to active work.',
        'Set or edit deadlines from the todo editor or directly from the list.',
        'Choose advance reminders and receive compact native in-app alerts when they are due.',
        'Keep overdue work visible and preserve deadline delivery state in local storage.',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.4',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.3...v0.3.4',
    },
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
      version: `v${previewRelease.version}`,
      status: 'preview',
      date: '2026 年 9 月 4 日',
      dateTime: '2026-09-04',
      title: '待办和笔记，搬到菜单栏',
      summary:
        '正在开发中的新版：从菜单栏打开待办和笔记，搭配新的阅读与编辑界面。当前可下载的正式版仍为 v0.3.4。',
      highlights: [
        '点击菜单栏图标展开，角标显示未完成待办数。',
        '可切换阅读与编辑，支持任务清单、标题和 Markdown 复制。',
        '待办和笔记共用彩色标签，支持组合筛选。',
        '在列表中查看截止时间与逾期状态；预览版尚未提供到点弹出提醒。',
      ],
      sourceUrl: previewRelease.sourceUrl,
      compareUrl: `${repositoryUrl}/compare/v0.3.4...refactor/tauri`,
    },
    {
      version: 'v0.3.4',
      date: '2026 年 8 月 13 日',
      dateTime: '2026-08-13',
      title: '进行中的待办、截止时间和提醒',
      summary:
        '现在可以更清楚地看到手头正在做什么，也能给待办加上截止时间和提醒，不需要开启系统通知。',
      highlights: [
        '把待办标成“进行中”，并只查看正在做的任务。',
        '在编辑器或列表里设置和修改截止时间。',
        '按需要设置提前提醒，到点后会收到应用内提醒。',
        '逾期任务会一直标出来，提醒状态也会保存在本机。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.4',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.3...v0.3.4',
    },
    {
      version: 'v0.3.3',
      date: '2026 年 8 月 5 日',
      dateTime: '2026-08-05',
      title: '待办旁边，多了一个随手记',
      summary:
        '现在可以在 Floatick 里记灵感、工作记录和临时片段，不用把所有内容都塞进待办。',
      highlights: [
        '在同一个悬浮面板里切换待办和笔记。',
        '笔记支持搜索、置顶、归档、恢复和自动保存。',
        '待办和笔记可以共用同一套彩色标签。',
        '在同一页里编辑标题和 Markdown 正文。',
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
        'GitHub 账号地址变更后，应用内检查更新一度不可用。这个版本修好了它。',
      highlights: [
        '把应用内更新检查切换到新的 GitHub Pages 地址。',
        '发布前会检查安装包里的更新地址和线上更新源。',
        '如果你在用 v0.3.0 或 v0.3.1，需要手动安装一次这个版本。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.2',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.1...v0.3.2',
    },
    {
      version: 'v0.3.1',
      date: '2026 年 7 月 31 日',
      dateTime: '2026-07-31',
      title: '设置文字更清楚，手机预览也更好看',
      summary:
        '较长的设置文字不再被过早截断，手机上的官网产品预览也更清楚。',
      highlights: [
        '较长的设置项最多可以显示两行。',
        '手机上会显示更清楚、更靠近的 3D 产品预览。',
        '窄屏下隐藏过大的背景板，把注意力留给应用界面。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.1',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.3.0...v0.3.1',
    },
    {
      version: 'v0.3.0',
      date: '2026 年 7 月 29 日',
      dateTime: '2026-07-29',
      title: '待办可以完整复制，长列表也更流畅',
      summary:
        '现在可以把一个待办完整复制成 Markdown，同时也改进了操作方式、悬浮窗口和长列表表现。',
      highlights: [
        '把待办标题和正文一起复制成 Markdown。',
        '待办操作统一放到底部面板里。',
        '可以选择点到窗口外时自动收起主面板。',
        '本机有多达 10,000 条待办时，列表滚动依然流畅。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.3.0',
      compareUrl: 'https://github.com/lucaslus/floatick/compare/v0.2.0...v0.3.0',
    },
    {
      version: 'v0.2.0',
      date: '2026 年 7 月 28 日',
      dateTime: '2026-07-28',
      title: '待办详情和可重复使用的标签',
      summary:
        '待办现在可以写 Markdown 正文，也可以用彩色标签整理，还增加了一些常用的 macOS 设置。',
      highlights: [
        '给待办添加 Markdown 正文，双击就能查看详情。',
        '创建、编辑、搜索和组合多个彩色标签。',
        '可以设置外观、窗口置顶和开机启动。',
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
        'Floatick 的第一个公开版本：一份放在 macOS 桌面上、数据只存在本机的待办清单。',
      highlights: [
        '待办保存在 ~/.floatick，不用注册账号。',
        '同一个安装包支持 Apple 芯片和 Intel Mac。',
        '支持英文与简体中文切换。',
        '通过 Sparkle 与 EdDSA 验证应用更新。',
      ],
      releaseUrl: 'https://github.com/lucaslus/floatick/releases/tag/v0.1.0',
    },
  ],
};
