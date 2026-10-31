import { readFileSync } from 'node:fs';
import { afterEach, describe, expect, it } from 'vitest';
import { siteDescription, siteTitle } from '@/shared/site';
import { defaultDocSlug, docPages } from '@/modules/docs/docs';
import {
  MAX_DESCRIPTION,
  absoluteUrl,
  applyPageMeta,
  descriptionFits,
  docMeta,
  homeMeta,
  pageJsonLd,
  publicPaths,
  robotsTxt,
  sitemapXml,
} from '@/shared/seo/seo';

afterEach(() => {
  document.title = '';
  document
    .querySelectorAll(
      'meta[name="description"], meta[property^="og:"], meta[name^="twitter:"], link[rel="canonical"], script#seo-json-ld',
    )
    .forEach((node) => node.remove());
});

describe('page metadata', () => {
  it('builds unique titles for home and each docs page', () => {
    const titles = [
      homeMeta().title,
      ...docPages.map((page) => docMeta(page).title),
    ];
    expect(homeMeta().title).toBe(siteTitle);
    expect(new Set(titles).size).toBe(titles.length);
    for (const page of docPages) {
      expect(docMeta(page).title).toBe(`${page.title} — nvim.setup`);
      expect(docMeta(page).path).toBe(`/docs/${page.slug}`);
      expect(docMeta(page).type).toBe('article');
    }
  });

  it('keeps descriptions within a search snippet', () => {
    expect(homeMeta().description).toBe(siteDescription);
    expect(descriptionFits(homeMeta().description)).toBe(true);
    expect(homeMeta().description.length).toBeLessThanOrEqual(MAX_DESCRIPTION);
    for (const page of docPages) {
      expect(descriptionFits(docMeta(page).description)).toBe(true);
    }
  });

  it('lists every public route in the sitemap and none of the raw guides', () => {
    const paths = publicPaths();
    expect(paths[0]).toBe('/');
    for (const page of docPages) {
      expect(paths).toContain(`/docs/${page.slug}`);
    }
    expect(paths).not.toContain('/docs');
    expect(paths.some((path) => path.startsWith('/guides/'))).toBe(false);
    const xml = sitemapXml();
    expect(xml).toContain('https://lfscamargo.github.io/nvim.setup/');
    expect(xml).toContain(
      `https://lfscamargo.github.io/nvim.setup/docs/${defaultDocSlug}`,
    );
    expect(xml).not.toContain('/guides/');
    expect(robotsTxt()).toContain('Disallow: /guides/');
    expect(robotsTxt()).toContain(
      'Sitemap: https://lfscamargo.github.io/nvim.setup/sitemap.xml',
    );
    expect(readFileSync('public/sitemap.xml', 'utf8')).toBe(sitemapXml());
    expect(readFileSync('public/robots.txt', 'utf8')).toBe(robotsTxt());
  });

  it('applies title, description, canonical, and Open Graph tags to the document', () => {
    applyPageMeta(docMeta(docPages[2]!), 'https://example.test');
    expect(document.title).toBe('Editor guide — nvim.setup');
    expect(
      document
        .querySelector('meta[name="description"]')
        ?.getAttribute('content'),
    ).toBe('Keybindings, panes, languages, chat, and debugging.');
    expect(
      document.querySelector('link[rel="canonical"]')?.getAttribute('href'),
    ).toBe('https://example.test/docs/editor');
    expect(
      document
        .querySelector('meta[property="og:title"]')
        ?.getAttribute('content'),
    ).toBe('Editor guide — nvim.setup');
    expect(
      document
        .querySelector('meta[property="og:type"]')
        ?.getAttribute('content'),
    ).toBe('article');
    expect(
      document
        .querySelector('meta[property="og:image"]')
        ?.getAttribute('content'),
    ).toBe('https://example.test/assets/editor.png');
    expect(
      document
        .querySelector('meta[name="twitter:card"]')
        ?.getAttribute('content'),
    ).toBe('summary_large_image');
  });

  it('refuses protocol-relative and off-site paths in canonical URLs', () => {
    expect(absoluteUrl('//evil.example/phish')).toBe(
      'https://lfscamargo.github.io/nvim.setup/',
    );
    expect(absoluteUrl('https://evil.example/phish')).toBe(
      'https://lfscamargo.github.io/nvim.setup/',
    );
  });

  it('emits SoftwareApplication JSON-LD with the repository', () => {
    const data = pageJsonLd(homeMeta(), 'https://example.test');
    const encoded = JSON.stringify(data);
    expect(encoded).toContain('SoftwareApplication');
    expect(encoded).toContain('https://github.com/LFSCamargo/nvim.setup');
    expect(encoded).toContain('https://example.test/');
    applyPageMeta(homeMeta(), 'https://example.test');
    expect(document.getElementById('seo-json-ld')?.textContent).toContain(
      'SoftwareApplication',
    );
  });
});
