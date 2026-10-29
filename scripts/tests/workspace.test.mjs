import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { test } from 'node:test';

const read = (path) =>
  readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8');
const json = (path) => JSON.parse(read(path));

test('workspace uses one pnpm lockfile and discovers the marketing app', () => {
  assert.match(json('package.json').packageManager, /^pnpm@10\.\d+\.\d+$/);
  assert.match(read('pnpm-lock.yaml'), /^lockfileVersion: '9\.0'/);
  assert.equal(
    (read('pnpm-lock.yaml').match(/^---$/gm) || []).length,
    0,
    'Nx requires a single-document pnpm lockfile',
  );
  assert.match(read('pnpm-workspace.yaml'), /apps\/\*/);
  assert.equal(
    existsSync(new URL('../../package-lock.json', import.meta.url)),
    false,
  );
  assert.equal(json('apps/web/package.json').name, 'web');
});

test('Nx delegates the real setup checks without caching interactive e2e results', () => {
  const setup = json('project.json');
  assert.equal(setup.name, 'setup');
  assert.equal(setup.targets.e2e.options.command, 'make e2e');
  assert.equal(setup.targets.e2e.cache, false);
  assert.equal(setup.targets.test.cache, false);
  assert.deepEqual(setup.targets.test.options.commands, [
    'make test',
    'node --test scripts/tests/workspace.test.mjs',
    'bash scripts/tests/bootstrap.test.sh',
  ]);
  assert.equal(setup.targets.test.options.parallel, false);
  assert.equal(json('package.json').scripts.build, 'nx run web:build');
});

test('marketing app is TypeScript with Tailwind and Prettier', () => {
  assert.equal(
    existsSync(new URL('../../apps/web/tsconfig.json', import.meta.url)),
    true,
  );
  assert.equal(
    existsSync(new URL('../../apps/web/src/App.tsx', import.meta.url)),
    true,
  );
  assert.equal(
    existsSync(new URL('../../apps/web/src/App.jsx', import.meta.url)),
    false,
  );
  assert.match(read('apps/web/src/styles.css'), /@import ['"]tailwindcss['"]/);
  assert.match(read('apps/web/vite.config.ts'), /@tailwindcss\/vite/);
  assert.match(read('prettier.config.mjs'), /prettier-plugin-tailwindcss/);
  assert.match(read('package.json'), /"format": "prettier --write \."/);
  assert.match(read('.github/workflows/web.yml'), /pnpm format:check/);
  assert.equal(
    existsSync(
      new URL('../../apps/web/public/assets/agents.png', import.meta.url),
    ),
    true,
  );
  assert.match(read('apps/web/src/content.ts'), /id: 'agents'/);
});

test('bootstrap is a curl-pipeable installer that does not bundle markdown', () => {
  const bootstrap = read('scripts/bootstrap.sh');
  const content = read('apps/web/src/content.ts');
  assert.match(
    bootstrap,
    /raw\.githubusercontent\.com\/LFSCamargo\/nvim\.setup\/main\/scripts\/bootstrap\.sh/,
  );
  assert.match(bootstrap, /Do not run this installer as root/);
  assert.doesNotMatch(bootstrap, /\?raw/);
  assert.match(
    content,
    /curl -fsSL https:\/\/raw\.githubusercontent\.com\/LFSCamargo\/nvim\.setup\/main\/scripts\/bootstrap\.sh \| bash/,
  );
  assert.match(content, /bash -s -- --preview/);
  assert.equal(
    existsSync(
      new URL('../../scripts/tests/bootstrap.test.sh', import.meta.url),
    ),
    true,
  );
});

test('docs reader loads static public guides instead of bundling markdown', () => {
  const docs = read('apps/web/src/lib/docs.ts');
  assert.doesNotMatch(docs, /\?raw/);
  assert.doesNotMatch(docs, /from ['"].+\.md['"]/);
  assert.match(docs, /src: '\/guides\/getting-started\.md'/);
  assert.match(read('apps/web/src/pages/docs-page.tsx'), /fetch\(page\.src\)/);
  assert.match(read('apps/web/vite.config.ts'), /copy-repo-guides/);
  for (const name of [
    'getting-started.md',
    'workspace.md',
    'editor.md',
    'plugins.md',
    'testing.md',
  ]) {
    assert.equal(
      existsSync(
        new URL(`../../apps/web/public/guides/${name}`, import.meta.url),
      ),
      true,
      `missing static guide ${name}`,
    );
  }
});

test('commit hooks and CI use the same pnpm workspace install', () => {
  const workflow = read('.github/workflows/commitlint.yml');
  assert.match(workflow, /pnpm\/action-setup@v4/);
  assert.match(workflow, /pnpm install --frozen-lockfile/);
  assert.doesNotMatch(workflow, /npm ci|cache: npm|npx /);
  assert.match(read('.husky/commit-msg'), /pnpm exec commitlint --edit "\$1"/);
  assert.match(read('Makefile'), /pnpm exec commitlint --last/);
});
