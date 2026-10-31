import { describe, expect, it } from 'vitest';
import { tokenize, tokenizeShell, wrapsLanguage } from '@/shared/ui/highlight';

describe('highlight', () => {
  it('wraps shell samples and keeps diagrams intact', () => {
    expect(wrapsLanguage('sh')).toBe(true);
    expect(wrapsLanguage('text')).toBe(false);
  });

  it('leaves diagrams as a single text token', () => {
    expect(tokenize('text', '│ Editor │')).toEqual([
      { kind: 'text', value: '│ Editor │' },
    ]);
  });

  it('marks comments, flags, pipes, urls, and env assignments', () => {
    const tokens = tokenizeShell(
      'curl -fsSL https://example.com/bootstrap.sh | bash -s -- --preview # install',
    );
    expect(tokens).toEqual(
      expect.arrayContaining([
        { kind: 'flag', value: '-fsSL' },
        { kind: 'url', value: 'https://example.com/bootstrap.sh' },
        { kind: 'punct', value: '|' },
        { kind: 'flag', value: '--preview' },
        { kind: 'comment', value: '# install' },
      ]),
    );
    expect(tokenizeShell('NVIM_APPNAME=nvim-preview nvim .')).toEqual(
      expect.arrayContaining([
        { kind: 'env', value: 'NVIM_APPNAME=nvim-preview' },
      ]),
    );
  });

  it('keeps markup as text instead of interpreting it', () => {
    const line = '<script>alert(1)</script> && img.jpg';
    const tokens = tokenizeShell(line);
    expect(tokens.map((token) => token.value).join('')).toBe(line);
    expect(tokens.some((token) => token.value.includes('<script>'))).toBe(true);
    expect(tokens.find((token) => token.value.includes('<script>'))?.kind).toBe(
      'text',
    );
  });
});
