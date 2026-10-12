"""Static token pairs only; not an automated WCAG audit of rendered gradients."""
import json

def luminance(value):
    channels = [int(value[index:index + 2], 16) / 255 for index in (0, 2, 4)]
    linear = [channel / 12.92 if channel <= .04045 else ((channel + .055) / 1.055) ** 2.4
              for channel in channels]
    return sum(a * b for a, b in zip(linear, (.2126, .7152, .0722)))

pairs = {
    'light body / surface': ('202b44', 'fcfdff'),
    'light secondary text / high surface': ('52617b', 'dfe7f4'),
    'dark body / surface': ('f0f3fc', '1c2436'),
    'dark secondary text / high surface': ('b8c5dc', '384760'),
    'light primary button': ('ffffff', '5540b7'),
    'dark primary button': ('251850', 'c8bdff'),
    'sidebar muted / lower gradient': ('ccd3f2', '272454'),
    **{f'white / header endpoint {color}': ('ffffff', color)
       for color in ('5540b7', '275c96', '146779', '35265f', '253d68', '164555')},
}
ratios = {}
for name, (foreground, background) in pairs.items():
    light, dark = sorted((luminance(foreground), luminance(background)), reverse=True)
    ratio = (light + .05) / (dark + .05)
    assert ratio >= 4.5, (name, ratio)
    ratios[name] = round(ratio, 2)
print(json.dumps({'result': 'PASS', 'minimum': min(ratios.values()), 'ratios': ratios}, indent=2))
