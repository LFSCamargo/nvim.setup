import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import lint from '@commitlint/lint';
import load from '@commitlint/load';
import parse from '@commitlint/parse';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outfile = join(root, 'CHANGELOG.md');
const sections = new Map([
  ['feat', 'Features'],
  ['fix', 'Bug Fixes'],
  ['perf', 'Performance'],
  ['revert', 'Reverts'],
  ['docs', 'Documentation'],
  ['refactor', 'Refactoring'],
  ['test', 'Tests'],
  ['build', 'Build'],
  ['ci', 'CI'],
  ['chore', 'Chores'],
  ['style', 'Styles'],
]);

function git(args) {
  return execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trimEnd();
}

function repoUrl() {
  try {
    return git(['remote', 'get-url', 'origin'])
      .replace(/^git@github\.com:/, 'https://github.com/')
      .replace(/^ssh:\/\/git@github\.com\//, 'https://github.com/')
      .replace(/^https:\/\/github\.com\//, 'https://github.com/')
      .replace(/\.git$/, '');
  } catch {
    return '';
  }
}

function hashes(range) {
  const args = ['log', '--reverse', '--no-merges', '--format=%H'];
  if (range) args.push(range);
  const out = git(args);
  return out ? out.split('\n') : [];
}

function readCommits() {
  const out = git([
    'log',
    '--reverse',
    '--no-merges',
    '--format=%H%x00%h%x00%cs%x00%B%x1e',
  ]);
  const commits = [];
  for (const record of out.split('\x1e')) {
    const trimmed = record.replace(/^\n/, '');
    if (!trimmed) continue;
    const [hash, short, date, raw = ''] = trimmed.split('\x00');
    const message = raw.replace(/\n+$/, '');
    if (!hash || !message) continue;
    commits.push({
      hash,
      short,
      date,
      message,
      subject: message.split('\n')[0],
    });
  }
  return commits;
}

function releaseTags() {
  const out = git(['tag', '--list', '--sort=version:refname']);
  return out
    ? out.split('\n').filter((tag) => /^v?\d+\.\d+\.\d+$/.test(tag))
    : [];
}

function isLegacyFailure(report, parsed) {
  if (report.valid) return false;
  return (
    !parsed.type ||
    report.errors.every(
      (error) => error.name === 'type-empty' || error.name === 'subject-empty',
    )
  );
}

function isBreaking(parsed) {
  if (
    (parsed.notes || []).some((note) =>
      /^BREAKING[- ]CHANGE$/i.test(note.title),
    )
  )
    return true;
  return /!:/.test(parsed.header || '');
}

function isChangelogCommit(parsed) {
  return parsed.type === 'chore' && parsed.scope === 'changelog';
}

function entryLine(commit, parsed, url) {
  const subject = (parsed.subject || commit.subject).trim();
  const scope = parsed.scope ? `**${parsed.scope}:** ` : '';
  const link = url
    ? `[${commit.short}](${url}/commit/${commit.hash})`
    : commit.short;
  return `- ${scope}${subject} (${link})`;
}

function renderSection(title, lines) {
  return lines.length ? `### ${title}\n\n${lines.join('\n')}\n` : '';
}

function renderRelease(title, grouped, order) {
  const blocks = [];
  if (grouped.has('breaking'))
    blocks.push(renderSection('Breaking Changes', grouped.get('breaking')));
  for (const type of order) {
    if (type === 'breaking' || type === 'other') continue;
    if (grouped.has(type))
      blocks.push(renderSection(sections.get(type) || type, grouped.get(type)));
  }
  for (const [type, lines] of grouped) {
    if (
      type === 'breaking' ||
      type === 'other' ||
      sections.has(type) ||
      order.includes(type)
    )
      continue;
    blocks.push(renderSection(type, lines));
  }
  if (grouped.has('other'))
    blocks.push(renderSection('Other', grouped.get('other')));
  return `## ${title}\n\n${blocks.filter(Boolean).join('\n')}`;
}

const config = await load({}, { cwd: root });
const parserOpts =
  config.parserPreset && typeof config.parserPreset === 'object'
    ? config.parserPreset.parserOpts
    : undefined;
const lintOpts = {
  parserOpts: parserOpts && typeof parserOpts === 'object' ? parserOpts : {},
  plugins: config.plugins,
  ignores: config.ignores,
  defaultIgnores: config.defaultIgnores,
};

const url = repoUrl();
const commits = readCommits();
if (!commits.length) {
  console.error('ERROR: No git commits found.');
  process.exit(1);
}

const byHash = new Map();
const unknownTypes = [];
let conventional = 0;
let other = 0;
const invalid = [];

for (const commit of commits) {
  const report = await lint(commit.message, config.rules, lintOpts);
  const parsed = await parse(commit.message, undefined, lintOpts.parserOpts);
  const legacy = isLegacyFailure(report, parsed);
  if (!report.valid && !legacy) {
    invalid.push({ commit, report });
    continue;
  }
  if (legacy || !parsed.type) {
    other += 1;
    byHash.set(commit.hash, { commit, parsed, section: 'other' });
    continue;
  }
  conventional += 1;
  if (isChangelogCommit(parsed)) continue;
  if (!sections.has(parsed.type) && !unknownTypes.includes(parsed.type))
    unknownTypes.push(parsed.type);
  byHash.set(commit.hash, {
    commit,
    parsed,
    section: isBreaking(parsed) ? 'breaking' : parsed.type,
  });
}

if (invalid.length) {
  for (const { commit, report } of invalid) {
    console.error(`${commit.short} ${commit.subject}`);
    for (const error of report.errors)
      console.error(`  ${error.name}: ${error.message}`);
  }
  console.error(
    `ERROR: ${invalid.length} commit(s) failed Conventional Commits checks.`,
  );
  process.exit(1);
}

const tags = releaseTags();
const releases = [];
let previous;
for (const tag of tags) {
  const range = previous ? `${previous}..${tag}` : tag;
  const date = git(['log', '-1', '--format=%cs', tag]);
  const label = tag.replace(/^v/, '');
  releases.push({
    title: `[${label}] - ${date}`,
    hashes: hashes(range),
    tag,
    label,
    previous,
  });
  previous = tag;
}
releases.push({
  title: '[Unreleased]',
  hashes: previous ? hashes(`${previous}..HEAD`) : hashes(),
  tag: null,
  label: 'Unreleased',
  previous,
});

const typeOrder = [...sections.keys(), ...unknownTypes];
const changelogReleases = [];
const compare = [];
for (const release of [...releases].reverse()) {
  const grouped = new Map();
  for (const hash of [...release.hashes].reverse()) {
    const item = byHash.get(hash);
    if (!item) continue;
    const lines = grouped.get(item.section) || [];
    lines.push(entryLine(item.commit, item.parsed, url));
    grouped.set(item.section, lines);
  }
  if (!grouped.size && release.tag) continue;
  changelogReleases.push(
    grouped.size
      ? renderRelease(release.title, grouped, typeOrder)
      : `## ${release.title}\n`,
  );
  if (!url) continue;
  if (release.tag && release.previous) {
    compare.push(
      `[${release.label}]: ${url}/compare/${release.previous}...${release.tag}`,
    );
  } else if (release.tag) {
    compare.push(`[${release.label}]: ${url}/releases/tag/${release.tag}`);
  } else if (release.previous) {
    compare.push(`[Unreleased]: ${url}/compare/${release.previous}...HEAD`);
  } else {
    compare.push(`[Unreleased]: ${url}/commits/HEAD`);
  }
}

const body = [
  '<!-- Generated by make changelog; do not edit by hand. -->',
  '',
  '# Changelog',
  '',
  'All notable changes to this project are documented in this file.',
  'The script validates every commit against Conventional Commits, then groups the history by type.',
  'Scopes are optional. Commits from before that convention are listed under Other.',
  '`chore(changelog)` regeneration commits are omitted so the file can be committed without a loop.',
  '',
  changelogReleases.join('\n'),
  compare.length ? compare.join('\n') + '\n' : '',
].join('\n');

writeFileSync(outfile, body);
console.log(
  `Validated ${commits.length} commits (${conventional} conventional, ${other} other).`,
);
console.log(`Wrote ${outfile}`);
