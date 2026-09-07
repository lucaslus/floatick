import { stableRelease } from '../config/site-links';

export type Locale = 'en' | 'zh';

type SiteCopy = {
  meta: {
    lang: 'en' | 'zh-CN';
    title: string;
    description: string;
    canonicalPath: string;
    alternatePath: string;
  };
  nav: { features: string; privacy: string; changelog: string; download: string; languageLabel: string };
  hero: {
    eyebrow: string;
    titleBefore: string;
    titleAccent: string;
    body: string;
    detail: string;
    download: string;
    github: string;
    compatibility: string;
    releaseNote: string;
    facts: string[];
  };
  features: {
    eyebrow: string;
    title: string;
    items: Array<{ title: string; body: string; detail: string }>;
  };
  privacy: { eyebrow: string; title: string; body: string; points: string[]; note: string; source: string };
  faq: { eyebrow: string; title: string; items: Array<{ question: string; answer: string }> };
  finalCta: { title: string; body: string; download: string; releaseNote: string; changelog: string };
  footer: { tagline: string; source: string; license: string; language: string };
};

export const siteCopy: Record<Locale, SiteCopy> = {
  en: {
    meta: {
      lang: 'en',
      title: 'Floatick — A little space for todos & notes',
      description: 'Todos and notes, close at hand on your Mac. Free, open source, and saved on your device. Keep everyday tasks and ideas in your Mac menu bar.',
      canonicalPath: '/',
      alternatePath: '/zh/',
    },
    nav: { features: 'Features', privacy: 'Your data', changelog: 'Changelog', download: 'Download', languageLabel: '阅读中文版' },
    hero: {
      eyebrow: 'A little space in your Mac menu bar',
      titleBefore: 'Jot it down.',
      titleAccent: 'Get it done.',
      body: 'Your todos and notes, just a click away.',
      detail: 'Catch a thought. Check off a task. Get back to your day.',
      download: 'Download for macOS',
      github: 'View source',
      compatibility: 'macOS 10.15+ · Apple silicon & Intel',
      releaseNote: `Current release · v${stableRelease.version}`,
      facts: ['Free & open source', 'No account needed', 'Saved on your Mac'],
    },
    features: {
      eyebrow: 'Room for your everyday',
      title: 'A few things, done well.',
      items: [
        { title: 'Catch the little things.', body: 'A task for later. A thought worth keeping. Give it a home before it slips away.', detail: 'Todos & notes, side by side' },
        { title: 'Make space for the details.', body: 'Turn a quick note into a checklist, a meeting plan, or a few lines of Markdown.', detail: 'Checklists · Headings · Markdown copy' },
        { title: 'Keep today in view.', body: 'Add a due date, find things with shared tags, and check them off when you’re done.', detail: 'Due dates · Tags · Search' },
      ],
    },
    privacy: {
      eyebrow: 'Yours, from the first note',
      title: 'On your Mac.\nIn your hands.',
      body: 'Your todos and notes live in a local folder. No sign-up, no cloud workspace. Back up the files whenever you like.',
      points: ['No account', 'No cloud sync', 'Readable files'],
      note: 'One folder. Your own copy of everything.',
      source: 'Explore the source on GitHub',
    },
    faq: {
      eyebrow: 'Before you start',
      title: 'A few useful answers.',
      items: [
        { question: 'Which version am I downloading?', answer: `The download is v${stableRelease.version}, with the menu bar app and editor shown on this page. One Universal installer works on Apple silicon and Intel Macs.` },
        { question: 'Will it work on my Mac?', answer: 'The current release supports macOS 10.15 and later, on both Apple silicon and Intel. The same download works for both.' },
        { question: 'Can I sync or back up my notes?', answer: 'Floatick does not sync between devices. Your todos, notes, tags, and settings are saved in ~/.floatick. Copy that folder to keep a backup.' },
        { question: 'How do due dates and reminders work?', answer: 'You can set due dates and see overdue tasks in the list. v0.4.0 does not yet include the reminder popups from v0.3.4.' },
      ],
    },
    finalCta: {
      title: 'One less thing to keep in your head.',
      body: 'A small home for the things on your mind.',
      download: 'Download Floatick',
      releaseNote: `Current release · v${stableRelease.version}`,
      changelog: 'See what’s changing',
    },
    footer: { tagline: 'A little space for todos & notes.', source: 'GitHub', license: 'MIT License', language: '简体中文' },
  },
  zh: {
    meta: {
      lang: 'zh-CN',
      title: 'Floatick — 随手记，专心做。',
      description: '给待办和笔记一个顺手的位置。Floatick 免费开源，无需注册，数据保存在本机。从 Mac 菜单栏随手记下日常任务和灵感。',
      canonicalPath: '/zh/',
      alternatePath: '/',
    },
    nav: { features: '功能', privacy: '数据与隐私', changelog: '更新日志', download: '下载', languageLabel: 'Read in English' },
    hero: {
      eyebrow: '待办和笔记，就在 Mac 菜单栏',
      titleBefore: '随手记，',
      titleAccent: '专心做。',
      body: '点开记下，做完勾掉。',
      detail: '让琐事有处安放，把注意力留给眼前。',
      download: '下载 macOS 版',
      github: '查看源码',
      compatibility: 'macOS 10.15+ · Apple 芯片与 Intel',
      releaseNote: `当前正式版 · v${stableRelease.version}`,
      facts: ['免费开源', '无需注册', '数据只存本机'],
    },
    features: {
      eyebrow: '刚好够用',
      title: '日常小事，顺手就好。',
      items: [
        { title: '想到，就记下来。', body: '临时待办、闪过的灵感，点开就记。不用先想好该放进哪个项目。', detail: '待办与笔记，一处收好' },
        { title: '细节，也放得下。', body: '列一份清单，写几行会议笔记。需要分享时，一键复制成 Markdown。', detail: '清单 · 标题 · Markdown 复制' },
        { title: '手头的事，一眼清楚。', body: '按需加上截止时间，用标签整理和查找。做完一件，就勾掉一件。', detail: '截止时间 · 标签 · 搜索' },
      ],
    },
    privacy: {
      eyebrow: '从第一条笔记开始，就属于你',
      title: '存在本机，\n自己掌握。',
      body: '待办和笔记保存在 Mac 的本地文件夹里。无需账号，不同步到云端。想备份时，复制一份就好。',
      points: ['不用账号', '不传云端', '文件可读'],
      note: '一个文件夹，装下你记过的事。',
      source: '在 GitHub 查看源代码',
    },
    faq: {
      eyebrow: '开始之前',
      title: '你可能想知道。',
      items: [
        { question: '现在下载的是哪个版本？', answer: `当前下载为 v${stableRelease.version}，包含页面展示的菜单栏界面和新版编辑器。同一个安装包支持 Apple 芯片和 Intel Mac。` },
        { question: '我的 Mac 能用吗？', answer: '当前正式版支持 macOS 10.15 及以上系统。Apple 芯片和 Intel Mac 使用同一个安装包。' },
        { question: '可以同步或备份数据吗？', answer: '目前不支持设备间同步。待办、笔记、标签和设置都保存在 ~/.floatick 文件夹中，复制整个文件夹即可备份。' },
        { question: '截止时间到了会怎么提醒？', answer: '可以设置截止时间，在列表查看到期和逾期状态。v0.4.0 暂未迁移 v0.3.4 的到点弹出提醒。' },
      ],
    },
    finalCta: {
      title: '少一件挂在心上的事。',
      body: '给待办和笔记，一个顺手的位置。',
      download: '下载 Floatick',
      releaseNote: `当前正式版 · v${stableRelease.version}`,
      changelog: '看看最近的变化',
    },
    footer: { tagline: '给待办和笔记，一个顺手的位置。', source: 'GitHub', license: 'MIT 许可证', language: 'English' },
  },
};
