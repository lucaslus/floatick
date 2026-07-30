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
      title: 'Floatick — Free Floating Todo List for macOS',
      description:
        'A free, open-source floating todo list for macOS with local storage, Markdown notes, tags, Sticky Boards, and fast desktop capture.',
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
      eyebrow: 'Floating todo list for macOS · Local-first · Open source',
      titleBefore: 'Your next task,',
      titleAccent: 'always one click away.',
      body:
        'Floatick lives on your Mac as a small, draggable icon. Click to capture a todo, add notes or tags, then collapse it back to the desktop.',
      download: 'Download for macOS',
      github: 'Explore on GitHub',
      compatibility: 'macOS 10.15+ · Apple silicon and Intel',
    },
    proof: [
      { value: 'Free', label: 'No account or subscription' },
      { value: 'Open source', label: 'MIT-licensed on GitHub' },
      { value: 'Local-first', label: 'Todos stay on your Mac' },
      { value: 'Maintained', label: 'New releases and fixes' },
    ],
    features: {
      eyebrow: 'Core features',
      title: 'Everything you need, close to the desktop.',
      body:
        'Capture, organize, and revisit todos without keeping a full-size task manager open.',
      items: [
        {
          number: '01',
          title: 'A draggable desktop icon',
          body:
            'Place Floatick anywhere. It opens toward available screen space and collapses back to the same spot.',
        },
        {
          number: '02',
          title: 'Titles and Markdown notes',
          body:
            'Keep the list short with titles, then open Markdown details when a task needs more context.',
        },
        {
          number: '03',
          title: 'Tags and combined filters',
          body:
            'Create colored tags, assign more than one, and filter the list by several tags at once.',
        },
        {
          number: '04',
          title: 'Pinnable Sticky Boards',
          body:
            'Group existing todos on a colored board and pin it to the desktop. A board never owns or deletes its todos.',
        },
        {
          number: '05',
          title: 'Archive and restore',
          body:
            'Move finished work out of the main list, search the archive, and restore a todo when you need it again.',
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
      title: 'Start with a title. Add context when you need it.',
      body:
        'A todo can stay one line or grow into a complete Markdown brief.',
      steps: [
        {
          label: 'Capture',
          title: 'Create a todo from the desktop.',
          body:
            'Open Floatick, add a title, and get back to what you were doing.',
        },
        {
          label: 'Organize',
          title: 'Use tags and Sticky Boards.',
          body:
            'Group related work without moving or duplicating the original todo.',
        },
        {
          label: 'Share',
          title: 'Copy the whole task as Markdown.',
          body:
            'Send the title and notes to a document, teammate, or chat in one paste.',
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
        'Floatick saves todos and settings as readable files in ~/.floatick. No account is required.',
      points: [
        'Your todo data stays in a folder you can inspect and back up.',
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
      version: 'v0.3.0',
      date: 'July 29, 2026',
      highlights: [
        'Copy a todo title and notes together as Markdown.',
        'Use consistent bottom-sheet actions across the app.',
        'Scroll smoothly through larger local lists.',
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
        'Quick answers about storage, compatibility, Sticky Boards, and Markdown copy.',
      items: [
        {
          question: 'What is Floatick?',
          answer:
            'Floatick is a free, open-source floating todo list for macOS. It stays on the desktop as a draggable icon and expands into a task list when clicked.',
        },
        {
          question: 'Where does Floatick store my todos?',
          answer:
            'Floatick stores todos and preferences as readable files in ~/.floatick on your Mac. It does not require an account or cloud workspace.',
        },
        {
          question: 'What is a Sticky Board?',
          answer:
            'A Sticky Board is a colored desktop group for existing todos. You can pin it to the desktop, and deleting the board never deletes its todos.',
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
      title: 'Keep your next todo on the desktop.',
      body:
        'Download the latest universal build, or view the source on GitHub.',
      download: 'Download Floatick',
      github: 'View source',
    },
    footer: {
      tagline: 'A local-first floating todo list for macOS.',
      source: 'Source',
      releases: 'Releases',
      license: 'MIT License',
      language: '简体中文',
    },
  },
  zh: {
    meta: {
      lang: 'zh-CN',
      title: 'Floatick — 免费开源的 macOS 悬浮 Todo 清单',
      description:
        '免费开源的 macOS 桌面悬浮待办清单，支持本地存储、Markdown、标签、便利板和快速记录。',
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
      eyebrow: 'macOS 悬浮待办清单 · 本地优先 · 开源',
      titleBefore: '下一件事，',
      titleAccent: '点一下就到。',
      body:
        'Floatick 平时是桌面上的一个可拖动图标。点击记录 Todo、补充内容或标签，用完后再收回原位。',
      download: '下载 macOS 版',
      github: '在 GitHub 查看',
      compatibility: '支持 macOS 10.15+ · Apple 芯片与 Intel',
    },
    proof: [
      { value: '免费', label: '无需账号或订阅' },
      { value: '开源', label: 'GitHub 上的 MIT 项目' },
      { value: '本地优先', label: 'Todo 保存在这台 Mac' },
      { value: '持续维护', label: '持续发布功能与修复' },
    ],
    features: {
      eyebrow: '核心功能',
      title: '常用的 Todo 操作，就在桌面旁边。',
      body:
        '无需常驻一个完整的任务管理器，也能随时记录、整理和找回 Todo。',
      items: [
        {
          number: '01',
          title: '可拖动的桌面图标',
          body:
            '把 Floatick 放在任意位置。它会朝有空间的方向展开，收起后回到原位。',
        },
        {
          number: '02',
          title: '标题与 Markdown 内容',
          body:
            '列表只展示标题，需要更多上下文时再打开 Markdown 详情。',
        },
        {
          number: '03',
          title: '标签与组合筛选',
          body:
            '创建彩色标签，为一个 Todo 添加多个标签，并同时按多个标签筛选。',
        },
        {
          number: '04',
          title: '可固定的便利板',
          body:
            '把已有 Todo 放进彩色便利板并固定在桌面。删除便利板不会删除 Todo。',
        },
        {
          number: '05',
          title: '归档与恢复',
          body:
            '把完成的工作移出主列表，继续搜索归档，并在需要时恢复。',
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
      title: '先写标题，需要时再补充上下文。',
      body:
        '一个 Todo 可以只有一行，也可以逐步整理成完整的 Markdown 任务。',
      steps: [
        {
          label: '记录',
          title: '直接从桌面新建 Todo。',
          body:
            '展开 Floatick、写下标题，然后继续手上的工作。',
        },
        {
          label: '组织',
          title: '使用标签和便利板。',
          body:
            '把相关工作放在一起，不移动或复制原来的 Todo。',
        },
        {
          label: '复制',
          title: '把整个任务复制为 Markdown。',
          body:
            '一次复制标题和内容，直接粘贴到文档、聊天或发给同事。',
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
        'Floatick 将 Todo 和设置保存为 ~/.floatick 中的可读文件，无需账号。',
      points: [
        'Todo 数据可以直接查看和备份。',
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
      version: 'v0.3.0',
      date: '2026 年 7 月 29 日',
      highlights: [
        '把 Todo 标题和内容一起复制为 Markdown。',
        '统一应用内的底部抽屉操作方式。',
        '优化大量 Todo 下的列表滚动。',
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
        '快速了解数据存储、系统兼容性、便利板和 Markdown 复制。',
      items: [
        {
          question: 'Floatick 是什么？',
          answer:
            'Floatick 是一款免费开源的 macOS 悬浮 Todo 清单。它平时是桌面上的可拖动图标，点击后展开为任务列表。',
        },
        {
          question: 'Todo 数据保存在哪里？',
          answer:
            'Todo 和偏好设置以可读文件保存在这台 Mac 的 ~/.floatick 中，无需账号或云工作区。',
        },
        {
          question: '便利板是什么？',
          answer:
            '便利板是已有 Todo 的彩色桌面分组，可以固定在桌面。删除便利板不会删除其中的 Todo。',
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
      title: '把下一件事放在桌面旁边。',
      body:
        '下载最新 Universal 安装包，或前往 GitHub 查看源代码。',
      download: '下载 Floatick',
      github: '查看源代码',
    },
    footer: {
      tagline: '本地优先的 macOS 悬浮待办清单。',
      source: '源代码',
      releases: '版本发布',
      license: 'MIT 许可证',
      language: 'English',
    },
  },
};
