import { useEffect, useState } from 'react';
import {
  defaultInstallRefs,
  fallbackRelease,
  githubReleasesUrl,
  parseGithubReleases,
  type InstallRef,
} from '@/modules/home/utils/releases';

export function useInstallVersions() {
  const [refs, setRefs] = useState<InstallRef[]>(defaultInstallRefs);
  const [selected, setSelected] = useState(fallbackRelease);

  useEffect(() => {
    const controller = new AbortController();
    void fetch(githubReleasesUrl, {
      headers: { Accept: 'application/vnd.github+json' },
      signal: controller.signal,
    })
      .then((response) => (response.ok ? response.json() : Promise.reject()))
      .then((payload: unknown) => {
        const next = parseGithubReleases(payload);
        setRefs(next);
        setSelected((current) =>
          next.some((item) => item.id === current) ? current : next[0].id,
        );
      })
      .catch(() => {
        // Keep the bundled release list when GitHub is unreachable.
      });
    return () => controller.abort();
  }, []);

  return { refs, selected, setSelected };
}
