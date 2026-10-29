import type { Components } from 'react-markdown';
import Markdown from 'react-markdown';
import { Link } from 'react-router-dom';
import remarkGfm from 'remark-gfm';
import { localDocHref } from '@/lib/docs';

function resolveHref(href: string | undefined): string | undefined {
  if (!href) return href;
  const file = href.split('/').pop();
  if (file && localDocHref[file]) return localDocHref[file];
  if (href.endsWith('.md') && !href.startsWith('http')) {
    const slug = file?.replace(/\.md$/i, '').toLowerCase();
    if (slug === 'editor') return '/docs/editor';
    if (slug === 'plugins') return '/docs/plugins';
    if (slug === 'e2e-testplan') return '/docs/testing';
  }
  return href;
}

const components: Components = {
  a({ href, children }) {
    const next = resolveHref(href);
    if (next?.startsWith('/')) {
      return (
        <Link
          to={next}
          className="text-foreground underline underline-offset-4"
        >
          {children}
        </Link>
      );
    }
    return (
      <a
        href={next}
        className="text-foreground underline underline-offset-4"
        {...(next?.startsWith('http')
          ? { target: '_blank', rel: 'noreferrer' }
          : {})}
      >
        {children}
      </a>
    );
  },
  pre({ children }) {
    return (
      <pre className="overflow-x-auto rounded-xl border border-line bg-black/40 p-4 font-mono text-[13px] leading-7 dark:bg-black/40">
        {children}
      </pre>
    );
  },
  code({ className, children, ...props }) {
    const isBlock = Boolean(className);
    if (isBlock) {
      return (
        <code className={className} {...props}>
          {children}
        </code>
      );
    }
    return (
      <code
        className="rounded bg-glass px-1.5 py-0.5 font-mono text-[0.85em]"
        {...props}
      >
        {children}
      </code>
    );
  },
  table({ children }) {
    return (
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left text-sm">
          {children}
        </table>
      </div>
    );
  },
  th({ children }) {
    return (
      <th className="border-b border-line px-3 py-2 font-medium text-foreground">
        {children}
      </th>
    );
  },
  td({ children }) {
    return (
      <td className="border-b border-line px-3 py-2 align-top text-muted">
        {children}
      </td>
    );
  },
};

type MarkdownViewProps = {
  markdown: string;
};

export function MarkdownView({ markdown }: MarkdownViewProps) {
  return (
    <div className="docs-prose">
      <Markdown remarkPlugins={[remarkGfm]} components={components}>
        {markdown}
      </Markdown>
    </div>
  );
}
