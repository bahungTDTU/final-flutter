# Palette selector —16/10/2026

User explicitly requests multiple UI colour combinations using ui-ux-pro-max.
This overrides the single-palette rule while retaining the Deskbook layout and NotoSans.
Master is not overwritten. Product: Flutter Web/Android notes for students/small teams.

Verified skill guidance: initial design-system query productivity notes refined theme palettes
returned a marketing pattern, not adopted. One retry, notes productivity themes --domain color,
returned Notes & Writing App (warm ink/amber on cream) and Productivity Tool (teal/action orange).
Separate UX contrast query confirmed4.5normal-text and no colour-only state; Flutter stack query
confirmed ThemeData and context-driven tokens. Keep existing navigation, no remote fonts/GSAP.

Curated families: Atelier, Ocean, Iris, Rose quartz, Amber, Jade forest. Stable IDs:
atelier/ocean/iris/rose/amber/forest. Light seeds:242622/205CAF/6640A6/9F3E68/875623/24634E.
Each has a coordinated canvas, surface ladder, primary/secondary/tertiary and dark counterpart.
Dark actions lighten accents; text and borders use high contrast semantic tokens.
Warnings/errors preserve semantic colour and icons. A note's explicit rich-text colour is data.

Picker: native outlined buttons; two columns>=440dp/text<150%, otherwise one. Decorative
70dp mini interface previews, readable labels/descriptions, check+2dp selected border and merged
selected semantics. No fixed tile height. Modal fixed header/close and scrollable gallery;
settings scrolls as a whole, light/dark toggle appears before gallery. Keyboard Tab/Enter/Escape.
Account/token guards; show local-write failure; durable commit before theme notification.

ThemeData cache bound12 by (enum,brightness), ThemeExtension interpolation, static canvas,
no per-frame shaders/blur or layout transforms. Preserve note controllers/base revision/selection,
query/filter/scroll. Locked privacy remains unchanged; previews contain only colour shapes.

Acceptance:308Flutter/147backend, all12themes normal text>=4.5 and outline>=3,
320px/text200% two locales/modes, real Web PC/tablet/phone/landscape, editor draft/HTTP ACK,
account prefs/reload/query/privacy, Web/APK debug compile. Native/FPS/provider/CI/release NOT RUN.
See docs/COLOR_PALETTES.md and evidence/2026-10-16-color-palettes/INDEX.md for scope.
