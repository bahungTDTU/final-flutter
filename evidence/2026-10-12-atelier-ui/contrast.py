"""Representative semantic pairs; not a full rendered WCAG audit."""
import json
def luminance(value):
    channels = [int(value[i:i+2], 16) / 255 for i in (0, 2, 4)]
    linear = [v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in channels]
    return sum(a*b for a,b in zip(linear, (.2126,.7152,.0722)))
pairs = {
    'light text / paper': ('272b25','fcfaf5'),
    'light muted / high container': ('555b51','d8dacb'),
    'dark text / surface': ('f4f0e6','242822'),
    'dark muted / high container': ('c4c5b8','42493b'),
    'primary light action': ('ffffff','242622'),
    'primary dark action': ('302919','d7b87f'),
    'sidebar muted / warm panel': ('555b51','eeeadf'),
    'white / auth endpoint': ('ffffff','536453'),
    'selected creation action': ('293b31','e5e8dd'),
}
ratios={}
for name,(foreground,background) in pairs.items():
    hi,lo=sorted((luminance(foreground),luminance(background)),reverse=True)
    ratio=(hi+.05)/(lo+.05)
    assert ratio>=4.5,(name,ratio)
    ratios[name]=round(ratio,2)
print(json.dumps({'result':'PASS','minimum':min(ratios.values()),'ratios':ratios},indent=2))
