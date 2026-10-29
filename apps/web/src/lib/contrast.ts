const LIGHT_LUMINANCE = 0.55;

export function parseCssColor(
  color: string,
): { r: number; g: number; b: number; a: number } | null {
  const modern =
    /^rgba?\(\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)(?:\s*\/\s*([\d.]+%?))?\s*\)$/i.exec(
      color,
    );
  const legacy =
    /^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/i.exec(
      color,
    );
  const match = modern ?? legacy;
  if (!match) return null;
  const alphaToken = match[4];
  let a = 1;
  if (alphaToken) {
    a = alphaToken.endsWith('%')
      ? Number(alphaToken.slice(0, -1)) / 100
      : Number(alphaToken);
  }
  return {
    r: Number(match[1]),
    g: Number(match[2]),
    b: Number(match[3]),
    a,
  };
}

export function relativeLuminance(r: number, g: number, b: number) {
  const toLinear = (channel: number) => {
    const sample = channel / 255;
    return sample <= 0.03928
      ? sample / 12.92
      : ((sample + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

export function isLightBackdrop(color: string) {
  const parsed = parseCssColor(color);
  if (!parsed || parsed.a < 0.6) return false;
  return relativeLuminance(parsed.r, parsed.g, parsed.b) > LIGHT_LUMINANCE;
}

export function isHeaderOverLightBackdrop(header: Element) {
  const band = header.getBoundingClientRect();
  if (band.width <= 0 || band.height <= 0) return false;
  const y = band.top + band.height / 2;
  const x = band.left + Math.min(48, Math.max(16, band.width / 8));
  for (const section of document.querySelectorAll('[data-nav-contrast]')) {
    const contrast = section.getAttribute('data-nav-contrast');
    if (contrast !== 'light' && contrast !== 'dark') continue;
    const box = section.getBoundingClientRect();
    if (box.width <= 0 || box.height <= 0) continue;
    if (y >= box.top && y <= box.bottom && x >= box.left && x <= box.right) {
      return contrast === 'light';
    }
  }
  const style = window.getComputedStyle(document.body);
  return isLightBackdrop(style.backgroundColor);
}
