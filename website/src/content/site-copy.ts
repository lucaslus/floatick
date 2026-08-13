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
      version: 'v0.3.4',
      date: 'August 13, 2026',
      dateTime: '2026-08-13',
      highlights: [
        'Move tasks through Todo, Doing, and Done, and filter the list to active work.',
        'Set deadlines and advance reminders from the editor or directly from the list.',
        'Receive compact native in-app alerts while overdue work stays visible.',
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
      title: 'Floatick — 放在桌面上的 macOS 待办和随手记',
      description:
        'Floatick 是一款免费开源的 macOS 小工具。点开就能记待办和笔记，也能标记进行中任务、设置截止时间和提醒；所有数据都保存在本机。',
      canonicalPath: '/zh/',
      alternatePath: '/',
    },
    nav: {
      features: '功能',
      workflow: '怎么用',
      privacy: '数据与隐私',
      changelog: '更新日志',
      download: '下载',
      languageLabel: 'Read in English',
    },
    hero: {
      eyebrow: 'macOS 桌面待办与随手记 · 数据存在本机 · 免费开源',
      titleBefore: '随手记下来，',
      titleAccent: '专心做完它。',
      body:
        'Floatick 平时收在桌面上的一个小图标里。点开就能记待办、写笔记，正在做的事可以标成“进行中”，需要时再加上截止时间和提醒。',
      download: '下载 macOS 版',
      github: '在 GitHub 查看',
      compatibility: '支持 macOS 10.15 及以上版本 · Apple 芯片和 Intel 都能用',
    },
    proof: [
      { value: '点开就记', label: '不用来回切换应用' },
      { value: '状态简单', label: '待办、进行中、已完成' },
      { value: '到点提醒', label: '截止时间和应用内提醒' },
      { value: '只存本机', label: '不用注册，也不会上传数据' },
    ],
    features: {
      eyebrow: '主要功能',
      title: '待办和笔记，就放在桌面手边。',
      body:
        '不用一直开着一个大而全的效率软件。想到什么就记下来，做完再勾掉。',
      items: [
        {
          number: '01',
          title: '拖到顺手的位置',
          body:
            '小图标可以放在桌面任意位置。点开时会自动朝有空间的方向展开，收起后还在原来的地方。',
        },
        {
          number: '02',
          title: '一眼看到正在做什么',
          body:
            '把当前任务标成“进行中”，它会更醒目。也可以只看正在做的任务，不被其他待办打扰。',
        },
        {
          number: '03',
          title: '需要时再设截止时间',
          body:
            '新建或编辑待办时可以设置截止时间，也能直接在列表里修改。到点后，Floatick 会在应用内提醒你。',
        },
        {
          number: '04',
          title: '随手记点东西',
          body:
            '灵感、工作记录、临时片段都可以放进笔记。支持按日期整理、搜索、置顶、自动保存和 Markdown 预览。',
        },
        {
          number: '05',
          title: '用标签整理待办和笔记',
          body:
            '待办和笔记可以共用同一套彩色标签，也能组合筛选。用完的内容可以归档，需要时再找回来。',
        },
        {
          number: '06',
          title: '常用的 macOS 设置都有',
          body:
            '可以设置开机启动、窗口置顶、明暗主题，以及点到窗口外时要不要自动收起。',
        },
      ],
    },
    workflow: {
      eyebrow: '用起来很简单',
      title: '记下来，开始做，做完勾掉。',
      body:
        'Floatick 只保留真正用得上的状态和提醒，不会把简单的待办变成复杂的项目管理。',
      steps: [
        {
          label: '记下来',
          title: '想到什么，点开就记。',
          body:
            '选择待办或笔记，写个标题，就可以继续忙手上的事。',
        },
        {
          label: '开始做',
          title: '把手头这件事标成“进行中”。',
          body:
            '需要卡时间时，再加上截止时间或提前提醒。',
        },
        {
          label: '做完了',
          title: '勾一下，就完成了。',
          body:
            '做完可以直接归档；需要发给别人时，也能把标题和内容一起复制成 Markdown。',
        },
      ],
    },
    agent: {
      eyebrow: '一键复制',
      title: '把待办完整复制出去。',
      body:
        '标题和正文会一起复制成 Markdown，可以粘贴到文档、聊天窗口或其他工具里。',
      sourceLabel: '待办',
      sourceTitle: '准备明天的项目简报',
      sourceContent: '整理目标、待确认的问题，以及下一步要做的第一件事。',
      sourceTags: ['计划', '明天'],
      resultLabel: '已复制为 Markdown',
      copied:
        '# 准备明天的项目简报\n\n整理目标、待确认的问题，以及下一步要做的第一件事。',
    },
    privacy: {
      eyebrow: '数据只存在本机',
      title: '不用注册，也不会上传。',
      body:
        '待办、笔记和设置都保存在这台 Mac 的 ~/.floatick 文件夹里。',
      points: [
        '文件就在本机，随时可以查看和备份。',
        '不用账号，也没有云端工作区。',
        '除了检查新版本，Floatick 不会主动联网。',
      ],
      pathLabel: '保存位置',
    },
    updates: {
      eyebrow: '更新日志',
      title: '每个版本改了什么，都写清楚。',
      body:
        '新增功能、问题修复和使用上的变化，都会记录在这里。',
      latestLabel: '最新版本',
      version: 'v0.3.4',
      date: '2026 年 8 月 13 日',
      dateTime: '2026-08-13',
      highlights: [
        '待办可以标成“进行中”，也能只看手头正在做的任务。',
        '可以在编辑器或列表里设置截止时间和提前提醒。',
        '到点后会在应用内提醒，逾期任务也会一直标出来。',
      ],
      viewAll: '查看完整更新日志',
    },
    community: {
      eyebrow: '免费开源',
      title: '代码在 GitHub，欢迎一起改进。',
      body:
        'Floatick 使用 MIT 许可证。你可以免费使用，也可以提交问题、建议或代码。',
      points: [
        '遇到问题，可以提交能复现的 Bug。',
        '有更顺手的用法，可以告诉我们。',
        '也欢迎贡献代码、测试、文档、翻译或设计。',
      ],
      contribute: '去 GitHub 看看',
      suggest: '提个建议',
    },
    faq: {
      eyebrow: '常见问题',
      title: '安装前，先回答几个常见问题。',
      body:
        '关于数据保存、提醒、系统支持和笔记功能，这里都有简短说明。',
      items: [
        {
          question: 'Floatick 是什么？',
          answer:
            'Floatick 是一款免费开源的 macOS 桌面小工具。它平时是一个可以拖动的小图标，点一下就会展开待办和笔记。',
        },
        {
          question: '数据保存在哪里？',
          answer:
            '待办、笔记和设置都以可读文件保存在这台 Mac 的 ~/.floatick 文件夹里，不需要账号，也不会同步到云端。',
        },
        {
          question: '可以用 Floatick 随手记笔记吗？',
          answer:
            '可以。笔记有单独的页面，支持搜索、置顶、归档、标签、自动保存和 Markdown 预览。',
        },
        {
          question: '截止时间到了会怎么提醒？',
          answer:
            '新建或编辑待办时可以设置截止时间，也能直接在列表里修改。到点后 Floatick 会弹出一个简洁的应用内提醒，并继续标出逾期任务；不需要开启 macOS 系统通知。',
        },
        {
          question: '支持 Apple 芯片和 Intel Mac 吗？',
          answer:
            '支持。安装包同时支持 Apple 芯片和 Intel Mac，系统需要 macOS 10.15 或更高版本。',
        },
        {
          question: '可以把待办复制成 Markdown 吗？',
          answer:
            '可以。标题和正文会一起复制，直接粘贴到文档或聊天里就行。',
        },
      ],
    },
    finalCta: {
      eyebrow: 'macOS',
      title: '把待办和随手记放在桌面手边。',
      body:
        '点开就记，做完就勾。Floatick 免费开源，数据只存在本机，同时支持 Apple 芯片和 Intel Mac。',
      download: '下载 Floatick',
      github: '查看源代码',
    },
    footer: {
      tagline: '放在 macOS 桌面上的待办和随手记，数据只存在本机。',
      source: '源代码',
      releases: '版本发布',
      license: 'MIT 许可证',
      language: 'English',
    },
  },
};
