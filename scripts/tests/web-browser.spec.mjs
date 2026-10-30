import { test, expect } from '@playwright/test';

async function overlapHeaderWith(page, selector) {
  await page.evaluate((sel) => {
    const target = document.querySelector(sel);
    const header = document.querySelector('header');
    if (!target || !header) return;
    const targetBox = target.getBoundingClientRect();
    const headerBox = header.getBoundingClientRect();
    const top =
      window.scrollY +
      targetBox.top +
      Math.min(160, targetBox.height * 0.35) -
      (headerBox.top + headerBox.height / 2);
    window.scrollTo({ top, left: 0, behavior: 'instant' });
    window.dispatchEvent(new Event('scroll'));
  }, selector);
  await expect
    .poll(() =>
      page.evaluate((sel) => {
        const target = document.querySelector(sel);
        const header = document.querySelector('header');
        if (!target || !header) return false;
        const targetBox = target.getBoundingClientRect();
        const headerBox = header.getBoundingClientRect();
        const y = headerBox.top + headerBox.height / 2;
        return y >= targetBox.top && y <= targetBox.bottom;
      }, selector),
    )
    .toBe(true);
}

test('installation, screenshots, help and keyboard access work', async ({
  page,
  context,
}) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toContainText('build');
  await expect(page.getByLabel('Standard installation commands')).toContainText(
    'scripts/bootstrap.sh',
  );
  await expect(page.getByLabel('Standard installation commands')).toHaveClass(
    /whitespace-pre-wrap/,
  );
  await expect(
    page.getByRole('link', { name: 'Install Neovim 0.12+' }),
  ).toHaveAttribute(
    'href',
    'https://github.com/neovim/neovim/blob/master/INSTALL.md',
  );
  await expect(
    page.getByRole('link', {
      name: 'Full requirements in the getting started guide ↗',
    }),
  ).toHaveAttribute('href', '/docs/getting-started');
  await expect
    .poll(() =>
      page
        .getByRole('button', { name: 'Enlarge workspace screenshot' })
        .locator('img')
        .evaluate((img) => img.naturalWidth),
    )
    .toBeGreaterThan(0);
  await page
    .getByRole('button', { name: 'Try alongside', exact: true })
    .click();
  await expect(page.getByLabel('Preview installation commands')).toContainText(
    'NVIM_APPNAME=nvim-preview',
  );
  await page.getByRole('button', { name: 'Copy commands' }).click();
  await expect(page.getByText('Copied ✓')).toBeVisible();
  expect(await page.evaluate(() => navigator.clipboard.readText())).toContain(
    'NVIM_APPNAME=nvim-preview',
  );
  await page
    .getByRole('button', { name: 'Source control', exact: true })
    .click();
  await page
    .getByRole('button', { name: 'Enlarge source control screenshot' })
    .click();
  await expect(page.getByRole('dialog')).toBeVisible();
  await expect(page.getByRole('dialog').locator('img')).toHaveAttribute(
    'src',
    '/assets/git.png',
  );
  await expect(page.getByRole('dialog')).toContainText('Source control');
  await expect(
    page.getByRole('button', { name: 'Close screenshot' }),
  ).toBeVisible();
  await expect(page.getByRole('banner')).toBeHidden();
  const dialogBox = await page.getByRole('dialog').boundingBox();
  const viewport = page.viewportSize();
  expect(dialogBox).toBeTruthy();
  expect(viewport).toBeTruthy();
  expect(dialogBox.height).toBeLessThan(viewport.height - 32);
  expect(dialogBox.width).toBeLessThanOrEqual(viewport.width);
  await page.screenshot({ path: 'test-results/screenshot-dialog.png' });
  await page.keyboard.press('Escape');
  await expect(page.getByRole('dialog')).toHaveCount(0);
  await page.getByRole('button', { name: 'The layout', exact: true }).click();
  await page
    .getByRole('button', { name: 'Enlarge the layout screenshot' })
    .click();
  await expect(page.getByRole('dialog').locator('img')).toHaveAttribute(
    'src',
    '/assets/layout.png',
  );
  await page.keyboard.press('Escape');
  await expect(page.getByRole('dialog')).toHaveCount(0);
  await page.getByRole('button', { name: 'AI agents', exact: true }).click();
  await page
    .getByRole('button', { name: 'Enlarge ai agents screenshot' })
    .click();
  await expect(page.getByRole('dialog')).toBeVisible();
  await expect(page.getByRole('dialog').locator('img')).toHaveAttribute(
    'src',
    '/assets/agents.png',
  );
  await expect
    .poll(() =>
      page
        .getByRole('dialog')
        .locator('img')
        .evaluate((img) => img.naturalWidth),
    )
    .toBeGreaterThan(0);
  await page.getByRole('button', { name: 'Next screenshot' }).click();
  await expect(page.getByRole('dialog').locator('img')).toHaveAttribute(
    'src',
    '/assets/editor.png',
  );
  await page.keyboard.press('Escape');
  await expect(page.getByRole('dialog')).toHaveCount(0);
  await expect(
    page.getByRole('link', { name: 'Ask for help' }),
  ).toHaveAttribute(
    'href',
    'https://github.com/LFSCamargo/nvim.setup/issues/new/choose',
  );
  expect(errors).toEqual([]);
});

test('header logo turns black over the light install band', async ({
  page,
}) => {
  await page.goto('/');
  const logo = page
    .getByRole('banner')
    .getByRole('link', { name: 'nvim.setup home' })
    .locator('svg');
  await expect(logo).toHaveClass(/text-white/);
  await overlapHeaderWith(page, '#install');
  await expect(logo).toHaveClass(/text-black/);
  await page.evaluate(() => window.scrollTo(0, 0));
  await expect(logo).toHaveClass(/text-white/);
});

test('light mode keeps hero chrome, cards, and docs readable', async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  await page.getByRole('button', { name: 'Light', exact: true }).click();
  await expect(page.locator('html')).not.toHaveClass(/dark/);
  await expect(page.getByRole('heading', { level: 1 })).toContainText('build');
  await expect(page.getByText(/The speed of Neovim/)).toBeVisible();
  const subtitleFilter = await page
    .locator('p')
    .filter({ hasText: 'The speed of Neovim' })
    .locator('span span')
    .first()
    .evaluate((el) => getComputedStyle(el).filter);
  expect(subtitleFilter === 'none' || subtitleFilter === '').toBe(true);
  const caret = page.locator('[data-hero-caret]');
  await expect(caret).toBeVisible();
  const caretBox = await caret.boundingBox();
  expect(caretBox).toBeTruthy();
  expect(caretBox.width).toBeLessThan(caretBox.height * 0.3);
  await expect(page.getByRole('link', { name: /Make it yours/ })).toHaveClass(
    /border-zinc-900/,
  );
  await expect(
    page
      .getByRole('navigation', { name: 'Main navigation' })
      .getByRole('link', {
        name: 'Workspace',
      }),
  ).toHaveClass(/text-black/);
  const shell = page.locator('[data-nav-shell]');
  await expect(shell).toHaveCount(1);
  await expect(shell).not.toHaveClass(/border-white/);
  await expect(shell).not.toHaveClass(/border-zinc-900/);
  await expect(shell).not.toHaveAttribute('data-rim');
  await expect(
    page
      .getByRole('button', { name: 'Enlarge workspace screenshot' })
      .locator('xpath=ancestor::*[@data-rim][1]'),
  ).toHaveAttribute('data-rim', 'dark');
  await expect(
    page.getByRole('heading', { name: 'Files, in a real tree.' }),
  ).toBeVisible();
  expect(
    await page.evaluate(() => document.documentElement.scrollHeight),
  ).toBeLessThan(9000);
  await page.goto('/docs/getting-started');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(
    'Get started',
  );
  await expect(
    page
      .getByRole('banner')
      .getByRole('link', { name: 'nvim.setup home' })
      .locator('svg'),
  ).toHaveClass(/text-black/);
  await page.screenshot({
    path: 'test-results/docs-light.png',
    fullPage: true,
  });
});

test('light and dark switchers change the page theme and invert the install band', async ({
  page,
}) => {
  await page.goto('/');
  const light = page.getByRole('button', { name: 'Light', exact: true });
  const dark = page.getByRole('button', { name: 'Dark', exact: true });
  const logo = page
    .getByRole('banner')
    .getByRole('link', { name: 'nvim.setup home' })
    .locator('svg');
  await expect(dark).toHaveAttribute('aria-pressed', 'true');
  await light.click();
  await expect(light).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('html')).not.toHaveClass(/dark/);
  await expect(logo).toHaveClass(/text-black/);
  await expect(page.locator('#install')).toHaveClass(/bg-zinc-950/);
  const shell = page.locator('[data-nav-shell]');
  await expect(shell).not.toHaveClass(/border-white/);
  await expect(shell).not.toHaveAttribute('data-rim');
  await page.evaluate(() => window.scrollTo(0, 0));
  await expect(page.locator('#install h2')).toBeVisible();
  expect(
    await page.locator('#install h2').evaluate((node) => {
      let opacity = 1;
      let el = node;
      while (el) {
        opacity *= Number(getComputedStyle(el).opacity);
        el = el.parentElement;
      }
      return opacity;
    }),
  ).toBeGreaterThan(0.9);
  expect(
    await page
      .getByRole('heading', { name: 'Files, in a real tree.' })
      .evaluate((node) => {
        let opacity = 1;
        let el = node;
        while (el) {
          opacity *= Number(getComputedStyle(el).opacity);
          el = el.parentElement;
        }
        return opacity;
      }),
  ).toBeGreaterThan(0.9);
  expect(
    await page.evaluate(() => document.documentElement.scrollHeight),
  ).toBeLessThan(9000);
  await expect
    .poll(() =>
      page
        .getByRole('button', { name: 'Enlarge workspace screenshot' })
        .locator('img')
        .evaluate((img) => img.naturalWidth),
    )
    .toBeGreaterThan(0);
  await page.screenshot({
    path: 'test-results/landing-light.png',
    fullPage: true,
  });
  await overlapHeaderWith(page, '[aria-label="Enlarge workspace screenshot"]');
  await expect(logo).toHaveClass(/text-white/);
  await expect(shell).not.toHaveClass(/border-white/);
  await overlapHeaderWith(page, '#install');
  await expect(logo).toHaveClass(/text-white/);
  await expect(shell).not.toHaveClass(/border-white/);
  await dark.click();
  await expect(page.locator('html')).toHaveClass(/dark/);
});

test('mobile layout and reduced motion remain usable', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  await page.getByRole('button', { name: 'Menu +' }).click();
  await page
    .getByRole('navigation')
    .getByRole('link', { name: 'Documentation' })
    .click();
  await expect(page).toHaveURL(/\/docs\/getting-started$/);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.screenshot({
    path: 'test-results/landing-mobile.png',
    fullPage: true,
  });
});

test('documentation sidebar lets visitors read guides and open GitHub', async ({
  page,
  context,
}) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  const guide = await page.request.get('/guides/getting-started.md');
  expect(guide.ok()).toBeTruthy();
  expect(await guide.text()).toContain('# Get started');
  await page.goto('/docs');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText(
    'Get started',
  );
  await expect(page.getByLabel('terminal code sample').first()).toBeVisible();
  await page.getByRole('button', { name: 'Copy code' }).first().click();
  await expect(page.getByText('Copied ✓').first()).toBeVisible();
  expect(await page.evaluate(() => navigator.clipboard.readText())).toContain(
    'scripts/bootstrap.sh',
  );
  await page
    .getByRole('navigation', { name: 'Documentation' })
    .getByRole('link', { name: 'Editor guide' })
    .click();
  await expect(page).toHaveURL(/\/docs\/editor$/);
  await expect(page.getByRole('heading', { level: 1 })).toContainText(
    'Neovim setup',
  );
  await expect(
    page.getByRole('link', { name: 'View on GitHub ↗' }),
  ).toHaveAttribute(
    'href',
    'https://github.com/LFSCamargo/nvim.setup/blob/main/docs/EDITOR.md',
  );
});

test('principles marquee fills the viewport with two equal looping halves', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1600, height: 900 });
  await page.goto('/');
  const viewport = page.locator('[data-marquee-viewport]');
  const groups = page.locator('[data-marquee-group]');
  await expect(viewport).toHaveAttribute('aria-label', /little less friction/i);
  await expect(groups).toHaveCount(2);
  const metrics = await viewport.evaluate((node) => {
    const halves = [...node.querySelectorAll('[data-marquee-group]')];
    const track = node.querySelector('[data-marquee-track]');
    const styles = track ? getComputedStyle(track) : null;
    return {
      viewport: node.getBoundingClientRect().width,
      group0: halves[0]?.getBoundingClientRect().width ?? 0,
      group1: halves[1]?.getBoundingClientRect().width ?? 0,
      copies: halves[0]?.childElementCount ?? 0,
      iteration: styles?.animationIterationCount,
      name: styles?.animationName,
    };
  });
  expect(metrics.copies).toBeGreaterThanOrEqual(2);
  expect(metrics.group0).toBeGreaterThanOrEqual(metrics.viewport);
  expect(Math.abs(metrics.group0 - metrics.group1)).toBeLessThan(1);
  expect(metrics.iteration).toBe('infinite');
  expect(metrics.name).toMatch(/marquee/);
  await page.waitForFunction(() => {
    const track = document.querySelector('[data-marquee-track]');
    if (!track) {
      return false;
    }
    const transform = getComputedStyle(track).transform;
    if (!transform || transform === 'none') {
      return false;
    }
    return new DOMMatrixReadOnly(transform).m41 < -1;
  });
});

test('desktop visual capture', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({
    path: 'test-results/landing-desktop.png',
    fullPage: true,
  });
});
