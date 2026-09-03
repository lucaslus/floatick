import React from "react";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface FloatickMarkdownProps {
  content: string;
  emptyMessage?: string;
  className?: string;
}

export const FloatickMarkdown: React.FC<FloatickMarkdownProps> = ({
  content,
  emptyMessage = "暂无内容",
  className = "",
}) => {
  if (!content || !content.trim()) {
    return (
      <div className="py-6 text-center text-xs text-zinc-400 dark:text-[#8E9599] italic">
        {emptyMessage}
      </div>
    );
  }

  return (
    <div className={`text-xs text-zinc-800 dark:text-[#EEF2F1]/90 select-text ${className}`}>
      <Markdown
        remarkPlugins={[remarkGfm]}
        components={{
          h1: ({ children }) => (
            <h1 className="text-[15px] font-bold text-zinc-900 dark:text-[#EEF2F1] mt-3.5 mb-2 pb-1 border-b border-black/[0.06] dark:border-white/[0.08] tracking-tight">
              {children}
            </h1>
          ),
          h2: ({ children }) => (
            <h2 className="text-[13.5px] font-semibold text-zinc-900 dark:text-[#EEF2F1] mt-3 mb-1.5 tracking-tight">
              {children}
            </h2>
          ),
          h3: ({ children }) => (
            <h3 className="text-[12.5px] font-semibold text-zinc-900 dark:text-[#EEF2F1] mt-2.5 mb-1">
              {children}
            </h3>
          ),
          p: ({ children }) => (
            <p className="text-xs leading-[1.65] text-zinc-800 dark:text-[#EEF2F1]/90 mb-2 last:mb-0">
              {children}
            </p>
          ),
          ul: ({ children }) => (
            <ul className="list-disc list-inside text-xs text-zinc-800 dark:text-[#EEF2F1]/90 my-2 pl-1 space-y-1">
              {children}
            </ul>
          ),
          ol: ({ children }) => (
            <ol className="list-decimal list-inside text-xs text-zinc-800 dark:text-[#EEF2F1]/90 my-2 pl-1 space-y-1">
              {children}
            </ol>
          ),
          li: ({ children }) => (
            <li className="text-xs leading-relaxed">{children}</li>
          ),
          blockquote: ({ children }) => (
            <blockquote className="border-l-[3px] border-teal-500 dark:border-[#22B8A7] bg-teal-500/[0.08] dark:bg-[#22B8A7]/[0.1] px-3.5 py-2 rounded-r-xl my-2.5 text-xs italic text-zinc-700 dark:text-[#EEF2F1]/85">
              {children}
            </blockquote>
          ),
          pre: ({ children }) => (
            <pre className="p-3.5 rounded-xl bg-black/[0.05] dark:bg-black/50 border border-black/[0.06] dark:border-white/[0.08] font-mono text-[11.5px] overflow-x-auto my-2.5 text-zinc-900 dark:text-[#EEF2F1] leading-relaxed">
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
                className="font-mono text-[11px] px-1.5 py-0.5 rounded-md bg-black/[0.06] dark:bg-white/[0.1] text-teal-700 dark:text-[#2CCCBD] font-medium"
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
              className="text-teal-600 dark:text-[#22B8A7] underline underline-offset-2 hover:opacity-80 transition-opacity font-medium"
            >
              {children}
            </a>
          ),
          hr: () => <hr className="my-3.5 border-black/[0.08] dark:border-white/[0.1]" />,
          table: ({ children }) => (
            <div className="overflow-x-auto my-2.5">
              <table className="w-full text-xs border-collapse border border-black/[0.08] dark:border-white/[0.1] rounded-xl overflow-hidden">
                {children}
              </table>
            </div>
          ),
          th: ({ children }) => (
            <th className="bg-black/[0.04] dark:bg-white/[0.06] px-3 py-1.5 text-left font-semibold border-b border-black/[0.08] dark:border-white/[0.1]">
              {children}
            </th>
          ),
          td: ({ children }) => (
            <td className="px-3 py-1.5 border-b border-black/[0.04] dark:border-white/[0.05]">
              {children}
            </td>
          ),
          strong: ({ children }) => (
            <strong className="font-semibold text-zinc-900 dark:text-[#EEF2F1]">
              {children}
            </strong>
          ),
          em: ({ children }) => (
            <em className="italic text-zinc-800 dark:text-[#EEF2F1]/90">
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
