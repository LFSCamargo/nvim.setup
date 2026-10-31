import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('../../', import.meta.url);
const read = (path) => readFileSync(new URL(path, root), 'utf8');
const json = (path) => JSON.parse(read(path));

test('workspace test commands resolve after the scripts move', () => {
  const commands = json('project.json').targets.test.options.commands;
  const shellTests = ['bootstrap', 'fonts', 'scan', 'format', 'bump'];
  assert.deepEqual(commands, [
    'make test',
    'node --test scripts/tests/workspace.test.mjs',
    ...shellTests.map((name) => `bash scripts/shell/__tests__/${name}.test.sh`),
  ]);
  for (const name of shellTests) {
    const path = `scripts/shell/__tests__/${name}.test.sh`;
    assert.equal(existsSync(new URL(path, root)), true, `${path} is missing`);
    assert.match(read(path), /dirname -- "\$0"\)\/\.\.\/\.\.\/\.\./);
  }
  assert.equal(existsSync(new URL('scripts/e2e/e2e.lua', root)), true);
  assert.equal(existsSync(new URL('scripts/e2e/e2e-init.lua', root)), true);
  assert.equal(
    existsSync(new URL('scripts/e2e/web-browser.spec.ts', root)),
    true,
  );
  const playwright = read('playwright.config.mjs');
  assert.match(playwright, /testDir: '\.\/scripts\/e2e'/);
  assert.match(playwright, /testMatch: 'web-browser\.spec\.ts'/);
  const packageScripts = json('package.json').scripts;
  for (const command of commands.slice(1)) {
    assert.match(
      packageScripts['test:workspace'],
      new RegExp(command.replaceAll('.', '\\.')),
    );
  }
});

test('web shared files sit in components, hooks, utils, or constants', () => {
  const kinds = new Set(['components', 'hooks', 'utils', 'constants']);
  const files = readdirSync(new URL('apps/web/src/shared/', root), {
    recursive: true,
  }).filter((name) => /\.(ts|tsx)$/.test(name));

  assert.ok(files.length > 0, 'shared/ is empty');
  for (const rel of files) {
    const [kind, ...rest] = rel.replaceAll('\\', '/').split('/');
    const name = rest.at(-1);
    assert.equal(
      kinds.has(kind),
      true,
      `${rel} must live under components/, hooks/, utils/, or constants/`,
    );
    if (kind === 'components') {
      assert.match(
        name,
        /\.tsx$/,
        `${rel} belongs in components/ as a .tsx file`,
      );
    }
    if (kind === 'hooks') {
      assert.match(
        name,
        /^use-.+\.ts$/,
        `${rel} belongs in hooks/ as use-*.ts`,
      );
    }
    if (kind === 'constants') {
      assert.match(name, /\.ts$/, `${rel} belongs in constants/ as a .ts file`);
    }
  }
});
