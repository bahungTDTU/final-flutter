"""Measure used UI foreground/background pairs; not a whole-screen WCAG audit."""
import json
from pathlib import Path


def luminance(hex_value):
    rgb = [int(hex_value[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    return sum(a * b for a, b in zip(linear, (.2126, .7152, .0722)))


pairs = {
    'light text/surface': ('17251E', 'FFFFFF', 4.5),
    'light text/canvas': ('17251E', 'F7F8F5', 4.5),
    'light muted/surface': ('52645A', 'FFFFFF', 4.5),
    'light muted/secondary': ('52645A', 'EFF3EF', 4.5),
    'light button': ('FFFFFF', '176B57', 4.5),
    'light focus/canvas': ('176B57', 'F7F8F5', 3),
    'light control outline/surface': ('687E70', 'FFFFFF', 3),
    'dark text/surface': ('E6EEE8', '1A2320', 4.5),
    'dark text/canvas': ('E6EEE8', '111816', 4.5),
    'dark muted/surface': ('AFBEB4', '1A2320', 4.5),
    'dark muted/secondary': ('AFBEB4', '24312B', 4.5),
    'dark button': ('073B2D', '83D8B8', 4.5),
    'dark focus/canvas': ('83D8B8', '111816', 3),
    'dark control outline/surface': ('859C8E', '1A2320', 3),
}
results = []
for name, (foreground, background, minimum) in pairs.items():
    hi, lo = sorted((luminance(foreground), luminance(background)), reverse=True)
    ratio = (hi + .05) / (lo + .05)
    results.append(dict(pair=name, foreground=foreground, background=background,
                        ratio=round(ratio, 2), minimum=minimum, passed=ratio >= minimum))
target = Path('evidence/2026-10-01-ui/contrast.json')
target.write_text(json.dumps(results, indent=2), encoding='utf-8')
assert all(r['passed'] for r in results), results
print(f'{len(results)} used color pairs: PASS. Decorative outline not a control/focus boundary.')
