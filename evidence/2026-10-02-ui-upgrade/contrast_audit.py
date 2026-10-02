"""Contrast measurement for verified explicit theme pairs, not a coverage test."""
import json
from datetime import datetime, timezone


def luminance(hex_color):
    values = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    values = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in values]
    return sum(v * weight for v, weight in zip(values, (.2126, .7152, .0722)))


# Explicit overrides reviewed against lib/ui/design_system.dart in this run.
pairs = [
    ('light primary container text', '154b39', 'e0f0e7', 4.5),
    ('dark primary container text', 'b4efd2', '204c3c', 4.5),
    ('light selected navigation text', '17251e', 'eaf1eb', 4.5),
    ('dark selected navigation text', 'e6eee8', '314137', 4.5),
    ('light surface text', '17251e', 'ffffff', 4.5),
    ('dark surface text', 'e6eee8', '1a2320', 4.5),
    ('light pill muted text', '52645a', 'eff3ef', 4.5),
    ('dark pill muted text', 'afbeb4', '24312b', 4.5),
    ('light input outline', '687e70', 'ffffff', 3.0),
    ('dark input outline', '859c8e', '1a2320', 3.0),
]
rows = []
for name, foreground, background, threshold in pairs:
    a, b = sorted([luminance(foreground), luminance(background)])
    ratio = (b + .05) / (a + .05)
    assert ratio >= threshold, (name, ratio)
    rows.append(dict(pair=name, foreground=foreground, background=background,
                     ratio=round(ratio, 3), threshold=threshold, passed=True))
print(json.dumps(dict(measured_at_utc=datetime.now(timezone.utc).isoformat(),
                     scope='10 explicit theme pairs; not all hover/error/SDK-generated states or a screen-reader audit',
                     results=rows), indent=2))
