export type Locale = 'en' | 'zh';

type Feature = {
  number: string;
  title: string;
  body: string;
};

type WorkflowStep = {
  label: string;
  title: string;
  body: string;
};

type SiteCopy = {
  meta: {
    lang: 'en' | 'zh-CN';
    title: string;
    description: string;
    canonicalPath: string;
    alternatePath: string;
  };
  nav: {
    features: string;
    workflow: string;
    privacy: string;
    changelog: string;
    download: string;
    languageLabel: string;
  };
  hero: {
    eyebrow: string;
    titleBefore: string;
    titleAccent: string;
    body: string;
    download: string;
    github: string;
    compatibility: string;
  };
  proof: Array<{
    value: string;
    label: string;
  }>;
  features: {
    eyebrow: string;
    title: string;
    body?: string;
    items: Feature[];
  };
  workflow: {
    eyebrow: string;
    title: string;
    body?: string;
    steps: WorkflowStep[];
  };
  privacy: {
    eyebrow: string;
    title: string;
    body: string;
    points: string[];
    pathLabel: string;
  };
  updates: {
    eyebrow: string;
    title: string;
    body?: string;
    latestLabel: string;
    version: string;
    date: string;
    dateTime: string;
    highlights: string[];
    viewAll: string;
  };
  faq: {
    eyebrow: string;
    title: string;
    body?: string;
    items: Array<{
      question: string;
      answer: string;
    }>;
  };
  finalCta: {
    eyebrow: string;
    title: string;
    body: string;
    download: string;
    github: string;
  };
  footer: {
    tagline: string;
    source: string;
    releases: string;
    license: string;
    language: string;
  };
};

export const siteCopy: Record<Locale, SiteCopy> = {
  en: {
    meta: {
      lang: 'en',
      title: 'Floatick — Native macOS Menu Bar Todos & Notes',
      description:
        'A lightweight, open-source macOS menu bar app for tasks and quick notes. Built with Tauri v2 and Rust.',
      canonicalPath: '/',
      alternatePath: '/zh/',
    },
    nav: {
      features: 'Features',
      workflow: 'Workflow',
      privacy: 'Privacy',
      changelog: 'Changelog',
      download: 'Download',
      languageLabel: 'Read in Chinese',
    },
    hero: {
      eyebrow: 'macOS Menu Bar Todos & Notes',
      titleBefore: 'Capture fast.',
      titleAccent: 'Finish with focus.',
      body:
        'Lives quietly in your Menu Bar. Capture tasks and notes in seconds, without breaking your flow.',
      download: 'Download for macOS',
      github: 'View on GitHub',
      compatibility: 'macOS 10.15+ · Apple silicon and Intel',
    },
    proof: [
      { value: 'One Click', label: 'Instant access right from your Menu Bar' },
      { value: 'Lightweight', label: 'Sub-30MB footprint, fast and quiet' },
      { value: 'On Time', label: 'Clear deadlines and gentle reminders' },
      { value: 'Local-First', label: '100% on your Mac, zero cloud sync' },
    ],
    features: {
      eyebrow: 'Features',
      title: 'Everything you need, right at your fingertips.',
      items: [
        {
          number: '01',
          title: 'macOS Menu Bar',
          body:
            'Lives in your status bar with a live pending badge. Click to open.',
        },
        {
          number: '02',
          title: 'Full-Width Cards',
          body:
            'Long titles never truncate. Floating capsules reveal actions on hover.',
        },
        {
          number: '03',
          title: 'Deadlines & Reminders',
          body:
            'Set due dates with one click. Clear status without noisy banners.',
        },
        {
          number: '04',
          title: 'TipTap Markdown',
          body:
            'Press / for interactive checklists, headings, code blocks, and quotes.',
        },
        {
          number: '05',
          title: 'Color Tags',
          body:
            'Shared color tags across tasks and notes for fast, flexible filtering.',
        },
        {
          number: '06',
          title: 'Rust & Tauri 2',
          body:
            'Sub-30MB idle footprint, instant launch, and optional start at login.',
        },
      ],
    },
    workflow: {
      eyebrow: 'Workflow',
      title: 'Capture, schedule, finish.',
      steps: [
        {
          label: 'Capture',
          title: 'Quick capture in seconds',
          body:
            'Click the icon or press ⌘N to jot down thoughts without breaking flow.',
        },
        {
          label: 'Schedule',
          title: 'Add deadlines and tags',
          body:
            'Set due dates or color tags to keep your daily priorities clear.',
        },
        {
          label: 'Finish',
          title: 'Check off and move on',
          body:
            'Check tasks off or copy the full context as clean Markdown.',
        },
      ],
    },
    privacy: {
      eyebrow: 'Privacy & Storage',
      title: 'Local-first. 100% on your Mac.',
      body:
        'All your todos, notes, and settings are saved locally as plain files.',
      points: [
        'Plain text files: view, export, or back up anytime.',
        'Zero tracking: no accounts, no cloud servers, no telemetry.',
        '100% offline: connects only when checking for updates.',
      ],
      pathLabel: 'Storage Directory',
    },
    updates: {
      eyebrow: 'Changelog',
      title: "What's new",
      latestLabel: 'Latest Release',
      version: 'v0.4.0',
      date: 'September 4, 2026',
      dateTime: '2026-09-04',
      highlights: [
        'Full-width title layout with floating action capsules.',
        'Instant click-to-complete separated from the editor drawer.',
        'TipTap rich text editor with / slash commands and checklists.',
      ],
      viewAll: 'View Full Changelog',
    },
    faq: {
      eyebrow: 'FAQ',
      title: 'Frequently asked questions',
      items: [
        {
          question: 'What is Floatick designed for?',
          answer:
            'Quick todos and notes in your macOS Menu Bar without the weight of complex project tools.',
        },
        {
          question: 'Where is my data stored?',
          answer:
            'Locally in ~/.floatick on your Mac. Plain text files, no accounts, and zero cloud sync.',
        },
        {
          question: 'How do deadline reminders work?',
          answer:
            'Set due dates with one click. Tasks highlight in-app when upcoming or overdue, without noisy banners.',
        },
        {
          question: 'Can I take notes with Floatick?',
          answer:
            'Yes. Notes has a dedicated tab with TipTap Markdown editing, slash commands, and code blocks.',
        },
        {
          question: 'Which Macs are supported?',
          answer:
            'Native universal binary for both Apple silicon and Intel, running macOS 10.15 or later.',
        },
        {
          question: 'Can I copy tasks as Markdown?',
          answer:
            'Yes. Hover over any task card and click copy to export the title and notes as clean Markdown.',
        },
      ],
    },
    finalCta: {
      eyebrow: 'For macOS',
      title: 'Capture fast. Finish with focus.',
      body: 'Free, open source, and local-first for macOS.',
      download: 'Download for macOS',
      github: 'View on GitHub',
    },
    footer: {
      tagline: 'Local-first macOS Menu Bar todos and notes.',
      source: 'Source',
      releases: 'Changelog',
      license: 'MIT License',
      language: '简体中文',
    },
  },
  zh: {
    meta: {
      lang: 'zh-CN',
      title: 'Floatick — 常驻 macOS 菜单栏的待办与便签',
      description:
        'Floatick 是一款专为 macOS 设计的极简菜单栏待办与便签应用。点击即开，支持截止时间提醒、TipTap Markdown 编辑与本地隐私存储。',
      canonicalPath: '/zh/',
      alternatePath: '/',
    },
    nav: {
      features: '功能特性',
      workflow: '使用流程',
      privacy: '隐私与存储',
      changelog: '更新日志',
      download: '下载',
      languageLabel: 'Read in English',
    },
    hero: {
      eyebrow: 'macOS 菜单栏待办与便签',
      titleBefore: '随手记，',
      titleAccent: '专心做。',
      body:
        '常驻 macOS 菜单栏。点开即记待办与便签，轻巧随手，不扰专注。',
      download: '下载 macOS 版',
      github: 'GitHub 源码',
      compatibility: 'macOS 10.15+ · 原生支持 Apple 芯片与 Intel',
    },
    proof: [
      { value: '点开即记', label: '常驻手边，不扰工作' },
      { value: '轻巧极速', label: '极低内存，秒开秒关' },
      { value: '到点提醒', label: '临近与逾期清晰标识' },
      { value: '本地存储', label: '零账号，数据只在本机' },
    ],
    features: {
      eyebrow: '核心特性',
      title: '恰到好处的轻巧。',
      items: [
        {
          number: '01',
          title: '常驻菜单栏',
          body:
            '常驻右上角状态栏，角标显示未完成数，点击即开。',
        },
        {
          number: '02',
          title: '全宽卡片与悬浮胶囊',
          body:
            '长标题全宽展示无遮挡，悬浮呼出截止时间、编辑与复制。',
        },
        {
          number: '03',
          title: '截止时间与提醒',
          body:
            '按需设定截止时间，临近与逾期清晰高亮，不弹吵闹通知。',
        },
        {
          number: '04',
          title: 'TipTap Markdown',
          body:
            '输入 / 唤出任务清单、多级标题、代码块与引用。',
        },
        {
          number: '05',
          title: '彩色标签分类',
          body:
            '待办与笔记共享彩色标签，支持快速多维度筛选。',
        },
        {
          number: '06',
          title: '极简省电架构',
          body:
            '基于 Tauri 2 与 Rust 构建，内存占用极低，支持开机自启。',
        },
      ],
    },
    workflow: {
      eyebrow: '使用流程',
      title: '记下，排期，完成。',
      steps: [
        {
          label: '捕捉',
          title: '点击菜单栏随时记下',
          body:
            '点击图标或按 ⌘N，随时记下闪过的想法或任务。',
        },
        {
          label: '排期',
          title: '按需添加时间与标签',
          body:
            '设定截止时间或分配彩色标签，轻重缓急一目了然。',
        },
        {
          label: '了结',
          title: '做完随手勾销',
          body:
            '做完即勾，亦可一键完整复制为 Markdown 分享。',
        },
      ],
    },
    privacy: {
      eyebrow: '隐私与存储',
      title: '数据只存本机，完全属于你。',
      body:
        '所有待办、笔记与设置均保存在本地明文文件，不上传任何云端。',
      points: [
        '明文文件：随时自由查看、导出与备份',
        '零账号零追踪：无云端服务器，不收集任何数据',
        '100% 离线：仅在手动检查更新时发起网络请求',
      ],
      pathLabel: '本地存储目录',
    },
    updates: {
      eyebrow: '更新日志',
      title: '持续打磨',
      latestLabel: '最新版本',
      version: 'v0.4.0',
      date: '2026 年 9 月 4 日',
      dateTime: '2026-09-04',
      highlights: [
        '全宽标题排版，次行悬浮操作胶囊',
        '快速勾选与 TipTap 独立编辑抽屉',
        'TipTap 斜杠命令、清单与代码块',
      ],
      viewAll: '查看完整更新日志',
    },
    faq: {
      eyebrow: '常见问题',
      title: '常见问题',
      items: [
        {
          question: 'Floatick 适合怎样的场景？',
          answer:
            '适合想要在 macOS 菜单栏随时速记待办与碎片便签、不希望被庞杂工具打扰专注的用户。',
        },
        {
          question: '我的数据保存在哪里？',
          answer:
            '保存在本机 ~/.floatick 目录下。明文存储，无需注册，不经过任何云端。',
        },
        {
          question: '截止时间提醒是如何工作的？',
          answer:
            '为待办设定截止时间后，临近与逾期状态会在应用内清晰标记，没有吵闹的系统横幅。',
        },
        {
          question: '可以用 Floatick 记录便签笔记吗？',
          answer:
            '可以。笔记拥有独立标签页与 TipTap Markdown 编辑抽屉，支持 / 命令与代码块。',
        },
        {
          question: '支持哪些 Mac 机型？',
          answer:
            '原生适配 Apple 芯片（M 系列）与 Intel 架构，支持 macOS 10.15 及以上系统。',
        },
        {
          question: '可以把待办导出或分享吗？',
          answer:
            '悬浮在卡片上点击复制，即可将标题与正文完整复制为 Markdown 格式。',
        },
      ],
    },
    finalCta: {
      eyebrow: '专为 macOS 打造',
      title: '随手记，专心做。',
      body: '免费开源 · 数据只存本机 · 原生支持 Apple 芯片与 Intel',
      download: '下载 macOS 版',
      github: '在 GitHub 查看',
    },
    footer: {
      tagline: 'macOS 菜单栏轻量待办与便签',
      source: '源代码',
      releases: '更新日志',
      license: 'MIT 许可证',
      language: 'English',
    },
  },
};
