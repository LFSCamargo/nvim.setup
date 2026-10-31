export type TokenKind =
  'text' | 'comment' | 'string' | 'punct' | 'flag' | 'env' | 'url';

export type Token = { kind: TokenKind; value: string };

const SHELL_LANGUAGES = new Set(['sh', 'bash', 'shell', 'zsh']);

const SHELL_TOKEN =
  /https?:\/\/[^\s'"]+|'[^']*'|"[^"\\]*(?:\\.[^"\\]*)*"|#.*$|\|{1,2}|&&|;|--?[\w-]+|[A-Z_][A-Z0-9_]*=\S+|\s+|\S+/g;

export function wrapsLanguage(language: string): boolean {
  return language !== 'text';
}

export function tokenize(language: string, line: string): Token[] {
  if (!SHELL_LANGUAGES.has(language)) {
    return [{ kind: 'text', value: line }];
  }
  return tokenizeShell(line);
}

export function tokenizeShell(line: string): Token[] {
  if (!line) {
    return [{ kind: 'text', value: '' }];
  }
  const tokens: Token[] = [];
  const pattern = new RegExp(SHELL_TOKEN.source, 'g');
  let match: RegExpExecArray | null;
  let cursor = 0;
  while ((match = pattern.exec(line))) {
    if (match.index > cursor) {
      tokens.push({ kind: 'text', value: line.slice(cursor, match.index) });
    }
    tokens.push({ kind: kindOf(match[0]), value: match[0] });
    cursor = match.index + match[0].length;
  }
  if (cursor < line.length) {
    tokens.push({ kind: 'text', value: line.slice(cursor) });
  }
  return merge(tokens);
}

function kindOf(value: string): TokenKind {
  if (value.startsWith('#')) return 'comment';
  if (value.startsWith('http://') || value.startsWith('https://')) return 'url';
  if (value.startsWith("'") || value.startsWith('"')) return 'string';
  if (value === '|' || value === '||' || value === '&&' || value === ';') {
    return 'punct';
  }
  if (value.startsWith('-')) return 'flag';
  if (/^[A-Z_][A-Z0-9_]*=/.test(value)) return 'env';
  return 'text';
}

function merge(tokens: Token[]): Token[] {
  const out: Token[] = [];
  for (const token of tokens) {
    const last = out[out.length - 1];
    if (last && last.kind === token.kind) {
      last.value += token.value;
    } else {
      out.push({ ...token });
    }
  }
  return out.length > 0 ? out : [{ kind: 'text', value: '' }];
}
