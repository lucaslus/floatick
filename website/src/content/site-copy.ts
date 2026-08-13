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
    body: string;
    items: Feature[];
  };
  workflow: {
    eyebrow: string;
    title: string;
    body: string;
    steps: WorkflowStep[];
  };
  agent: {
    eyebrow: string;
    title: string;
    body: string;
    sourceLabel: string;
    sourceTitle: string;
    sourceContent: string;
    sourceTags: [string, string];
    resultLabel: string;
    copied: string;
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
    body: string;
    latestLabel: string;
    version: string;
    date: string;
    dateTime: string;
    highlights: string[];
    viewAll: string;
  };
  community: {
    eyebrow: string;
    title: string;
    body: string;
    points: string[];
    contribute: string;
    suggest: string;
  };
  faq: {
    eyebrow: string;
    title: string;
    body: string;
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
      title: 'Floatick — Floating Todos & Notes for macOS',
      description:
        'A free, open-source floating todo and quick notes app for macOS with a focused Doing state, deadlines, local reminders, Markdown, and local storage.',
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
      eyebrow: 'Floating todos, quick notes & deadlines · Local-first · Open source',
      titleBefore: 'Capture fast.',
      titleAccent: 'Finish with focus.',
      body:
        'Floatick stays on your Mac as a small, draggable icon. Capture a todo or note, mark the task you are doing, add a deadline, and let a quiet in-app reminder bring it back at the right moment.',
      download: 'Download for macOS',
      github: 'Explore on GitHub',
      compatibility: 'macOS 10.15+ · Apple silicon and Intel',
    },
    proof: [
      { value: 'One click', label: 'Capture without changing context' },
      { value: '3 states', label: 'Todo → Doing → Done' },
      { value: 'On time', label: 'Deadlines and in-app reminders' },
      { value: 'Local-first', label: 'Your workspace stays on your Mac' },
    ],
    features: {
      eyebrow: 'Core features',
      title: 'Tasks and notes, close to the desktop.',
      body:
        'Capture, focus, and finish without keeping a full-size productivity app open.',
      items: [
        {
          number: '01',
          title: 'A draggable desktop icon',
          body:
            'Place Floatick anywhere. It opens toward available screen space and collapses back to the same spot.',
        },
        {
          number: '02',
          title: 'A visible Doing state',
          body:
            'Move one task into Doing, give it a calm visual emphasis, and filter the list down to active work.',
        },
        {
          number: '03',
          title: 'Deadlines without notification noise',
          body:
            'Set a due date and reminder from creation or the list. Floatick surfaces a compact in-app alert when it matters.',
        },
        {
          number: '04',
          title: 'A lightweight Notes space',
          body:
            'Capture ideas, logs, and snippets with date grouping, search, pinning, autosave, and Markdown preview.',
        },
        {
          number: '05',
          title: 'Shared tags and fast retrieval',
          body:
            'Reuse colored tags across todos and notes, combine filters, archive finished work, and restore it later.',
        },
        {
          number: '06',
          title: 'Useful macOS controls',
          body:
            'Start at login, stay above other apps, choose a theme, and control whether outside clicks collapse the panel.',
        },
      ],
    },
    workflow: {
      eyebrow: 'From capture to action',
      title: 'A small, explicit path from idea to done.',
      body:
        'Floatick keeps status and timing visible without turning a lightweight list into project management software.',
      steps: [
        {
          label: 'Capture',
          title: 'Capture a todo or quick note from the desktop.',
          body:
            'Open Floatick, choose the right space, add a title, and get back to what you were doing.',
        },
        {
          label: 'Focus',
          title: 'Mark what you are doing and set the time.',
          body:
            'Use Doing to spotlight active work, then add a deadline or reminder only when the task needs one.',
        },
        {
          label: 'Finish',
          title: 'Complete it with one check.',
          body:
            'Check the task off, archive it when you are ready, or copy the full context as Markdown.',
        },
      ],
    },
    agent: {
      eyebrow: 'One-click Markdown',
      title: 'Copy the whole todo.',
      body:
        'Copy the title and notes together, ready to paste into a document, message, or AI agent.',
      sourceLabel: 'Todo',
      sourceTitle: 'Prepare tomorrow’s project brief',
      sourceContent:
        'Summarize the goal, the open questions, and the first action to take.',
      sourceTags: ['planning', 'tomorrow'],
      resultLabel: 'Copied as Markdown',
      copied:
        '# Prepare tomorrow’s project brief\n\nSummarize the goal, the open questions, and the first action to take.',
    },
    privacy: {
      eyebrow: 'Local-first',
      title: 'Stored on your Mac.',
      body:
        'Floatick saves todos, notes, and settings as readable files in ~/.floatick. No account is required.',
      points: [
        'Your todo and note data stays in a folder you can inspect and back up.',
        'No sign-up, cloud workspace, or telemetry.',
        'Floatick connects to the network only to check for app updates.',
      ],
      pathLabel: 'Working directory',
    },
    updates: {
      eyebrow: 'Changelog',
      title: 'See what changed.',
      body:
        'Each release lists its new features, fixes, and behavior changes.',
      latestLabel: 'Latest release',
      version: 'v0.3.3',
      date: 'August 5, 2026',
      dateTime: '2026-08-05',
      highlights: [
        'Capture lightweight notes beside your todos without leaving the floating panel.',
        'Search, pin, archive, and organize notes with the same reusable tags.',
        'Write titles and Markdown content in one continuous editor.',
      ],
      viewAll: 'Read the full changelog',
    },
    community: {
      eyebrow: 'Open source',
      title: 'Built in public.',
      body:
        'Floatick is MIT-licensed. Use it for free, report problems, or help improve the app.',
      points: [
        'Report a reproducible bug.',
        'Suggest a feature or workflow.',
        'Contribute code, tests, documentation, translations, or design.',
      ],
      contribute: 'Contribute on GitHub',
      suggest: 'Suggest a feature',
    },
    faq: {
      eyebrow: 'FAQ',
      title: 'Before you install.',
      body:
        'Quick answers about deadlines, notes, storage, compatibility, and Markdown copy.',
      items: [
        {
          question: 'What is Floatick?',
          answer:
            'Floatick is a free, open-source floating todo and notes app for macOS. It stays on the desktop as a draggable icon and expands when clicked.',
        },
        {
          question: 'Where does Floatick store my data?',
          answer:
            'Floatick stores todos, notes, and preferences as readable files in ~/.floatick on your Mac. It does not require an account or cloud workspace.',
        },
        {
          question: 'Can I use Floatick for quick notes?',
          answer:
            'Yes. Notes have their own searchable workspace with pinning, archiving, shared tags, automatic saving, and Markdown preview.',
        },
        {
          question: 'How do deadline reminders work?',
          answer:
            'Set a deadline while creating or editing a todo, or directly from the list. Floatick shows a compact in-app reminder and keeps overdue work visible; it does not require macOS system notifications.',
        },
        {
          question: 'Does Floatick support Apple silicon and Intel Macs?',
          answer:
            'Yes. The universal build supports Apple silicon and Intel Macs running macOS 10.15 or later.',
        },
        {
          question: 'Can I copy a todo as Markdown?',
          answer:
            'Yes. Floatick copies the title and notes together, ready to paste into a document or message.',
        },
      ],
    },
    finalCta: {
      eyebrow: 'For macOS',
      title: 'Keep tasks and thoughts on the desktop.',
      body:
        'Capture quickly, focus on what is active, and finish on time with a local-first Universal macOS app.',
      download: 'Download Floatick',
      github: 'View source',
    },
    footer: {
      tagline: 'Local-first floating todos and notes for macOS.',
      source: 'Source',
      releases: 'Releases',
      license: 'MIT License',
      language: '简体中文',
    },
  },
  zh: {
    meta: {
      lang: 'zh-CN',
      title: 'Floatick — 免费开源的 macOS 悬浮 Todo 与笔记',
      description:
        '免费开源的 macOS 桌面悬浮 Todo 与轻量笔记，支持 Doing 状态、截止时间、本地提醒、Markdown 和本地存储。',
      canonicalPath: '/zh/',
      alternatePath: '/',
    },
    nav: {
      features: '功能',
      workflow: '工作流',
      privacy: '隐私',
      changelog: '更新日志',
      download: '下载',
      languageLabel: 'Read in English',
    },
    hero: {
      eyebrow: 'macOS 悬浮 Todo、Quick Notes 与 DDL · 本地优先 · 开源',
      titleBefore: '随手记下，',
      titleAccent: '专注完成。',
      body:
        'Floatick 平时是桌面上的可拖动图标。记录 Todo 或笔记、标记正在做的任务、设置 DDL；到时间后，用克制的应用内提醒把它带回视线。',
      download: '下载 macOS 版',
      github: '在 GitHub 查看',
      compatibility: '支持 macOS 10.15+ · Apple 芯片与 Intel',
    },
    proof: [
      { value: '一步记录', label: '不必切换当前工作环境' },
      { value: '3 个状态', label: 'Todo → Doing → Done' },
      { value: '按时提醒', label: 'DDL 与应用内提醒' },
      { value: '本地优先', label: '工作空间留在这台 Mac' },
    ],
    features: {
      eyebrow: '核心功能',
      title: 'Todo 和笔记，就在桌面旁边。',
      body:
        '无需常驻一个完整的效率工具，也能完成记录、专注与按时收尾。',
      items: [
        {
          number: '01',
          title: '可拖动的桌面图标',
          body:
            '把 Floatick 放在任意位置。它会朝有空间的方向展开，收起后回到原位。',
        },
        {
          number: '02',
          title: '清晰的 Doing 状态',
          body:
            '把正在推进的任务标记为 Doing，用克制的视觉强调它，也可以只筛选进行中的任务。',
        },
        {
          number: '03',
          title: '不打扰的 DDL 与提醒',
          body:
            '新建、编辑或直接在列表中设置截止时间；到点后显示紧凑的应用内提醒。',
        },
        {
          number: '04',
          title: '轻量的 Notes 空间',
          body:
            '随手记录灵感、工作日志和片段，支持按日期分组、搜索、置顶、自动保存与 Markdown 预览。',
        },
        {
          number: '05',
          title: '共享标签与快速找回',
          body:
            'Todo 与笔记复用彩色标签，支持组合筛选、归档与恢复。',
        },
        {
          number: '06',
          title: '实用的 macOS 设置',
          body:
            '支持登录时启动、置顶、主题切换，以及点击窗口外时是否自动收起。',
        },
      ],
    },
    workflow: {
      eyebrow: '从记录到执行',
      title: '从想法到完成，路径小而明确。',
      body:
        '状态和时间始终清晰可见，但 Floatick 不会因此变成一套沉重的项目管理工具。',
      steps: [
        {
          label: '记录',
          title: '直接从桌面新建 Todo 或笔记。',
          body:
            '展开 Floatick、选择合适的空间、写下标题，然后继续手上的工作。',
        },
        {
          label: '专注',
          title: '标记正在做的任务和时间。',
          body:
            '用 Doing 聚焦当前任务；只有确实需要时，再补充 DDL 或提醒。',
        },
        {
          label: '完成',
          title: '勾选一下，结束任务。',
          body:
            '完成后勾选，准备好时再归档；需要交接时也可以复制完整 Markdown。',
        },
      ],
    },
    agent: {
      eyebrow: '一键复制 Markdown',
      title: '完整复制一个 Todo。',
      body:
        '标题和内容会一起复制，可以直接粘贴到文档、聊天或 AI Agent。',
      sourceLabel: 'Todo',
      sourceTitle: '准备明天的项目简报',
      sourceContent: '整理目标、待确认的问题，以及下一步要做的第一件事。',
      sourceTags: ['计划', '明天'],
      resultLabel: '已复制为 Markdown',
      copied:
        '# 准备明天的项目简报\n\n整理目标、待确认的问题，以及下一步要做的第一件事。',
    },
    privacy: {
      eyebrow: '本地优先',
      title: '数据保存在这台 Mac。',
      body:
        'Floatick 将 Todo、笔记和设置保存为 ~/.floatick 中的可读文件，无需账号。',
      points: [
        'Todo 和笔记数据可以直接查看和备份。',
        '无需注册、云工作区或遥测。',
        'Floatick 只在检查应用更新时访问网络。',
      ],
      pathLabel: '工作目录',
    },
    updates: {
      eyebrow: '更新日志',
      title: '看看这次改了什么。',
      body:
        '每个版本都会列出新增功能、问题修复和行为变化。',
      latestLabel: '最新版本',
      version: 'v0.3.3',
      date: '2026 年 8 月 5 日',
      dateTime: '2026-08-05',
      highlights: [
        '在悬浮面板中新增独立的轻量笔记空间，与 Todo 随时切换。',
        '支持搜索、置顶、归档笔记，并复用同一套彩色标签。',
        '标题与 Markdown 内容采用连贯的一体式编辑体验。',
      ],
      viewAll: '查看完整更新日志',
    },
    community: {
      eyebrow: '开放源代码',
      title: '在 GitHub 一起完善。',
      body:
        'Floatick 采用 MIT 许可证。你可以免费使用、反馈问题或参与开发。',
      points: [
        '反馈可以复现的问题。',
        '提出功能或工作流建议。',
        '贡献代码、测试、文档、翻译或设计。',
      ],
      contribute: '前往 GitHub 贡献',
      suggest: '提出功能建议',
    },
    faq: {
      eyebrow: '常见问题',
      title: '安装前，你可能想知道这些。',
      body:
        '快速了解 DDL、笔记、数据存储、系统兼容性和 Markdown 复制。',
      items: [
        {
          question: 'Floatick 是什么？',
          answer:
            'Floatick 是一款免费开源的 macOS 悬浮 Todo 与笔记应用。它平时是桌面上的可拖动图标，点击后展开。',
        },
        {
          question: 'Todo 和笔记数据保存在哪里？',
          answer:
            'Todo、笔记和偏好设置以可读文件保存在这台 Mac 的 ~/.floatick 中，无需账号或云工作区。',
        },
        {
          question: '可以用 Floatick 随手记笔记吗？',
          answer:
            '可以。Notes 有独立的可搜索空间，支持置顶、归档、共享标签、自动保存和 Markdown 预览。',
        },
        {
          question: 'DDL 到时间后如何提醒？',
          answer:
            '新建或编辑 Todo 时可以设置 DDL，也可以直接从首页列表设置。到时间后 Floatick 会显示紧凑的应用内提醒，并持续标记逾期任务；不依赖 macOS 系统通知。',
        },
        {
          question: '支持 Apple 芯片和 Intel Mac 吗？',
          answer:
            '支持。Universal 安装包兼容 macOS 10.15 或更高版本的 Apple 芯片与 Intel Mac。',
        },
        {
          question: '可以把 Todo 复制为 Markdown 吗？',
          answer:
            '可以。Floatick 会一起复制标题和内容，可以直接粘贴到文档或聊天。',
        },
      ],
    },
    finalCta: {
      eyebrow: 'macOS',
      title: '把待办和灵感放在桌面旁边。',
      body:
        '随手记录、聚焦进行中的任务，并在截止时间前完成。下载本地优先的 Universal macOS 应用。',
      download: '下载 Floatick',
      github: '查看源代码',
    },
    footer: {
      tagline: '本地优先的 macOS 悬浮 Todo 与笔记。',
      source: '源代码',
      releases: '版本发布',
      license: 'MIT 许可证',
      language: 'English',
    },
  },
};
