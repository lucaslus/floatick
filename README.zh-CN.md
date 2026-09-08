<div align="center">
  <h1>
    <img src="./docs/assets/app-icon.png" width="36" height="36" align="absmiddle" alt="Floatick Icon" />
    Floatick
  </h1>
  <p><strong>常驻 macOS 菜单栏的轻量待办与便签</strong></p>
  <p>随手记，专心做。本地存储 · 极简轻快 · 免费开源</p>
  <p>
    <a href="https://github.com/lucaslus/floatick/actions/workflows/ci.yml">
      <img src="https://github.com/lucaslus/floatick/actions/workflows/ci.yml/badge.svg" alt="CI 状态" />
    </a>
    <img src="https://img.shields.io/badge/macOS-10.15%2B-111111?logo=apple" alt="macOS 10.15+" />
    <img src="https://img.shields.io/badge/Tauri-v2-24C8D8?logo=tauri" alt="Tauri v2" />
    <img src="https://img.shields.io/badge/Rust-1.80%2B-DEA584?logo=rust" alt="Rust 1.80+" />
    <img src="https://img.shields.io/badge/React-19-61DAFB?logo=react" alt="React 19" />
    <img src="https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript" alt="TypeScript 5.x" />
    <a href="./LICENSE">
      <img src="https://img.shields.io/badge/license-MIT-00C7B7" alt="MIT 许可证" />
    </a>
  </p>
  <p>
    <a href="./README.md">English</a> · <strong>简体中文</strong>
  </p>
</div>

<p align="center">
  <img src="./docs/assets/floatick-showcase.png" width="100%" alt="Floatick 菜单栏待办、TipTap 富文本写作与随手记便签" />
</p>

Floatick 是一款专为 macOS 设计的原生轻量效率工具。安静常驻于屏幕顶部的菜单栏中，未完成事项实时显示角标；点击图标即在手边展开浮动面板。无需复杂配置，点开即记，做完即勾，不扰专注。

## 特性亮点

- **原生常驻菜单栏**：常驻右上角状态栏，角标实时显示待办数，点击即开，不占 Dock。
- **全宽卡片与悬浮胶囊**：长标题全宽展示无遮挡；鼠标悬浮呼出截止时间、编辑、复制与删除操作胶囊。
- **浏览勾选与编辑抽屉独立**：列表专注纯粹浏览与单键勾销；双击或按 `⌘N` 唤出独立编辑抽屉。
- **TipTap 富文本与斜杠指令**：输入 `/` 快速插入交互式任务清单、多级标题、代码块与引用。
- **到点提醒与截止时间**：按需设置截止时间，临近与逾期状态清晰高亮，适度提醒不吵闹。
- **便签与彩色标签**：随时速记碎片灵感；待办与便签共享彩色标签，支持快速多维度筛选。
- **数据完全保存在本机**：无账号体系、无云端同步，数据以纯文本 JSON 格式存放在 `~/.floatick`。
- **原生轻快省电**：基于 Tauri 2 与 Rust 构建，内存占用极低（通常低于 30MB），支持开机自启与置顶。

## 下载安装

前往 [GitHub Releases](https://github.com/lucaslus/floatick/releases) 下载最新 DMG 安装包，打开后将 Floatick 拖入 `Applications` 即可。安装包为 Universal Binary，原生支持 Apple 芯片（M 系列）与 Intel 架构。

> **macOS 首次打开提示**：
> 如打开时提示“来自未受信任的开发者”，请前往 **系统设置 → 隐私与安全**，在“安全性”中点击 **仍要打开** 即可（仅需首次确认一次）。

## 应用更新

打开 **设置 → 软件更新**（`⌘,`），可手动检查新版本、查看更新说明，或开启每天自动检查。Sparkle 原生窗口负责展示下载进度、验证 Ed25519 签名，并在你确认后安装、重启；自动检查不会自动安装。

v0.4.0 和 v0.4.1 尚未内置更新组件，需要先手动安装一次 v0.4.2。检查更新需要联网，待办和便签数据仍保存在本机。更新偏好保存在 macOS 用户偏好中。

## 快捷键与常用交互

| 操作 | 快捷键 / 交互 | 说明 |
| --- | --- | --- |
| **唤出 / 收起** | 点击托盘图标 | 在托盘正下方弹出或收起面板 |
| **新建事项** | `⌘N` | 打开编辑抽屉（新建待办或便签） |
| **编辑事项** | 双击卡片 / 悬浮点击 ✏️ | 呼出 TipTap 编辑抽屉 |
| **保存退出** | `⌘ ⏎` | 保存当前内容并关闭抽屉 |
| **返回 / 收起** | `Esc` | 优先关闭抽屉，其次收起主面板 |
| **快速搜索** | `⌘F` | 聚焦搜索栏 |
| **切换标签** | `Tab` / `⌘1`, `⌘2` | 在待办与便签视图之间切换 |
| **偏好设置** | `⌘,` | 呼出设置抽屉（主题、开机自启、置顶等） |
| **斜杠排版** | 输入 `/` | 插入任务清单、标题、代码块等 |
| **设定截止时间** | 悬浮点击 ⏰ | 直接呼出时间选择器 |
| **复制 Markdown** | 悬浮点击 ⎘ | 将标题与正文一键复制为 Markdown |
| **退出应用** | 右键托盘 / 设置菜单 | 退出 Floatick |

## 本地数据与隐私

Floatick 首次启动时会在用户目录自动创建数据文件：

| 文件路径 | 内容说明 |
| --- | --- |
| `~/.floatick/todos.json` | 待办列表、完成状态、截止时间、提醒与归档 |
| `~/.floatick/notes.json` | 便签正文、彩色标签、置顶与归档 |
| `~/.floatick/tags.json` | 待办与便签共享的可复用彩色标签 |
| `~/.floatick/settings.json` | 主题外观、界面语言、开机自启与置顶偏好 |

所有数据完全保存在本机，不经过任何云端服务器，亦无任何数据遥测。

## 本地开发

### 环境要求

- macOS 10.15 或更高版本
- [Node.js](https://nodejs.org/) 18+ 与 [pnpm](https://pnpm.io/)
- [Rust](https://www.rust-lang.org/) (1.80+) 与 Cargo 环境

### 启动开发

```bash
# 1. 安装依赖
pnpm install

# 2. 启动开发模式（支持前端热重载）
pnpm tauri:dev
```

Tauri 命令会自动下载固定版本且经过 SHA-256 校验的 Sparkle 框架。直接运行 Cargo 前，请先执行一次 `pnpm setup:sparkle`。更新功能仅在打包后的 `.app` 中启用，浏览器预览及未打包的 `tauri dev` 会显示不可用提示；测试原生更新窗口请构建并启动 `.app`。

### 生产打包

```bash
# 构建 Universal Binary DMG 与 .app
pnpm tauri:build
```

产物生成于 `src-tauri/target/release/bundle/macos/` 与 `dmg/` 目录下。

## 项目结构

```text
src/                          # 前端界面 (React 19 + TypeScript + Vite + Tailwind CSS)
  components/
    common/                   # TipTap 富文本编辑器、搜索栏、通用组件
    layout/                   # 顶栏 Header、切换器 ContentSwitcher、主浮窗容器
    notes/                    # 便签列表、便签卡片、便签编辑抽屉
    settings/                 # 偏好设置抽屉 (主题、语言、自启、置顶)
    tags/                     # 标签管理与筛选
    todos/                    # 待办列表、事项卡片、截止时间选择器、待办编辑抽屉
  stores/                     # Zustand 全局状态流
  i18n/                       # 多语言资源 (zh / en)
  lib/                        # Tauri IPC 调用封装
src-tauri/                    # 原生后端 (Rust + Tauri 2.x)
  src/
    tray.rs                   # macOS 菜单栏托盘与窗口磁吸定位
    storage.rs                # 本地 JSON 原子持久化存储
    commands.rs               # 暴露给前端调用的 Tauri Command
    lib.rs                    # 窗口生命周期与失焦自动收起
website/                      # 官网工程 (Astro)
docs/                         # 设计规范与架构文档
```

## 开源协议

Floatick 基于 [MIT License](./LICENSE) 开源。
