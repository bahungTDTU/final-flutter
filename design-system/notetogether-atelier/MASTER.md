# NoteTogether — Editorial Atelier

Direction approved for implementation by the user's 12 October request: a distinct,
modern and refined notes product. Actual stack: Flutter Web/Android, bundled NotoSans.

## Skill decisions

Used `.agents/skills/ui-ux-pro-max/SKILL.md` and its Python search. The design-system
query `luxury editorial notes workspace` suggested a showcase/Brutalism template;
that layout was unsuitable for a functional notes app. A focused `Editorial Magazine`
style search supplied the relevant asymmetric grid, print hierarchy and restrained
rules. Keep those principles; no landing-page sections, font downloads or parallax.

## Tokens and surfaces

Warm paper #F4F1EA, reading panels #FCFAF5, writing page #FFFFFF, obsidian #272B25, sage #394A40,
brass #80602F. Dark canvas #171A17, dark surface #242822, ivory text #F4F0E6,
muted #C4C5B8 (dark) / #555B51 (light). Source of truth: `lib/ui/design_system.dart` and `prism.dart`.
Use semantic ColorScheme roles, opaque dialogs and visible 2px focus outlines.
Most controls radius 8, cards 12, desktop writing page 4. No blur or decorative loops.

## Layout

PC library: indexed left navigation, editorial title with CTA underneath, contrasting
count plate, search/filter controls, two pinned covers at 7:5 then lazy catalogue.
Locked covers stay neutral; first unlocked cover uses the opposite theme. Phones:
compact summary, top creation action, bottom navigation, single-column cards.
Large text uses natural card heights and stacked actions, preserving grid preference.
Desktop writer: outline / paper / inspector, folio rule and separate title/content;
phone writer retains its compact column and bottom toolbar. Auth uses a dark publication
panel and warm form. Management pages inherit the same reading and action tokens.

## Interaction and invariants

48dp primary targets, framework keyboard behavior, reduced motion, short existing
press/route transitions. Two eager cover widgets only; remaining items are slivers.
Do not rebuild controllers or change editor identity, selection, frozen revision,
Home filters or PageStorage when moving between desktop and mobile layouts.
No title/content/labels/date/share identity or count before unlock; pin and shared
boolean remain public. No animation retains private data after remote locking.

## Verification

Acceptance is recorded separately in `evidence/2026-10-12-atelier-ui/INDEX.md`.
Static contrast checks do not certify whole-app WCAG. Browser viewport checks do not
claim Android runtime, native IME, screen-reader or measured FPS acceptance.
