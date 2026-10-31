import { repo } from '@/shared/constants/site';

export type DocPage = {
  slug: string;
  title: string;
  description: string;
  group: 'Start' | 'Reference';
  src: string;
  githubPath: string;
};

export const docPages: DocPage[] = [
  {
    slug: 'getting-started',
    title: 'Get started',
    description:
      'Install the setup, check requirements, and open your first project.',
    group: 'Start',
    src: '/guides/getting-started.md',
    githubPath: 'README.md',
  },
  {
    slug: 'workspace',
    title: 'The workspace',
    description:
      'Files, editor tabs, Git, Settings, Extensions, AI chats, and sessions.',
    group: 'Start',
    src: '/guides/workspace.md',
    githubPath: 'docs/EDITOR.md',
  },
  {
    slug: 'editor',
    title: 'Editor guide',
    description: 'Keybindings, panes, languages, chat, and debugging.',
    group: 'Reference',
    src: '/guides/editor.md',
    githubPath: 'docs/EDITOR.md',
  },
  {
    slug: 'plugins',
    title: 'Plugins & tools',
    description: 'First-party modules, Lazy plugins, Mason tools, and parsers.',
    group: 'Reference',
    src: '/guides/plugins.md',
    githubPath: 'docs/PLUGINS.md',
  },
  {
    slug: 'testing',
    title: 'E2E test plan',
    description: 'What make e2e covers and how to extend it.',
    group: 'Reference',
    src: '/guides/testing.md',
    githubPath: 'docs/E2E-TESTPLAN.md',
  },
];

export const defaultDocSlug = 'getting-started';

export function isDocSlug(slug: string | undefined): slug is string {
  return Boolean(slug && docPages.some((page) => page.slug === slug));
}

export function getDocPage(slug: string | undefined): DocPage {
  return docPages.find((page) => page.slug === slug) ?? docPages[0]!;
}

export function githubDocUrl(page: DocPage): string {
  return `${repo}/blob/main/${page.githubPath}`;
}

export const localDocHref: Record<string, string> = {
  'EDITOR.md': '/docs/editor',
  'PLUGINS.md': '/docs/plugins',
  'E2E-TESTPLAN.md': '/docs/testing',
  'README.md': '/docs/getting-started',
};
