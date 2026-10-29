import { afterEach, describe, expect, it } from 'vitest';
import {
  isHeaderOverLightBackdrop,
  isLightBackdrop,
  parseCssColor,
  relativeLuminance,
} from '@/lib/contrast';

afterEach(() => {
  document.body.replaceChildren();
});

function stubRect(
  el: HTMLElement,
  box: { top: number; left?: number; width?: number; height: number },
) {
  const left = box.left ?? 0;
  const width = box.width ?? 400;
  el.getBoundingClientRect = () =>
    ({
      top: box.top,
      left,
      width,
      height: box.height,
      bottom: box.top + box.height,
      right: left + width,
      x: left,
      y: box.top,
      toJSON() {
        return {};
      },
    }) as DOMRect;
}

describe('nav logo contrast', () => {
  it('treats white and zinc-100 as light backdrops', () => {
    expect(isLightBackdrop('rgb(255, 255, 255)')).toBe(true);
    expect(isLightBackdrop('rgb(244 244 245)')).toBe(true);
    expect(isLightBackdrop('rgba(255, 255, 255, 1)')).toBe(true);
  });

  it('keeps the dark page background as a dark backdrop', () => {
    expect(isLightBackdrop('rgb(11, 11, 12)')).toBe(false);
    expect(isLightBackdrop('rgba(255, 255, 255, 0)')).toBe(false);
    expect(relativeLuminance(11, 11, 12)).toBeLessThan(0.2);
  });

  it('parses legacy and modern rgb() colors', () => {
    expect(parseCssColor('rgb(244, 244, 245)')).toEqual({
      r: 244,
      g: 244,
      b: 245,
      a: 1,
    });
    expect(parseCssColor('rgb(244 244 245 / 80%)')).toEqual({
      r: 244,
      g: 244,
      b: 245,
      a: 0.8,
    });
  });

  it('switches the header logo to the dark mark over a light section', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.dataset.navContrast = 'light';
    document.body.append(header, band);
    stubRect(header, { top: 16, height: 64, width: 800 });
    stubRect(band, { top: 40, height: 500, width: 800 });
    expect(isHeaderOverLightBackdrop(header)).toBe(true);
  });

  it('ignores collapsed layout boxes from jsdom defaults', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.dataset.navContrast = 'light';
    document.body.append(header, band);
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });

  it('uses a dark contrast band to keep the light mark over inverted sections', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.dataset.navContrast = 'dark';
    document.body.append(header, band);
    stubRect(header, { top: 16, height: 64, width: 800 });
    stubRect(band, { top: 40, height: 500, width: 800 });
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });

  it('keeps the light mark when the header sits over the dark page', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.dataset.navContrast = 'light';
    document.body.append(header, band);
    stubRect(header, { top: 16, height: 64, width: 800 });
    stubRect(band, { top: 400, height: 500, width: 800 });
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });
});
