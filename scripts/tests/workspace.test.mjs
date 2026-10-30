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
    'bash scripts/tests/fonts.test.sh',
    'bash scripts/tests/scan.test.sh',
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
  assert.equal(
    existsSync(
      new URL('../../apps/web/public/assets/layout.png', import.meta.url),
    ),
    true,
  );
  assert.match(read('apps/web/src/content.ts'), /id: 'agents'/);
  assert.match(read('apps/web/src/content.ts'), /id: 'layout'/);
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
  assert.equal(
    existsSync(new URL('../../scripts/tests/fonts.test.sh', import.meta.url)),
    true,
  );
  assert.match(read('scripts/install.sh'), /scripts\/fonts\.sh/);
  assert.match(bootstrap, /scripts\/fonts\.sh/);
});

test('marketing site publishes titles, Open Graph tags, robots, and a sitemap', () => {
  const html = read('apps/web/index.html');
  const robots = read('apps/web/public/robots.txt');
  const sitemap = read('apps/web/public/sitemap.xml');
  const seo = read('apps/web/src/lib/seo.ts');
  const content = read('apps/web/src/content.ts');
  assert.match(
    content,
    /site = 'https:\/\/lfscamargo\.github\.io\/nvim\.setup'/,
  );
  assert.match(html, /property="og:title"/);
  assert.match(html, /rel="canonical"/);
  assert.match(html, /application\/ld\+json/);
  assert.match(robots, /Disallow: \/guides\//);
  assert.match(
    robots,
    /Sitemap: https:\/\/lfscamargo\.github\.io\/nvim\.setup\/sitemap\.xml/,
  );
  assert.match(sitemap, /\/docs\/getting-started/);
  assert.match(sitemap, /\/docs\/editor/);
  assert.doesNotMatch(sitemap, /\/guides\//);
  assert.match(seo, /export function applyPageMeta/);
  assert.match(read('apps/web/src/pages/home-page.tsx'), /useDocumentMeta/);
  assert.match(read('apps/web/src/pages/docs-page.tsx'), /useDocumentMeta/);
});

test('marketing site recovers refreshed docs URLs on static hosts', () => {
  const vite = read('apps/web/vite.config.ts');
  assert.match(vite, /appType: 'spa'/);
  assert.match(vite, /writeSpaFallback/);
  assert.match(vite, /name: 'spa-fallback'/);
  assert.match(read('apps/web/src/lib/spa.ts'), /404\.html/);
  assert.match(read('apps/web/public/_redirects'), /\/\* +\/index\.html +200/);
  assert.equal(
    existsSync(new URL('../../apps/web/public/.nojekyll', import.meta.url)),
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

function versionAtLeast(spec, min) {
  const found = String(spec).match(/(\d+)\.(\d+)\.(\d+)/);
  const want = min.split('.').map(Number);
  assert.ok(found, `expected a semver in ${spec}`);
  const got = found.slice(1).map(Number);
  const rank = (parts) => parts[0] * 1e6 + parts[1] * 1e3 + parts[2];
  assert.ok(rank(got) >= rank(want), `${spec} must be >= ${min} (OWASP A06)`);
}

test('patched npm advisories stay above the OWASP A06 floor', () => {
  const overrides = json('package.json').pnpm.overrides;
  versionAtLeast(
    json('apps/web/package.json').devDependencies.vitest,
    '4.1.12',
  );
  versionAtLeast(overrides['brace-expansion@>=4'], '5.0.12');
  versionAtLeast(overrides['postcss-selector-parser'], '6.1.5');
});

test('OWASP Semgrep and npm audit fail the website CI', () => {
  const semgrep = read('.github/workflows/semgrep.yml');
  assert.match(semgrep, /image: semgrep\/semgrep/);
  assert.match(semgrep, /scripts\/semgrep-scan\.sh/);
  assert.doesNotMatch(semgrep, /SEMGREP_APP_TOKEN/);
  assert.match(read('scripts/semgrep-scan.sh'), /p\/owasp-top-ten/);
  assert.match(read('scripts/semgrep-scan.sh'), /--error/);
  assert.match(read('.github/workflows/web.yml'), /scripts\/scan\.sh audit/);
  assert.match(read('package.json'), /"scan": "bash scripts\/scan\.sh"/);
  assert.match(read('Makefile'), /bash scripts\/scan\.sh/);
  assert.match(read('.semgrepignore'), /node_modules\//);
  assert.match(read('pnpm-workspace.yaml'), /minimumReleaseAge:\s*10080/);
  assert.match(read('pnpm-workspace.yaml'), /trustPolicy:\s*no-downgrade/);
  assert.match(read('pnpm-workspace.yaml'), /blockExoticSubdeps:\s*true/);
});

test('commit hooks and CI use the same pnpm workspace install', () => {
  const workflow = read('.github/workflows/commitlint.yml');
  assert.match(workflow, /pnpm\/action-setup@[0-9a-f]{40}/);
  assert.match(workflow, /pnpm install --frozen-lockfile/);
  assert.doesNotMatch(workflow, /npm ci|cache: npm|npx /);
  assert.match(read('.husky/commit-msg'), /pnpm exec commitlint --edit "\$1"/);
  assert.match(read('Makefile'), /pnpm exec commitlint --last/);
});
