import { describe, expect, it } from 'vitest';
import { marqueeCopies, marqueeDurationSeconds } from '@/shared/ui/marquee';

describe('marqueeCopies', () => {
  it('keeps enough sequences that one half is wider than the viewport', () => {
    expect(marqueeCopies(1600, 400)).toBe(5);
    expect(marqueeCopies(400, 800)).toBe(2);
    expect(marqueeCopies(2560, 400)).toBe(8);
  });

  it('falls back when layout has not been measured yet', () => {
    expect(marqueeCopies(0, 400)).toBe(4);
    expect(marqueeCopies(1200, 0)).toBe(4);
  });
});

describe('marqueeDurationSeconds', () => {
  it('keeps a constant pixel speed as the strip grows', () => {
    expect(marqueeDurationSeconds(2, 800, 40)).toBe(40);
    expect(marqueeDurationSeconds(8, 800, 40)).toBe(160);
  });
});
