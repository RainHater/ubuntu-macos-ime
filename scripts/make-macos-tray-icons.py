#!/usr/bin/env python3
"""Render macOS-like menu-bar 拼 / ABC icons for fcitx5-rime tray.

拼 = filled light squircle + dark glyph
ABC = outlined (unfilled) squircle frame + light glyph
"""
import base64
import io
from pathlib import Path

import cairo
import gi

gi.require_version('Pango', '1.0')
gi.require_version('PangoCairo', '1.0')
from gi.repository import Pango, PangoCairo

BASE = Path.home() / '.local/share/icons/hicolor'
SIZES = [16, 22, 24, 32, 36, 40, 48, 64, 96, 128]


def rounded_rect(cr, x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    cr.new_sub_path()
    cr.arc(x + w - r, y + r, r, -1.5708, 0)
    cr.arc(x + w - r, y + h - r, r, 0, 1.5708)
    cr.arc(x + r, y + h - r, r, 1.5708, 3.14159)
    cr.arc(x + r, y + r, r, 3.14159, 4.71239)
    cr.close_path()


def render_square(text, *, filled, size, font):
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    cr = cairo.Context(surface)
    cr.set_operator(cairo.OPERATOR_CLEAR)
    cr.paint()
    cr.set_operator(cairo.OPERATOR_OVER)

    inset = size * 0.10
    box_w = size - 2 * inset
    box_h = size - 2 * inset
    radius = size * 0.26

    if filled:
        # macOS CN: light filled squircle, dark glyph
        rounded_rect(cr, inset, inset, box_w, box_h, radius)
        cr.set_source_rgba(0.96, 0.96, 0.97, 1)
        cr.fill()
        cr.set_source_rgba(0.05, 0.05, 0.07, 1)
        pts = size * 0.34
        weight = 'Bold'
        limit = size * 0.62
    else:
        # macOS EN: outlined squircle frame (有框、无填充) + light glyph
        stroke = max(1.25, size * 0.065)
        # Keep stroke fully inside the canvas
        pad = stroke / 2
        rounded_rect(
            cr,
            inset + pad,
            inset + pad,
            box_w - stroke,
            box_h - stroke,
            max(1.0, radius - pad * 0.35),
        )
        cr.set_source_rgba(0.96, 0.96, 0.98, 1)
        cr.set_line_width(stroke)
        cr.set_line_join(cairo.LINE_JOIN_ROUND)
        cr.stroke()
        cr.set_source_rgba(0.98, 0.98, 0.99, 1)
        pts = size * 0.26 if len(text) >= 3 else size * 0.40
        weight = 'Medium'
        limit = size * 0.72

    layout = PangoCairo.create_layout(cr)
    layout.set_font_description(Pango.font_description_from_string(f'{font} {weight} {pts}'))
    layout.set_text(text, -1)
    _ink, logical = layout.get_pixel_extents()
    while (logical.width > limit or logical.height > limit) and pts > 7:
        pts -= 0.3
        layout.set_font_description(Pango.font_description_from_string(f'{font} {weight} {pts}'))
        _ink, logical = layout.get_pixel_extents()
    cr.move_to((size - logical.width) / 2, (size - logical.height) / 2 - size * 0.02)
    PangoCairo.show_layout(cr, layout)

    buf = io.BytesIO()
    surface.write_to_png(buf)
    return buf.getvalue()


def main():
    specs = [
        ('fcitx-rime', '拼', True, 'Noto Sans CJK SC'),
        ('fcitx-rime-im', '拼', True, 'Noto Sans CJK SC'),
        ('fcitx-rime-latin', 'ABC', False, 'Inter'),
    ]
    tmp = Path('/tmp/macos-tray-icons')
    for name, text, filled, font in specs:
        for size in SIZES:
            data = render_square(text, filled=filled, size=size, font=font)
            for base in (tmp, BASE):
                for ctx in ('status', 'apps'):
                    d = base / f'{size}x{size}' / ctx
                    d.mkdir(parents=True, exist_ok=True)
                    (d / f'{name}.png').write_bytes(data)
        data128 = render_square(text, filled=filled, size=128, font=font)
        (tmp / 'preview').mkdir(parents=True, exist_ok=True)
        (tmp / 'preview' / f'{name}.png').write_bytes(data128)
        b64 = base64.b64encode(data128).decode()
        svg = (
            '<?xml version="1.0"?>'
            '<svg xmlns="http://www.w3.org/2000/svg" '
            'xmlns:xlink="http://www.w3.org/1999/xlink" '
            'width="128" height="128" viewBox="0 0 128 128">'
            f'<image width="128" height="128" xlink:href="data:image/png;base64,{b64}"/>'
            '</svg>'
        )
        for base in (tmp, BASE):
            d = base / 'scalable' / 'apps'
            d.mkdir(parents=True, exist_ok=True)
            (d / f'{name}.svg').write_text(svg, encoding='utf-8')
        print('ok', name, 'filled' if filled else 'outline')
    print('icons installed under', BASE)


if __name__ == '__main__':
    main()
