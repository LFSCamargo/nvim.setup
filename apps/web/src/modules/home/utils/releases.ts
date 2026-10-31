import type { InstallMode } from '@/modules/home/constants/install-content';

export type InstallRef = {
  id: string;
  label: string;
};

export const mainRef = 'main';
export const fallbackRelease = 'v2.0.0';
export const bootstrapUrl =
  'https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh';
export const githubReleasesUrl =
  'https://api.github.com/repos/LFSCamargo/nvim.setup/releases?per_page=30';

export function defaultInstallRefs(): InstallRef[] {
  return [
    { id: fallbackRelease, label: `${fallbackRelease} (latest)` },
    { id: mainRef, label: 'main (unreleased)' },
  ];
}

export function parseGithubReleases(payload: unknown): InstallRef[] {
  if (!Array.isArray(payload)) {
    return defaultInstallRefs();
  }
  const tags: InstallRef[] = [];
  for (const item of payload) {
    if (!item || typeof item !== 'object') {
      continue;
    }
    const release = item as {
      tag_name?: unknown;
      draft?: unknown;
      prerelease?: unknown;
    };
    if (release.draft === true || typeof release.tag_name !== 'string') {
      continue;
    }
    const id = release.tag_name;
    const latest = tags.length === 0 && release.prerelease !== true;
    tags.push({
      id,
      label: latest
        ? `${id} (latest)`
        : release.prerelease === true
          ? `${id} (prerelease)`
          : id,
    });
  }
  if (tags.length === 0) {
    return defaultInstallRefs();
  }
  tags.push({ id: mainRef, label: 'main (unreleased)' });
  return tags;
}

export function installCommands(
  mode: InstallMode,
  ref: string,
  withHscroll = true,
): string {
  const flags: string[] = [];
  if (mode === 'preview') {
    flags.push('--preview');
  }
  if (!withHscroll) {
    flags.push('--no-hscroll');
  }
  if (ref !== mainRef) {
    flags.push('--version', ref);
  }
  const pipe =
    flags.length > 0
      ? `curl -fsSL ${bootstrapUrl} | bash -s -- ${flags.join(' ')}`
      : `curl -fsSL ${bootstrapUrl} | bash`;
  const open =
    mode === 'preview' ? 'NVIM_APPNAME=nvim-preview nvim .' : 'nvim .';
  return `${pipe}\n${open}`;
}
