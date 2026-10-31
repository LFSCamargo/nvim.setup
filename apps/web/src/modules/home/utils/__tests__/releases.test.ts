import { describe, expect, it } from 'vitest';
import {
  defaultInstallRefs,
  fallbackRelease,
  installCommands,
  parseGithubReleases,
} from '@/modules/home/utils/releases';

describe('install version refs', () => {
  it('pins a release tag on the public curl one-liner', () => {
    expect(installCommands('standard', 'v1.1.0')).toBe(
      [
        'curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash -s -- --version v1.1.0',
        'nvim .',
      ].join('\n'),
    );
    expect(installCommands('preview', 'v1.0.0')).toContain(
      'bash -s -- --preview --version v1.0.0',
    );
    expect(installCommands('preview', 'v1.0.0')).toContain(
      'NVIM_APPNAME=nvim-preview nvim .',
    );
  });

  it('keeps main as an unpinned current checkout', () => {
    expect(installCommands('standard', 'main')).toBe(
      [
        'curl -fsSL https://raw.githubusercontent.com/LFSCamargo/nvim.setup/main/scripts/bootstrap.sh | bash',
        'nvim .',
      ].join('\n'),
    );
  });

  it('lists GitHub releases and always offers main', () => {
    expect(parseGithubReleases(null)).toEqual(defaultInstallRefs());
    expect(
      parseGithubReleases([
        { tag_name: 'v1.1.0', draft: false, prerelease: false },
        { tag_name: 'v1.0.0-beta', draft: false, prerelease: true },
        { tag_name: 'skip', draft: true },
      ]),
    ).toEqual([
      { id: 'v1.1.0', label: 'v1.1.0 (latest)' },
      { id: 'v1.0.0-beta', label: 'v1.0.0-beta (prerelease)' },
      { id: 'main', label: 'main (unreleased)' },
    ]);
    expect(fallbackRelease).toMatch(/^v\d+\.\d+\.\d+/);
  });
});
