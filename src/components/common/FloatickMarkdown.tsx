import React from "react";
import { useTranslation } from "react-i18next";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface FloatickMarkdownProps {
  content: string;
  emptyMessage?: string;
  className?: string;
}

export const FloatickMarkdown: React.FC<FloatickMarkdownProps> = ({
  content,
  emptyMessage,
  className = "",
}) => {
  const { t } = useTranslation();
  const defaultEmpty = emptyMessage || t("markdownPreviewEmptyMessage");

  if (!content || !content.trim()) {
    return (
      <div className="py-6 text-center text-xs text-[var(--color-text-subtle)] italic">
        {defaultEmpty}
      </div>
    );
  }

  return (
    <div className={`text-[13.5px] leading-[1.65] font-sans text-[var(--color-text-primary)] select-text ${className}`}>
      <Markdown
        remarkPlugins={[remarkGfm]}
        components={{
          h1: ({ children }) => (
            <h1 className="text-[17px] font-bold text-[var(--color-text-primary)] mt-3.5 mb-2 pb-1 border-b border-[var(--color-border-panel)] tracking-tight">
              {children}
            </h1>
          ),
          h2: ({ children }) => (
            <h2 className="text-[15px] font-semibold text-[var(--color-text-primary)] mt-3 mb-1.5 tracking-tight">
              {children}
            </h2>
          ),
          h3: ({ children }) => (
            <h3 className="text-[13.5px] font-semibold text-[var(--color-text-primary)] mt-2.5 mb-1">
              {children}
            </h3>
          ),
          p: ({ children }) => (
            <p className="text-[13.5px] leading-[1.65] text-[var(--color-text-primary)] mb-2 last:mb-0">
              {children}
            </p>
          ),
          ul: ({ children }) => (
            <ul className="list-disc list-inside text-[13.5px] leading-[1.65] text-[var(--color-text-primary)] my-2 pl-1 space-y-1">
              {children}
            </ul>
          ),
          ol: ({ children }) => (
            <ol className="list-decimal list-inside text-[13.5px] leading-[1.65] text-[var(--color-text-primary)] my-2 pl-1 space-y-1">
              {children}
            </ol>
          ),
          li: ({ children }) => (
            <li className="text-[13.5px] leading-relaxed">{children}</li>
          ),
          blockquote: ({ children }) => (
            <blockquote className="border-l-[3px] border-[var(--color-teal-primary)] bg-[var(--color-teal-tint)] px-3.5 py-2 rounded-r-lg my-2.5 text-[13px] italic text-[var(--color-text-secondary)]">
              {children}
            </blockquote>
          ),
          pre: ({ children }) => (
            <pre className="p-3.5 rounded-xl bg-[var(--color-hover-overlay)] border border-[var(--color-border-panel)] font-mono text-[12px] overflow-x-auto my-2.5 text-[var(--color-text-primary)] leading-relaxed">
              {children}
            </pre>
          ),
          code: ({ className: codeClassName, children, ...props }) => {
            const isCodeBlock = codeClassName && codeClassName.startsWith("language-");
            if (isCodeBlock) {
              return <code className="font-mono text-[11.5px]">{children}</code>;
            }
            return (
              <code
                className="font-mono text-[11px] px-1.5 py-0.5 rounded-md bg-[var(--color-hover-overlay)] text-[var(--color-teal-primary)] font-medium"
                {...props}
              >
                {children}
              </code>
            );
          },
          a: ({ href, children }) => (
            <a
              href={href}
              target="_blank"
              rel="noopener noreferrer"
              className="text-[var(--color-teal-primary)] underline underline-offset-2 hover:opacity-80 transition-opacity font-medium"
            >
              {children}
            </a>
          ),
          hr: () => <hr className="my-3.5 border-[var(--color-border-panel)]" />,
          table: ({ children }) => (
            <div className="overflow-x-auto my-2.5">
              <table className="w-full text-xs border-collapse border border-[var(--color-border-panel)] rounded-xl overflow-hidden">
                {children}
              </table>
            </div>
          ),
          th: ({ children }) => (
            <th className="bg-[var(--color-hover-overlay)] px-3 py-1.5 text-left font-semibold border-b border-[var(--color-border-panel)]">
              {children}
            </th>
          ),
          td: ({ children }) => (
            <td className="px-3 py-1.5 border-b border-[var(--color-border-panel)]">
              {children}
            </td>
          ),
          strong: ({ children }) => (
            <strong className="font-semibold text-[var(--color-text-primary)]">
              {children}
            </strong>
          ),
          em: ({ children }) => (
            <em className="italic text-[var(--color-text-primary)]">
              {children}
            </em>
          ),
          del: ({ children }) => (
            <del className="line-through opacity-60">{children}</del>
          ),
        }}
      >
        {content}
      </Markdown>
    </div>
  );
};
