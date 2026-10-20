# Soft Studio — visual refinement, 20/10/2026

Extends MASTER.md and overrides the visual treatment of dashboard-motion,
desk-navigation and color-palettes. Keep the Deskbook information layout, bundled
NotoSans, all six account-scoped palettes and the separate desktop/phone editor.
The Master is unchanged. Stack: Flutter Web/Android; audience: students and teams.

## Verified skill selection

The design-system query `premium creative notebook workspace` returned marketing
storytelling, Liquid Glass, external fonts and refraction. Those do not fit the
existing notebook or its performance constraints; the raw recommendation is not
persisted. The single focused retry `Soft UI Evolution --domain style` returned
`soft-ui-evolution`: measured contrast, semantic pastels, restrained depth, visible
focus and reduced motion. Adopt those principles in Flutter. Stack query
`responsive theme animation --stack flutter` confirmed context-driven themes,
LayoutBuilder and independently defined light/dark modes.

## Visual rules

- Radius rhythm: controls 14dp, reading cards 20dp, panels 24dp, hero 28dp. Reuse native
  Material controls and their 48dp targets; focus rings stay visible.
- Heading panels blend opaque semantic primary/tertiary containers into the surface.
  Text keeps onSurface/onSurfaceVariant; verify composed background contrast 4.5:1.
- Static canvas gradient has a mild palette tint. A static vector notebook motif
  appears only when there is room; it has no semantics, hit target or private data.
- Navigation retains three buttons, checkmarks, keyboard behavior and selected
  semantics. Selected surfaces use primaryContainer/onPrimaryContainer.
- Creation buttons follow the current semantic primary/onPrimary pair.
- Cards retain fixed hit bounds, isolated preview painting, current hover/press
  feedback and immediate lock redaction. Reading content remains on opaque paper.
- The right tool drawer is a bounded, rounded panel with distinct icon surfaces;
  desktop writing retains the formatting ribbon, contents/info drawers and paper.
- On phones, at text scale<150%, quick labels use one horizontal scroll row. Keep
  the full filter 152dp wide and always visible. Large text wraps naturally instead.
  Prioritize selected IDs while keeping the quick choices in catalog order, so
  choosing a late chip does not move it out of the scroll viewport. Keep at most 6.
- Landscape height<500dp and content width>=480dp: heading/count, sync and creation
  share a compact row. In other rail/tablet layouts with room and text<150%, the creation control sits
  beside the heading. Narrow panes and larger text stack it below the heading.

## State and verification boundaries

No storage, ACL, API, schema, sync or dependency changes. Preserve editor identity,
selection/draft/frozen revision; Home query/filter/scroll; palette IDs and privacy.
No blur, repeating decoration, network font or exit animation retaining private data.
Actual runtime and build results belong in the new Soft Studio evidence directory;
existing evidence is read-only. A debug APK compile is not native or FPS acceptance.
