import { useEffect, useState } from 'react';
import { tokenize, wrapsLanguage, type TokenKind } from '@/lib/highlight';
import { cn } from '@/lib/utils';

const tokenClass: Record<TokenKind, string> = {
  text: 'text-zinc-100',
  comment: 'text-zinc-500',
  string: 'text-zinc-200',
  punct: 'text-zinc-500',
  flag: 'text-zinc-400',
  env: 'text-zinc-200',
  url: 'text-zinc-300',
};

type CodeBlockProps = {
  code: string;
  language?: string;
  filename?: string;
  label?: string;
  copyLabel?: string;
  showHeader?: boolean;
  framed?: boolean;
  wrap?: boolean;
  className?: string;
};

export function CodeBlock({
  code,
  language = 'text',
  filename,
  label,
  copyLabel = 'Copy code',
  showHeader = true,
  framed = true,
  wrap,
  className,
}: CodeBlockProps) {
  const [copy, setCopy] = useState(copyLabel);
  const shouldWrap = wrap ?? wrapsLanguage(language);
  const lines = code.replace(/\n$/, '').split('\n');
  const caption = filename ?? language;
  const preLabel = label ?? `${caption} code sample`;

  useEffect(() => {
    const timer = window.setTimeout(() => setCopy(copyLabel), 2500);
    return () => window.clearTimeout(timer);
  }, [copy, copyLabel]);

  async function copyCode() {
    try {
      await navigator.clipboard.writeText(code.replace(/\n$/, ''));
      setCopy('Copied ✓');
    } catch {
      setCopy('Select and copy below');
    }
  }

  return (
    <div
      className={cn(
        'overflow-hidden text-zinc-100',
        framed && 'rounded-xl border border-white/10 bg-zinc-950',
        className,
      )}
    >
      {showHeader ? (
        <div className="flex items-center justify-between gap-3 border-b border-white/10 px-4 py-2.5 font-mono text-[10px] tracking-[0.14em] text-zinc-500">
          <span className="truncate uppercase">{caption}</span>
          <button
            type="button"
            className="shrink-0 tracking-normal text-zinc-400 hover:text-zinc-100"
            aria-label={copyLabel}
            onClick={() => void copyCode()}
          >
            <span aria-live="polite">{copy}</span>
            <span className="ml-2" aria-hidden="true">
              ⧉
            </span>
          </button>
        </div>
      ) : null}
      <pre
        tabIndex={0}
        aria-label={preLabel}
        className={cn(
          'max-w-full overflow-x-auto px-5 py-5 font-mono text-[13px] leading-7',
          shouldWrap ? 'whitespace-pre-wrap' : 'whitespace-pre',
        )}
      >
        <code>
          {lines.map((line, index) => (
            <span
              className={cn(
                'flex gap-4',
                shouldWrap
                  ? 'wrap-anywhere whitespace-pre-wrap'
                  : 'whitespace-pre',
              )}
              key={index}
            >
              <span className="w-6 shrink-0 text-right text-zinc-600 select-none">
                {String(index + 1).padStart(2, '0')}
              </span>
              <span className={shouldWrap ? 'min-w-0 flex-1' : 'shrink-0'}>
                {tokenize(language, line).map((token, tokenIndex) => (
                  <span
                    className={tokenClass[token.kind]}
                    key={`${index}-${tokenIndex}-${token.kind}`}
                  >
                    {token.value || ' '}
                  </span>
                ))}
              </span>
            </span>
          ))}
        </code>
      </pre>
    </div>
  );
}
