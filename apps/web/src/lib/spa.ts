import { copyFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export const spaFallbackName = '404.html';

export function writeSpaFallback(outDir: string) {
  const index = join(outDir, 'index.html');
  if (!existsSync(index)) {
    throw new Error(`missing ${index}`);
  }
  copyFileSync(index, join(outDir, spaFallbackName));
}
