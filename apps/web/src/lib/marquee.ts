const FALLBACK_COPIES = 4;
const MAX_COPIES = 24;

export function marqueeCopies(
  viewportWidth: number,
  sequenceWidth: number,
): number {
  if (viewportWidth <= 0 || sequenceWidth <= 0) {
    return FALLBACK_COPIES;
  }

  return Math.min(
    MAX_COPIES,
    Math.max(2, Math.ceil(viewportWidth / sequenceWidth) + 1),
  );
}

export function marqueeDurationSeconds(
  copies: number,
  sequenceWidth: number,
  pxPerSecond: number,
): number {
  const distance = copies * sequenceWidth;
  if (distance <= 0 || pxPerSecond <= 0) {
    return FALLBACK_COPIES * 20;
  }

  return distance / pxPerSecond;
}
