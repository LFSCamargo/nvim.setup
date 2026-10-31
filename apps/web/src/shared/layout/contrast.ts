const GRAYSCALE_LIGHT = 0.5;
const SAMPLE_COUNT = 5;

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
  if (match) {
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
  return parseColorWithCanvas(color);
}

function parseColorWithCanvas(color: string) {
  if (typeof document === 'undefined' || !color || color === 'transparent') {
    return null;
  }
  try {
    const canvas = document.createElement('canvas');
    canvas.width = 1;
    canvas.height = 1;
    const ctx = canvas.getContext('2d');
    if (!ctx) return null;
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, 1, 1);
    const pixel = ctx.getImageData(0, 0, 1, 1).data;
    return {
      r: pixel[0],
      g: pixel[1],
      b: pixel[2],
      a: pixel[3] / 255,
    };
  } catch {
    return null;
  }
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

export function grayscaleLevel(r: number, g: number, b: number) {
  return (r + g + b) / (3 * 255);
}

export function isLightBackdrop(color: string) {
  const parsed = parseCssColor(color);
  if (!parsed || parsed.a < 0.6) return false;
  return grayscaleLevel(parsed.r, parsed.g, parsed.b) > GRAYSCALE_LIGHT;
}

export function isHeaderOverLightBackdrop(header: Element) {
  const band = header.getBoundingClientRect();
  if (band.width <= 0 || band.height <= 0) return false;
  const y = band.top + band.height / 2;
  const inset = Math.min(48, band.width * 0.08);
  const span = Math.max(1, band.width - inset * 2);
  const samples: number[] = [];

  peekBehindHeader(header, () => {
    for (let i = 0; i < SAMPLE_COUNT; i++) {
      const x = band.left + inset + (i / (SAMPLE_COUNT - 1)) * span;
      const gray = grayscaleAt(x, y, header);
      if (gray !== null) samples.push(gray);
    }
  });

  if (samples.length === 0) {
    return isLightBackdrop(
      window.getComputedStyle(document.body).backgroundColor,
    );
  }
  const lightSamples = samples.filter((value) => value > GRAYSCALE_LIGHT);
  return lightSamples.length * 2 > samples.length;
}

function grayscaleAt(x: number, y: number, header: Element): number | null {
  const fromHit = grayscaleFromElement(elementBehindHeader(x, y), x, y);
  if (fromHit !== null) return fromHit;
  return grayscaleFromStack(x, y, header);
}

function grayscaleFromElement(
  el: Element | null,
  x: number,
  y: number,
): number | null {
  let node: Element | null = el;
  while (node && node !== document.documentElement && node !== document.body) {
    const painted = paintedGrayscale(node);
    if (painted !== null) return painted;
    if (node instanceof HTMLImageElement) {
      const sampled = imageGrayscaleAt(node, x, y);
      if (sampled !== null) return sampled;
    }
    node = node.parentElement;
  }
  return null;
}

function grayscaleFromStack(
  x: number,
  y: number,
  header: Element,
): number | null {
  let best: { area: number; gray: number } | null = null;
  for (const node of document.querySelectorAll('body *')) {
    if (node === header || header.contains(node)) continue;
    const box = node.getBoundingClientRect();
    if (box.width <= 0 || box.height <= 0) continue;
    if (y < box.top || y > box.bottom || x < box.left || x > box.right) {
      continue;
    }
    const gray = paintedGrayscale(node);
    if (gray === null) continue;
    const area = box.width * box.height;
    if (!best || area < best.area) best = { area, gray };
  }
  return best?.gray ?? null;
}

function paintedGrayscale(node: Element): number | null {
  const parsed = parseCssColor(window.getComputedStyle(node).backgroundColor);
  if (!parsed || parsed.a < 0.6) return null;
  return grayscaleLevel(parsed.r, parsed.g, parsed.b);
}

function imageGrayscaleAt(
  img: HTMLImageElement,
  x: number,
  y: number,
): number | null {
  if (img.naturalWidth < 1 || img.naturalHeight < 1) return null;
  const box = img.getBoundingClientRect();
  if (box.width < 1 || box.height < 1) return null;
  try {
    const canvas = document.createElement('canvas');
    canvas.width = 1;
    canvas.height = 1;
    const ctx = canvas.getContext('2d');
    if (!ctx) return null;
    const sx = ((x - box.left) / box.width) * img.naturalWidth;
    const sy = ((y - box.top) / box.height) * img.naturalHeight;
    ctx.drawImage(img, sx, sy, 1, 1, 0, 0, 1, 1);
    const pixel = ctx.getImageData(0, 0, 1, 1).data;
    if (pixel[3] < 153) return null;
    return grayscaleLevel(pixel[0], pixel[1], pixel[2]);
  } catch {
    return null;
  }
}

function peekBehindHeader(header: Element, read: () => void) {
  if (typeof document.elementFromPoint !== 'function') {
    read();
    return;
  }
  const nodes = [header, ...header.querySelectorAll('*')] as HTMLElement[];
  const previous = nodes.map((node) => node.style.pointerEvents);
  for (const node of nodes) node.style.pointerEvents = 'none';
  try {
    read();
  } finally {
    nodes.forEach((node, index) => {
      node.style.pointerEvents = previous[index] ?? '';
    });
  }
}

function elementBehindHeader(x: number, y: number) {
  if (typeof document.elementFromPoint !== 'function') return null;
  return document.elementFromPoint(x, y);
}
