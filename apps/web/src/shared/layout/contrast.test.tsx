import { afterEach, describe, expect, it } from 'vitest';
import {
  grayscaleLevel,
  isHeaderOverLightBackdrop,
  isLightBackdrop,
  parseCssColor,
  relativeLuminance,
} from '@/shared/layout/contrast';

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
  it('treats grayscale above 50% as a light backdrop', () => {
    expect(isLightBackdrop('rgb(255, 255, 255)')).toBe(true);
    expect(isLightBackdrop('rgb(244 244 245)')).toBe(true);
    expect(isLightBackdrop('rgb(129, 129, 129)')).toBe(true);
    expect(grayscaleLevel(129, 129, 129)).toBeGreaterThan(0.5);
  });

  it('keeps grayscale at or below 50% as a dark backdrop', () => {
    expect(isLightBackdrop('rgb(11, 11, 12)')).toBe(false);
    expect(isLightBackdrop('rgb(127, 127, 127)')).toBe(false);
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

  it('switches the header mark to black over a light painted surface', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.style.backgroundColor = 'rgb(244, 244, 245)';
    document.body.append(header, band);
    stubRect(header, { top: 16, height: 64, width: 800 });
    stubRect(band, { top: 40, height: 500, width: 800 });
    expect(isHeaderOverLightBackdrop(header)).toBe(true);
  });

  it('ignores collapsed layout boxes from jsdom defaults', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.style.backgroundColor = 'rgb(244, 244, 245)';
    document.body.append(header, band);
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });

  it('keeps the white mark over a dark painted surface', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.style.backgroundColor = 'rgb(9, 9, 11)';
    document.body.append(header, band);
    stubRect(header, { top: 16, height: 64, width: 800 });
    stubRect(band, { top: 40, height: 500, width: 800 });
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });

  it('keeps the white mark when the header sits over the dark page', () => {
    const header = document.createElement('header');
    const band = document.createElement('section');
    band.style.backgroundColor = 'rgb(244, 244, 245)';
    document.body.append(header, band);
    stubRect(header, { top: 16, height: 64, width: 800 });
    stubRect(band, { top: 400, height: 500, width: 800 });
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });

  it('reads a nested screenshot fill instead of a wrapping page color', () => {
    const header = document.createElement('header');
    const main = document.createElement('main');
    const shot = document.createElement('div');
    main.style.backgroundColor = 'rgb(243, 242, 238)';
    shot.style.backgroundColor = 'rgb(9, 9, 11)';
    main.append(shot);
    document.body.append(header, main);
    stubRect(header, { top: 16, height: 64, width: 800 });
    stubRect(main, { top: 0, height: 2000, width: 800 });
    stubRect(shot, { top: 0, height: 400, width: 800 });
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });

  it('uses the majority of samples so a light gutter does not win over a dark screenshot', () => {
    const header = document.createElement('header');
    const gutter = document.createElement('div');
    const shot = document.createElement('div');
    gutter.style.backgroundColor = 'rgb(243, 242, 238)';
    shot.style.backgroundColor = 'rgb(9, 9, 11)';
    document.body.append(header, gutter, shot);
    stubRect(header, { top: 16, left: 0, width: 800, height: 64 });
    stubRect(gutter, { top: 0, left: 0, width: 80, height: 500 });
    stubRect(shot, { top: 0, left: 80, width: 720, height: 500 });
    expect(isHeaderOverLightBackdrop(header)).toBe(false);
  });
});
