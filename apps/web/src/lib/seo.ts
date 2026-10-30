import {
  repo,
  screens,
  site,
  siteDescription,
  siteName,
  siteTitle,
} from '@/content';
import { docPages, type DocPage } from '@/lib/docs';

export const MAX_DESCRIPTION = 160;
export const ogImagePath = screens[0].src;
export const ogImageAlt = screens[0].alt;
export const ogImageWidth = screens[0].width;
export const ogImageHeight = screens[0].height;

export type PageMeta = {
  title: string;
  description: string;
  path: string;
  type: 'website' | 'article';
};

export function homeMeta(): PageMeta {
  return {
    title: siteTitle,
    description: siteDescription,
    path: '/',
    type: 'website',
  };
}

export function docMeta(page: DocPage): PageMeta {
  return {
    title: `${page.title} — ${siteName}`,
    description: page.description,
    path: `/docs/${page.slug}`,
    type: 'article',
  };
}

export function descriptionFits(text: string): boolean {
  return text.length > 0 && text.length <= MAX_DESCRIPTION;
}

export function publicPaths(): string[] {
  return ['/', ...docPages.map((page) => `/docs/${page.slug}`)];
}

export function absoluteUrl(path: string, origin = site): string {
  const root = origin.replace(/\/$/, '');
  if (path === '/' || path === '') return `${root}/`;
  if (!path.startsWith('/') || path.startsWith('//') || path.includes('://')) {
    return `${root}/`;
  }
  return `${root}${path}`;
}

export function sitemapXml(origin = site): string {
  const urls = publicPaths()
    .map(
      (path) =>
        `  <url>\n    <loc>${escapeXml(absoluteUrl(path, origin))}</loc>\n  </url>`,
    )
    .join('\n');
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`;
}

export function robotsTxt(origin = site): string {
  return [
    'User-agent: *',
    'Allow: /',
    'Disallow: /guides/',
    '',
    `Sitemap: ${absoluteUrl('/sitemap.xml', origin)}`,
    '',
  ].join('\n');
}

export function pageJsonLd(meta: PageMeta, origin = site) {
  const url = absoluteUrl(meta.path, origin);
  const home = absoluteUrl('/', origin);
  return {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'WebSite',
        name: siteName,
        url: home,
        description: siteDescription,
      },
      {
        '@type': 'SoftwareApplication',
        name: siteName,
        applicationCategory: 'DeveloperApplication',
        operatingSystem: 'macOS, Linux',
        offers: {
          '@type': 'Offer',
          price: '0',
          priceCurrency: 'USD',
        },
        url: home,
        description: siteDescription,
        sameAs: repo,
      },
      {
        '@type': meta.type === 'article' ? 'TechArticle' : 'WebPage',
        name: meta.title,
        description: meta.description,
        url,
        image: absoluteUrl(ogImagePath, origin),
        isPartOf: {
          '@type': 'WebSite',
          name: siteName,
          url: home,
        },
      },
    ],
  };
}

export function liveOrigin(): string {
  if (typeof window !== 'undefined' && window.location?.origin) {
    return window.location.origin;
  }
  return site;
}

export function applyPageMeta(meta: PageMeta, origin = liveOrigin()) {
  document.title = meta.title;
  upsertMeta('name', 'description', meta.description);
  upsertMeta('name', 'robots', 'index,follow');
  upsertMeta('name', 'author', 'LFSCamargo');
  upsertMeta('property', 'og:site_name', siteName);
  upsertMeta('property', 'og:title', meta.title);
  upsertMeta('property', 'og:description', meta.description);
  upsertMeta(
    'property',
    'og:type',
    meta.type === 'article' ? 'article' : 'website',
  );
  upsertMeta('property', 'og:url', absoluteUrl(meta.path, origin));
  upsertMeta('property', 'og:image', absoluteUrl(ogImagePath, origin));
  upsertMeta('property', 'og:image:alt', ogImageAlt);
  upsertMeta('property', 'og:image:width', String(ogImageWidth));
  upsertMeta('property', 'og:image:height', String(ogImageHeight));
  upsertMeta('property', 'og:locale', 'en_US');
  upsertMeta('name', 'twitter:card', 'summary_large_image');
  upsertMeta('name', 'twitter:title', meta.title);
  upsertMeta('name', 'twitter:description', meta.description);
  upsertMeta('name', 'twitter:image', absoluteUrl(ogImagePath, origin));
  upsertMeta('name', 'twitter:image:alt', ogImageAlt);
  upsertLink('canonical', absoluteUrl(meta.path, origin));
  upsertJsonLd('seo-json-ld', pageJsonLd(meta, origin));
}

function upsertMeta(attr: 'name' | 'property', key: string, content: string) {
  const selector = `meta[${attr}="${cssAttr(key)}"]`;
  let el = document.head.querySelector(selector);
  if (!el) {
    el = document.createElement('meta');
    el.setAttribute(attr, key);
    document.head.appendChild(el);
  }
  el.setAttribute('content', content);
}

function upsertLink(rel: string, href: string) {
  let el = document.head.querySelector(`link[rel="${cssAttr(rel)}"]`);
  if (!el) {
    el = document.createElement('link');
    el.setAttribute('rel', rel);
    document.head.appendChild(el);
  }
  el.setAttribute('href', href);
}

function upsertJsonLd(id: string, data: object) {
  let el = document.getElementById(id) as HTMLScriptElement | null;
  if (!el) {
    el = document.createElement('script');
    el.id = id;
    el.type = 'application/ld+json';
    document.head.appendChild(el);
  }
  el.textContent = JSON.stringify(data);
}

function cssAttr(value: string): string {
  return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

function escapeXml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}
