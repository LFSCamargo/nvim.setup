import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { spaFallbackName, writeSpaFallback } from '@/lib/spa';

describe('spa fallback', () => {
  it('copies the SPA shell to 404.html so a refresh can recover the route', () => {
    const dir = mkdtempSync(join(tmpdir(), 'nvim-setup-spa-'));
    const shell = '<!doctype html><div id="root"></div>';
    writeFileSync(join(dir, 'index.html'), shell);
    writeSpaFallback(dir);
    expect(readFileSync(join(dir, spaFallbackName), 'utf8')).toBe(shell);
  });
});
