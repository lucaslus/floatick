import React, { useEffect, useState, useRef, useMemo } from "react";
import { useEditor, EditorContent, Editor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import TaskList from "@tiptap/extension-task-list";
import TaskItem from "@tiptap/extension-task-item";
import { Markdown } from "tiptap-markdown";
import {
  TextHOne,
  TextHTwo,
  TextHThree,
  TextB,
  TextItalic,
  TextStrikethrough,
  Code as InlineCodeIcon,
  ListChecks,
  ListBullets,
  ListNumbers,
  Quotes,
  CodeBlock as CodeBlockIconPh,
  Minus,
  ArrowUUpLeft,
  ArrowUUpRight,
  DotsThree,
  Eraser,
} from "@phosphor-icons/react";

// Refined, minimalist, pixel-crisp SVG icons for Slash Menu
const TaskIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <rect x="3" y="3" width="18" height="18" rx="4" />
    <path d="m9 12 2 2 4-4" />
  </svg>
);

const BulletListIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="4" cy="7" r="1.25" fill="currentColor" />
    <path d="M9 7h12" />
    <circle cx="4" cy="12" r="1.25" fill="currentColor" />
    <path d="M9 12h12" />
    <circle cx="4" cy="17" r="1.25" fill="currentColor" />
    <path d="M9 17h12" />
  </svg>
);

const NumberedListIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M3 8h2M4 5v3" />
    <path d="M10 7h11" />
    <path d="M3 13.5a1.5 1.5 0 0 1 2.5-1.1c.6.5.6 1.4 0 2l-2.5 2.6h3" />
    <path d="M10 14h11" />
    <path d="M10 19h7" />
  </svg>
);

const HeadingOneIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M4 6v12M12 6v12M4 12h8" />
    <path d="m16.5 9 2.5-2v11" />
  </svg>
);

const HeadingTwoIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M4 6v12M12 6v12M4 12h8" />
    <path d="M16 10a2.5 2.5 0 0 1 4.5 1.5c0 1.8-2 3.5-4.5 5.5H21" />
  </svg>
);

const BlockquoteIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M4 4v16" strokeWidth="2.5" />
    <path d="M9 7h11M9 12h8M9 17h10" />
  </svg>
);

const CodeBlockIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="m7 8-4 4 4 4" />
    <path d="m17 8 4 4-4 4" />
    <path d="m14 4-4 16" />
  </svg>
);

const DividerIcon: React.FC<{ className?: string }> = ({ className = "w-4 h-4" }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.75"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <line x1="3" y1="12" x2="21" y2="12" />
    <line x1="3" y1="9" x2="3" y2="15" />
    <line x1="21" y1="9" x2="21" y2="15" />
  </svg>
);

interface SlashCommandItem {
  id: string;
  label: string;
  desc: string;
  shortcut: string;
  icon: React.FC<{ className?: string }>;
  action: (editor: Editor) => void;
}

const SLASH_COMMANDS: SlashCommandItem[] = [
  {
    id: "task",
    label: "任务清单",
    desc: "交互式待办复选框",
    shortcut: "/task",
    icon: TaskIcon,
    action: (editor) => editor.chain().focus().toggleTaskList().run(),
  },
  {
    id: "bullet",
    label: "无序列表",
    desc: "圆点项目列表",
    shortcut: "/bullet",
    icon: BulletListIcon,
    action: (editor) => editor.chain().focus().toggleBulletList().run(),
  },
  {
    id: "ordered",
    label: "有序列表",
    desc: "数字编号列表",
    shortcut: "/number",
    icon: NumberedListIcon,
    action: (editor) => editor.chain().focus().toggleOrderedList().run(),
  },
  {
    id: "h1",
    label: "大标题",
    desc: "一级主标题",
    shortcut: "/h1",
    icon: HeadingOneIcon,
    action: (editor) => editor.chain().focus().toggleHeading({ level: 1 }).run(),
  },
  {
    id: "h2",
    label: "中标题",
    desc: "二级分段标题",
    shortcut: "/h2",
    icon: HeadingTwoIcon,
    action: (editor) => editor.chain().focus().toggleHeading({ level: 2 }).run(),
  },
  {
    id: "quote",
    label: "引用段落",
    desc: "强调重点引文",
    shortcut: "/quote",
    icon: BlockquoteIcon,
    action: (editor) => editor.chain().focus().toggleBlockquote().run(),
  },
  {
    id: "code",
    label: "代码块",
    desc: "等宽排版代码块",
    shortcut: "/code",
    icon: CodeBlockIcon,
    action: (editor) => editor.chain().focus().toggleCodeBlock().run(),
  },
  {
    id: "divider",
    label: "分割线",
    desc: "水平内容分割线",
    shortcut: "/divider",
    icon: DividerIcon,
    action: (editor) => editor.chain().focus().setHorizontalRule().run(),
  },
];

interface ToolbarButtonProps {
  onClick: () => void;
  isActive?: boolean;
  disabled?: boolean;
  label: string;
  shortcut?: string;
  suppressTooltip?: boolean;
  children: React.ReactNode;
}

const ToolbarButton: React.FC<ToolbarButtonProps> = ({
  onClick,
  isActive = false,
  disabled = false,
  label,
  shortcut,
  suppressTooltip = false,
  children,
}) => {
  const [isHovered, setIsHovered] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const handleMouseEnter = () => {
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      setIsHovered(true);
    }, 180);
  };

  const handleMouseLeave = () => {
    if (timerRef.current) clearTimeout(timerRef.current);
    setIsHovered(false);
  };

  return (
    <div
      className="relative flex items-center justify-center"
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      <button
        type="button"
        aria-label={label}
        disabled={disabled}
        onMouseDown={(e) => {
          e.preventDefault(); // Retain editor focus and selection
        }}
        onClick={() => {
          setIsHovered(false);
          if (timerRef.current) clearTimeout(timerRef.current);
          onClick();
        }}
        className={`w-6 h-6 rounded flex items-center justify-center transition-colors cursor-pointer shrink-0 tactile-btn ${
          disabled
            ? "opacity-25 cursor-not-allowed"
            : isActive
            ? "bg-[var(--color-teal-tint)] text-[var(--color-teal-primary)] font-semibold"
            : "text-[var(--color-text-subtle)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
        }`}
      >
        {children}
      </button>

      {/* Exquisite macOS / Raycast Floating Micro-Tooltip */}
      {isHovered && !disabled && !suppressTooltip && (
        <div className="absolute top-full left-1/2 -translate-x-1/2 mt-1.5 z-50 pointer-events-none flex items-center space-x-1 px-1.5 py-0.5 rounded-md bg-[#18181B] dark:bg-[#27272A] text-[#FAFAFA] text-[10.5px] leading-tight whitespace-nowrap shadow-xl border border-white/10 dark:border-white/15 animate-in fade-in zoom-in-95 duration-75">
          <span>{label}</span>
          {shortcut && (
            <span className="font-mono text-[9px] text-[#A1A1AA] ml-0.5 tracking-tight">
              {shortcut}
            </span>
          )}
        </div>
      )}
    </div>
  );
};

const ToolbarDivider: React.FC = () => (
  <div className="w-[1px] h-3.5 mx-1 bg-[var(--color-border-panel)] shrink-0 opacity-70" />
);

export const EditorToolbar: React.FC<{ editor: Editor | null }> = ({ editor }) => {
  const [showMoreMenu, setShowMoreMenu] = useState(false);

  if (!editor) return null;

  const isMoreActive =
    editor.isActive("blockquote") ||
    editor.isActive("codeBlock") ||
    editor.isActive("heading", { level: 3 });

  return (
    <div className="relative flex items-center justify-between pb-2 mb-2 border-b border-[var(--color-border-panel)]/60 shrink-0 select-none">
      {/* Primary Formatting Tools */}
      <div className="flex items-center space-x-0.5 py-0.5">
        {/* Headings */}
        <ToolbarButton
          label="一级标题"
          shortcut="H1"
          isActive={editor.isActive("heading", { level: 1 })}
          onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}
        >
          <TextHOne size={14} weight={editor.isActive("heading", { level: 1 }) ? "bold" : "regular"} />
        </ToolbarButton>
        <ToolbarButton
          label="二级标题"
          shortcut="H2"
          isActive={editor.isActive("heading", { level: 2 })}
          onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
        >
          <TextHTwo size={14} weight={editor.isActive("heading", { level: 2 }) ? "bold" : "regular"} />
        </ToolbarButton>

        <ToolbarDivider />

        {/* Inline styles */}
        <ToolbarButton
          label="加粗"
          shortcut="⌘B"
          isActive={editor.isActive("bold")}
          onClick={() => editor.chain().focus().toggleBold().run()}
        >
          <TextB size={14} weight={editor.isActive("bold") ? "bold" : "regular"} />
        </ToolbarButton>
        <ToolbarButton
          label="斜体"
          shortcut="⌘I"
          isActive={editor.isActive("italic")}
          onClick={() => editor.chain().focus().toggleItalic().run()}
        >
          <TextItalic size={14} weight={editor.isActive("italic") ? "bold" : "regular"} />
        </ToolbarButton>
        <ToolbarButton
          label="删除线"
          shortcut="⌘⇧X"
          isActive={editor.isActive("strike")}
          onClick={() => editor.chain().focus().toggleStrike().run()}
        >
          <TextStrikethrough size={14} weight={editor.isActive("strike") ? "bold" : "regular"} />
        </ToolbarButton>
        <ToolbarButton
          label="行内代码"
          shortcut="⌘E"
          isActive={editor.isActive("code")}
          onClick={() => editor.chain().focus().toggleCode().run()}
        >
          <InlineCodeIcon size={14} weight={editor.isActive("code") ? "bold" : "regular"} />
        </ToolbarButton>

        <ToolbarDivider />

        {/* Lists */}
        <ToolbarButton
          label="待办清单"
          shortcut="/task"
          isActive={editor.isActive("taskList")}
          onClick={() => editor.chain().focus().toggleTaskList().run()}
        >
          <ListChecks size={14} weight={editor.isActive("taskList") ? "bold" : "regular"} />
        </ToolbarButton>
        <ToolbarButton
          label="无序列表"
          shortcut="/bullet"
          isActive={editor.isActive("bulletList")}
          onClick={() => editor.chain().focus().toggleBulletList().run()}
        >
          <ListBullets size={14} weight={editor.isActive("bulletList") ? "bold" : "regular"} />
        </ToolbarButton>
        <ToolbarButton
          label="编号列表"
          shortcut="/number"
          isActive={editor.isActive("orderedList")}
          onClick={() => editor.chain().focus().toggleOrderedList().run()}
        >
          <ListNumbers size={14} weight={editor.isActive("orderedList") ? "bold" : "regular"} />
        </ToolbarButton>

        <ToolbarDivider />

        {/* More Tools Dropdown Trigger */}
        <div className="relative shrink-0">
          <ToolbarButton
            label="更多格式"
            suppressTooltip={showMoreMenu}
            isActive={isMoreActive || showMoreMenu}
            onClick={() => setShowMoreMenu((prev) => !prev)}
          >
            <DotsThree size={16} weight="bold" />
          </ToolbarButton>

          {/* More Menu Dropdown Popover */}
          {showMoreMenu && (
            <>
              <div
                className="fixed inset-0 z-40 bg-transparent"
                onClick={(e) => {
                  e.stopPropagation();
                  setShowMoreMenu(false);
                }}
              />
              <div
                className="absolute right-0 top-full mt-1.5 z-50 w-44 bg-[var(--color-bg-drawer)] rounded-xl shadow-2xl border border-[var(--color-border-drawer)] p-1 backdrop-blur-xl animate-in fade-in zoom-in-95 duration-100 select-none"
                onClick={(e) => e.stopPropagation()}
              >
                <div className="px-2.5 pt-1 pb-1 text-[11px] font-medium text-[var(--color-text-subtle)]">
                  更多格式
                </div>

                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => {
                    editor.chain().focus().toggleHeading({ level: 3 }).run();
                    setShowMoreMenu(false);
                  }}
                  className={`w-full px-2 py-1.5 rounded-lg flex items-center justify-between text-left transition-colors cursor-pointer ${
                    editor.isActive("heading", { level: 3 })
                      ? "bg-black/[0.05] dark:bg-white/[0.08] text-[var(--color-teal-primary)]"
                      : "text-[var(--color-text-primary)] hover:bg-black/[0.03] dark:hover:bg-white/[0.04]"
                  }`}
                >
                  <div className="flex items-center space-x-2">
                    <TextHThree size={14} className={editor.isActive("heading", { level: 3 }) ? "text-[var(--color-teal-primary)]" : "text-[var(--color-text-subtle)]"} />
                    <span className="text-[12px]">三级标题</span>
                  </div>
                  <span className="text-[10px] font-mono text-[var(--color-text-subtle)] opacity-40">/h3</span>
                </button>

                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => {
                    editor.chain().focus().toggleBlockquote().run();
                    setShowMoreMenu(false);
                  }}
                  className={`w-full px-2 py-1.5 rounded-lg flex items-center justify-between text-left transition-colors cursor-pointer ${
                    editor.isActive("blockquote")
                      ? "bg-black/[0.05] dark:bg-white/[0.08] text-[var(--color-teal-primary)]"
                      : "text-[var(--color-text-primary)] hover:bg-black/[0.03] dark:hover:bg-white/[0.04]"
                  }`}
                >
                  <div className="flex items-center space-x-2">
                    <Quotes size={14} className={editor.isActive("blockquote") ? "text-[var(--color-teal-primary)]" : "text-[var(--color-text-subtle)]"} />
                    <span className="text-[12px]">引用段落</span>
                  </div>
                  <span className="text-[10px] font-mono text-[var(--color-text-subtle)] opacity-40">/quote</span>
                </button>

                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => {
                    editor.chain().focus().toggleCodeBlock().run();
                    setShowMoreMenu(false);
                  }}
                  className={`w-full px-2 py-1.5 rounded-lg flex items-center justify-between text-left transition-colors cursor-pointer ${
                    editor.isActive("codeBlock")
                      ? "bg-black/[0.05] dark:bg-white/[0.08] text-[var(--color-teal-primary)]"
                      : "text-[var(--color-text-primary)] hover:bg-black/[0.03] dark:hover:bg-white/[0.04]"
                  }`}
                >
                  <div className="flex items-center space-x-2">
                    <CodeBlockIconPh size={14} className={editor.isActive("codeBlock") ? "text-[var(--color-teal-primary)]" : "text-[var(--color-text-subtle)]"} />
                    <span className="text-[12px]">等宽代码块</span>
                  </div>
                  <span className="text-[10px] font-mono text-[var(--color-text-subtle)] opacity-40">/code</span>
                </button>

                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => {
                    editor.chain().focus().setHorizontalRule().run();
                    setShowMoreMenu(false);
                  }}
                  className="w-full px-2 py-1.5 rounded-lg flex items-center justify-between text-left transition-colors cursor-pointer text-[var(--color-text-primary)] hover:bg-black/[0.03] dark:hover:bg-white/[0.04]"
                >
                  <div className="flex items-center space-x-2">
                    <Minus size={14} weight="bold" className="text-[var(--color-text-subtle)]" />
                    <span className="text-[12px]">水平分割线</span>
                  </div>
                  <span className="text-[10px] font-mono text-[var(--color-text-subtle)] opacity-40">/divider</span>
                </button>

                <div className="my-1 border-t border-[var(--color-border-panel)]/50" />

                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => {
                    editor.chain().focus().unsetAllMarks().clearNodes().run();
                    setShowMoreMenu(false);
                  }}
                  className="w-full px-2 py-1.5 rounded-lg flex items-center justify-between text-left transition-colors cursor-pointer text-[var(--color-text-subtle)] hover:text-[var(--color-text-primary)] hover:bg-black/[0.03] dark:hover:bg-white/[0.04]"
                >
                  <div className="flex items-center space-x-2">
                    <Eraser size={14} />
                    <span className="text-[12px]">清除格式</span>
                  </div>
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* History (Undo / Redo) docked on the right */}
      <div className="flex items-center space-x-0.5 shrink-0 pl-1">
        <ToolbarButton
          label="撤销"
          shortcut="⌘Z"
          disabled={!editor.can().undo()}
          onClick={() => editor.chain().focus().undo().run()}
        >
          <ArrowUUpLeft size={14} />
        </ToolbarButton>
        <ToolbarButton
          label="重做"
          shortcut="⌘⇧Z"
          disabled={!editor.can().redo()}
          onClick={() => editor.chain().focus().redo().run()}
        >
          <ArrowUUpRight size={14} />
        </ToolbarButton>
      </div>
    </div>
  );
};

export interface FloatickEditorHandle {
  getMarkdown: () => string;
  setMarkdown: (content: string) => void;
  focus: () => void;
}

export interface FloatickTiptapEditorProps {
  initialContent: string;
  onChange?: (markdown: string) => void;
  onCmdEnter?: () => void;
  editorRef?: React.MutableRefObject<FloatickEditorHandle | null>;
  className?: string;
  showToolbar?: boolean;
}

export const FloatickTiptapEditor: React.FC<FloatickTiptapEditorProps> = ({
  initialContent,
  onChange,
  onCmdEnter,
  editorRef,
  className = "",
  showToolbar = true,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const menuListRef = useRef<HTMLDivElement>(null);
  const itemRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const lastEmittedMarkdownRef = useRef<string | null>(null);

  const [, setSelectionTick] = useState(0);

  const [showSlashMenu, setShowSlashMenu] = useState(false);
  const [slashQuery, setSlashQuery] = useState("");
  const [slashMenuIndex, setSlashMenuIndex] = useState(0);
  const [menuCoords, setMenuCoords] = useState<{ top: number; left: number }>({ top: 0, left: 0 });

  // Filter commands based on slashQuery
  const filteredCommands = useMemo(() => {
    if (!slashQuery) return SLASH_COMMANDS;
    const q = slashQuery.toLowerCase();
    return SLASH_COMMANDS.filter(
      (cmd) =>
        cmd.label.toLowerCase().includes(q) ||
        cmd.id.toLowerCase().includes(q) ||
        cmd.shortcut.toLowerCase().includes(q) ||
        cmd.desc.toLowerCase().includes(q)
    );
  }, [slashQuery]);

  // Keep refs synchronized with state to avoid stale closure issues in handleKeyDown
  const showSlashMenuRef = useRef(showSlashMenu);
  const slashMenuIndexRef = useRef(slashMenuIndex);
  const filteredCommandsRef = useRef(filteredCommands);
  const slashQueryRef = useRef(slashQuery);

  useEffect(() => {
    showSlashMenuRef.current = showSlashMenu;
    slashMenuIndexRef.current = slashMenuIndex;
    filteredCommandsRef.current = filteredCommands;
    slashQueryRef.current = slashQuery;
  }, [showSlashMenu, slashMenuIndex, filteredCommands, slashQuery]);

  // Execute Slash Command
  const handleSelectCommand = (cmd: SlashCommandItem) => {
    if (!editor) return;
    const { from } = editor.state.selection;
    // Delete the '/' character and any query text typed after it
    const deleteLength = 1 + slashQueryRef.current.length;
    editor
      .chain()
      .focus()
      .deleteRange({ from: Math.max(0, from - deleteLength), to: from })
      .run();
    cmd.action(editor);
    setShowSlashMenu(false);
    setSlashQuery("");
  };

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: {
          levels: [1, 2, 3],
        },
      }),
      TaskList,
      TaskItem.configure({
        nested: true,
        // Node views do not inherit the data-type added by renderHTML.
        HTMLAttributes: { "data-type": "taskItem" },
      }),
      Markdown.configure({
        html: true,
        transformPastedText: true,
        transformCopiedText: true,
      }),
    ],
    content: initialContent || "",
    editorProps: {
      attributes: {
        class: "tiptap focus:outline-none min-h-[160px] pb-12",
      },
      handleKeyDown: (_view, event) => {
        if (event.isComposing || (event as any).keyCode === 229) {
          return false;
        }

        // If slash menu is active, intercept navigation keys before ProseMirror
        if (showSlashMenuRef.current) {
          const list = filteredCommandsRef.current;
          if (list.length > 0) {
            if (event.key === "ArrowDown") {
              event.preventDefault();
              setSlashMenuIndex((prev) => (prev + 1) % list.length);
              return true;
            }

            if (event.key === "ArrowUp") {
              event.preventDefault();
              setSlashMenuIndex((prev) => (prev - 1 + list.length) % list.length);
              return true;
            }

            if (event.key === "Enter" || event.key === "Tab") {
              event.preventDefault();
              const selectedCmd = list[slashMenuIndexRef.current] || list[0];
              if (selectedCmd) {
                handleSelectCommand(selectedCmd);
              }
              return true;
            }

            if (event.key === "Escape") {
              event.preventDefault();
              setShowSlashMenu(false);
              setSlashQuery("");
              return true;
            }
          }
        }

        // Cmd+Enter or Ctrl+Enter to trigger save
        if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
          event.preventDefault();
          onCmdEnter?.();
          return true;
        }

        return false;
      },
    },
    onUpdate: ({ editor }) => {
      const { from } = editor.state.selection;
      const textBefore = editor.state.doc.textBetween(Math.max(0, from - 24), from, "\n");

      // Match '/' preceded by start of block or whitespace, followed by optional alphanumeric/Chinese query
      const slashMatch = textBefore.match(/(?:^|\s)\/([a-zA-Z0-9\u4e00-\u9fa5]*)$/);

      if (slashMatch) {
        const query = slashMatch[1];
        setSlashQuery(query);

        // Calculate menu coordinate position
        const coords = editor.view.coordsAtPos(from);
        const containerRect = containerRef.current?.getBoundingClientRect();

        if (containerRect) {
          const menuHeight = 280;
          const spaceBelow = containerRect.bottom - coords.bottom;
          let relativeTop = coords.bottom - containerRect.top + 6;

          // If insufficient space below, flip above cursor
          if (spaceBelow < menuHeight && coords.top - containerRect.top > menuHeight) {
            relativeTop = coords.top - containerRect.top - menuHeight - 6;
          }

          const relativeLeft = Math.min(
            Math.max(8, coords.left - containerRect.left),
            Math.max(8, containerRect.width - 272)
          );
          setMenuCoords({ top: relativeTop, left: relativeLeft });
        }

        setShowSlashMenu(true);
        setSlashMenuIndex(0);
      } else {
        if (showSlashMenu) {
          setShowSlashMenu(false);
          setSlashQuery("");
        }
      }

      const md = (editor.storage as any).markdown?.getMarkdown?.() ?? "";
      lastEmittedMarkdownRef.current = md;
      onChange?.(md);
    },
    onSelectionUpdate: () => {
      setSelectionTick((t) => t + 1);
    },
    onTransaction: () => {
      setSelectionTick((t) => t + 1);
    },
  });

  // Auto-scroll selected item into view whenever slashMenuIndex changes
  useEffect(() => {
    if (showSlashMenu) {
      const targetButton = itemRefs.current[slashMenuIndex];
      if (targetButton) {
        targetButton.scrollIntoView({
          block: "nearest",
          inline: "nearest",
          behavior: "auto",
        });
      }
    }
  }, [showSlashMenu, slashMenuIndex]);

  useEffect(() => {
    // Hydrate late initial data without reparsing our own updates. Empty headings
    // and task items are still editable structure even when editor.isEmpty is true.
    if (
      editor && !editor.isDestroyed && initialContent && editor.isEmpty &&
      initialContent !== lastEmittedMarkdownRef.current
    ) {
      editor.commands.setContent(initialContent);
    }
  }, [editor, initialContent]);

  // Reset scroll to top whenever slash menu first appears
  useEffect(() => {
    if (showSlashMenu) {
      setSlashMenuIndex(0);
      menuListRef.current?.scrollTo({ top: 0, behavior: "auto" });
    }
  }, [showSlashMenu]);

  useEffect(() => {
    if (typeof window !== "undefined" && window.location.search.includes("slash")) {
      setTimeout(() => {
        setMenuCoords({ top: 125, left: 16 });
        setShowSlashMenu(true);
      }, 400);
    }
  }, []);

  // Expose methods via editorRef
  useEffect(() => {
    if (!editorRef) return;
    editorRef.current = {
      getMarkdown: () => {
        if (!editor) return "";
        return (editor.storage as any).markdown?.getMarkdown?.() ?? "";
      },
      setMarkdown: (content: string) => {
        if (!editor) return;
        editor.commands.setContent(content || "");
      },
      focus: () => {
        if (!editor || editor.isDestroyed) return;
        // WebKit can flush DOM changes synchronously on focus. Focus the view
        // before creating a transaction so it uses the current document state.
        editor.view.focus();
        editor.commands.scrollIntoView();
      },
    };
  }, [editor, editorRef]);

  return (
    <div ref={containerRef} className={`relative flex-1 flex flex-col min-h-0 ${className}`}>
      {showToolbar && <EditorToolbar editor={editor} />}
      <EditorContent editor={editor} className="tiptap-scroll-container flex-1 overflow-y-auto smooth-scroll pr-1" />

      {/* Floating Slash Command Menu */}
      {showSlashMenu && filteredCommands.length > 0 && (
        <>
          <div
            className="fixed inset-0 z-40 bg-transparent"
            onClick={() => {
              setShowSlashMenu(false);
              setSlashQuery("");
            }}
          />
          <div
            ref={menuListRef}
            style={{ top: `${menuCoords.top}px`, left: `${menuCoords.left}px` }}
            className="slash-menu-scrollbar absolute z-50 w-64 max-h-[290px] overflow-y-auto rounded-xl bg-[var(--color-bg-drawer)] text-[var(--color-text-primary)] border border-[var(--color-border-drawer)] shadow-lg dark:shadow-2xl p-1.5 backdrop-blur-xl animate-in fade-in zoom-in-95 duration-100 pr-1.5"
          >
            <div className="px-2 pt-1 pb-1.5 text-[11px] font-medium text-[var(--color-text-subtle)] select-none">
              常用模块
            </div>
            {filteredCommands.map((cmd, index) => {
              const Icon = cmd.icon;
              const isSelected = index === slashMenuIndex;
              return (
                <button
                  key={cmd.id}
                  type="button"
                  ref={(el) => {
                    itemRefs.current[index] = el;
                  }}
                  onClick={() => handleSelectCommand(cmd)}
                  onMouseEnter={() => setSlashMenuIndex(index)}
                  className={`group w-full px-2.5 py-1.5 rounded-lg flex items-center space-x-2.5 text-left transition-colors duration-100 cursor-pointer ${
                    isSelected
                      ? "bg-black/[0.05] dark:bg-white/[0.08]"
                      : "hover:bg-black/[0.03] dark:hover:bg-white/[0.04]"
                  }`}
                >
                  {/* Pure icon without background or border */}
                  <div className="w-4 h-4 flex items-center justify-center shrink-0">
                    <Icon
                      className={`w-3.5 h-3.5 transition-colors duration-100 ${
                        isSelected
                          ? "text-[var(--color-teal-primary)]"
                          : "text-[var(--color-text-subtle)] group-hover:text-[var(--color-text-primary)]"
                      }`}
                    />
                  </div>

                  {/* Single-line description text + shortcut */}
                  <div className="flex items-center justify-between min-w-0 flex-1">
                    <span
                      className={`text-[12.5px] leading-tight truncate transition-colors ${
                        isSelected
                          ? "text-[var(--color-text-primary)] font-medium"
                          : "text-[var(--color-text-secondary)]"
                      }`}
                    >
                      {cmd.desc}
                    </span>
                    <span
                      className={`text-[10px] font-mono shrink-0 ml-2 transition-opacity ${
                        isSelected
                          ? "text-[var(--color-teal-primary)] opacity-85 font-medium"
                          : "text-[var(--color-text-subtle)] opacity-35 group-hover:opacity-65"
                      }`}
                    >
                      {cmd.shortcut}
                    </span>
                  </div>
                </button>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
};
