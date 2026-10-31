import { Children, isValidElement, type ReactNode } from 'react';
import type { Components } from 'react-markdown';
import Markdown from 'react-markdown';
import { Link } from 'react-router-dom';
import remarkGfm from 'remark-gfm';
import { CodeBlock } from '@/shared/components/code-block';
import { localDocHref } from '@/modules/docs/utils';

function codeText(children: ReactNode): string {
  if (typeof children === 'string') {
    return children.replace(/\n$/, '');
  }
  if (Array.isArray(children)) {
    return children
      .map((child) => (typeof child === 'string' ? child : ''))
      .join('')
      .replace(/\n$/, '');
  }
  return String(children ?? '').replace(/\n$/, '');
}

function languageFromClass(className: string | undefined): string {
  const match = /language-([\w+-]+)/.exec(className ?? '');
  return match?.[1] ?? 'text';
}

function sampleName(language: string): string {
  if (language === 'text') return 'layout';
  if (language === 'sh' || language === 'bash' || language === 'shell') {
    return 'terminal';
  }
  return language;
}

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
    const child = Children.toArray(children)[0];
    if (isValidElement<{ className?: string; children?: ReactNode }>(child)) {
      const language = languageFromClass(child.props.className);
      return (
        <CodeBlock
          className="mt-5"
          code={codeText(child.props.children)}
          language={language}
          filename={sampleName(language)}
        />
      );
    }
    return (
      <CodeBlock className="mt-5" code={codeText(children)} language="text" />
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
        className="rounded border border-line bg-glass px-1.5 py-0.5 font-mono text-[0.84em] text-foreground"
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
