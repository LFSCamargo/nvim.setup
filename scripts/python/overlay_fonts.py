#!/usr/bin/env python3
"""Bake Nerd Font glyphs into a Warp-usable Monocraft face.

Warp has no symbol_map / secondary font list, so the terminal font itself has
to carry Devicons outlines under the family name Warp is set to. Those Private
Use glyphs are scaled to one cell so they sit beside filenames without overlap.
"""
from __future__ import annotations

import sys
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTCollection, TTFont
from fontTools.ttLib.tables._c_m_a_p import cmap_classes

FAMILY = 'Monocraft Nerd Font'
FULL_NAME = 'Monocraft Nerd Font Regular'
PS_NAME = 'MonocraftNerdFont-Regular'
FILL = 1.0
ICON_CELLS = 1
POWERLINE = {0xE0B0: (True, False), 0xE0B1: (True, True),
             0xE0B2: (False, False), 0xE0B3: (False, True)}


def unicode_cmap(font: TTFont) -> dict[int, str]:
    out: dict[int, str] = {}
    for table in font['cmap'].tables:
        if table.isUnicode():
            out.update(table.cmap)
    return out


def is_icon_cp(cp: int) -> bool:
    if 0xE0A0 <= cp <= 0xE0D0:
        return False
    return 0xE000 <= cp <= 0xF8FF or 0xF0000 <= cp <= 0xF1FFF


def set_family_name(font: TTFont) -> None:
    wanted = {
        1: FAMILY,
        2: 'Regular',
        4: FULL_NAME,
        6: PS_NAME,
        16: FAMILY,
        17: 'Regular',
    }
    for rec in font['name'].names:
        if rec.nameID in wanted:
            rec.string = wanted[rec.nameID]


def cell_width(font: TTFont) -> int:
    cmap = unicode_cmap(font)
    for cp in (0x20, 0x41, 0x6D):
        name = cmap.get(cp)
        if name:
            width = font['hmtx'][name][0]
            if width > 0:
                return width
    return font['head'].unitsPerEm


def glyph_bounds(font: TTFont, name: str) -> tuple[float, float, float, float] | None:
    gs = font.getGlyphSet()
    pen = BoundsPen(gs)
    try:
        gs[name].draw(pen)
    except Exception:
        return None
    return pen.bounds


def copy_glyph(src: TTFont, src_name: str, dst: TTFont, dst_name: str, *, cells: int, cell: int) -> None:
    upem = dst['head'].unitsPerEm
    advance = max(cell, cell * cells)
    bounds = glyph_bounds(src, src_name)
    src_adv = max(1, src['hmtx'][src_name][0])
    if bounds:
        xmin, ymin, xmax, ymax = bounds
        gw = max(1.0, xmax - xmin)
        gh = max(1.0, ymax - ymin)
    else:
        xmin, ymin = 0.0, 0.0
        gw, gh = float(src_adv), float(src['head'].unitsPerEm)
    scale = min((advance * FILL) / gw, (upem * FILL) / gh)
    tx = (advance - gw * scale) / 2 - xmin * scale
    hhea = dst['hhea'] if 'hhea' in dst else None
    ascent = int(hhea.ascent) if hhea is not None else int(upem * 0.8)
    descent = int(hhea.descent) if hhea is not None else -int(upem * 0.2)
    ty = descent + ((ascent - descent) - gh * scale) / 2 - ymin * scale
    pen = TTGlyphPen(None)
    src.getGlyphSet()[src_name].draw(TransformPen(pen, (scale, 0, 0, scale, tx, ty)))
    dst['glyf'][dst_name] = pen.glyph()
    dst['hmtx'][dst_name] = (advance, max(0, round(tx)))


def cmap_accepts(table, cp: int) -> bool:
    if table.format in (12, 13):
        return True
    if table.format == 4:
        return 0 <= cp <= 0xFFFF
    return False


def ensure_format12(font: TTFont) -> None:
    tables = font['cmap'].tables
    if any(table.format == 12 for table in tables):
        return
    table = cmap_classes[12](12)
    table.platformID = 3
    table.platEncID = 10
    table.language = 0
    table.cmap = {}
    tables.append(table)


def overlay(dst: TTFont, src: TTFont, *, prefix: str) -> int:
    src_cmap = unicode_cmap(src)
    dst_cmap = unicode_cmap(dst)
    cell = cell_width(dst)
    order = list(dst.getGlyphOrder())
    added = 0
    ensure_format12(dst)
    for cp, src_name in src_cmap.items():
        if not is_icon_cp(cp):
            continue
        dst_name = dst_cmap.get(cp)
        if dst_name is None:
            dst_name = f'{prefix}{cp:05X}'
            if dst_name in dst['glyf']:
                dst_name = f'{prefix}{cp:05X}x{added}'
            order.append(dst_name)
        try:
            copy_glyph(src, src_name, dst, dst_name, cells=ICON_CELLS, cell=cell)
        except Exception:
            continue
        for table in dst['cmap'].tables:
            if cmap_accepts(table, cp):
                table.cmap[cp] = dst_name
        added += 1
    dst.setGlyphOrder(order)
    dst['maxp'].numGlyphs = len(order)
    return added


def pixel_powerline(font: TTFont) -> None:
    """Draw the four tab separators as one-cell, full-height pixel stairs."""
    cell = cell_width(font)
    ascent = font['hhea'].ascent
    descent = font['hhea'].descent
    height = ascent - descent
    steps = 12
    stroke = max(1, cell // steps)
    order = list(font.getGlyphOrder())
    ensure_format12(font)
    for cp, (right, hollow) in POWERLINE.items():
        name = f'pixelPowerline{cp:04X}'
        pen = TTGlyphPen(None)
        for index in range(steps):
            y0 = descent + round(height * index / steps)
            y1 = descent + round(height * (index + 1) / steps)
            reach = min(index, steps - index - 1)
            edge = round(cell * (2 * reach + 2) / steps)
            if right:
                x0, x1 = (max(0, edge - stroke), edge) if hollow else (0, edge)
            else:
                x0, x1 = (cell - edge, min(cell, cell - edge + stroke)) if hollow else (cell - edge, cell)
            if x1 <= x0 or y1 <= y0:
                continue
            pen.moveTo((x0, y0))
            pen.lineTo((x1, y0))
            pen.lineTo((x1, y1))
            pen.lineTo((x0, y1))
            pen.closePath()
        font['glyf'][name] = pen.glyph()
        font['hmtx'][name] = (cell, 0)
        if name not in order:
            order.append(name)
        for table in font['cmap'].tables:
            if cmap_accepts(table, cp):
                table.cmap[cp] = name
    font.setGlyphOrder(order)
    font['maxp'].numGlyphs = len(order)


def load_regular(path: Path) -> TTFont:
    raw = path.read_bytes()[:4]
    if raw == b'ttcf':
        return TTCollection(path).fonts[0]
    if raw in (b'\x00\x01\x00\x00', b'OTTO', b'true'):
        return TTFont(path)
    raise SystemExit(f'not a TrueType font: {path}')


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print('usage: overlay_fonts.py BASE.ttc SYMBOLS.ttf OUT.ttf', file=sys.stderr)
        return 2
    base_path, symbols_path, out_path = map(Path, argv[1:])
    font = load_regular(base_path)
    overlay(font, TTFont(symbols_path), prefix='nf')
    pixel_powerline(font)
    set_family_name(font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    font.save(out_path)
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv))
