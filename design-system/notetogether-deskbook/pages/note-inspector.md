# Note inspector override — 13/10/2026

Inherit MASTER.md paper/obsidian/sage/brass semantic theme. This override refines the
existing editor drawer and protected reader; it does not rebrand the application.

## Structure

Information/status/pin/labels/edit; AI; attachment/refresh/share; owner protection.
Conflict recovery is a separate conditional section. Owner controls are absent for
viewer; private sections exist only while the reader gate permits the content.

## Components

- InspectorSection: surfaceContainerLowest, outlineVariant, radius12, padding12,
  titleSmall/700/1.35, decorative icon18 in28tile;16gap below header and between cards.
- InspectorAction: native FilledButton for primary edit, OutlinedButton otherwise;
  full width, minimum48height,12padding,8radius, fixed icon18+10gap, Expanded label
  aligned left. Natural height/reflow;8gap between targets. Error color only for delete.
- InspectorBadge: static text semantics; bodySmall/600/1.5,8×4padding,6radius,
  outlineVariant and surfaceContainerLow. Optional decorative icon16. Label wraps.
- Selectable labels retain FilterChip interaction and selected semantics.

No local hard-coded palette, fixed text height, ellipsis for essential actions,
scale animation, exit retention, new dependency or font download.

## Verification

Narrow228dp and200% text in light/dark; badge180dp; actual protected reader transitions
1536→375→844→375(scale2)→1536 retain editor identity and selection. Web1280×1000 both
themes,375×812 and844×390 dark. Owner edit/pin/dialogs and viewer controls; relock purge.
Evidence: evidence/2026-10-13-inspector-ui; native runtime/IME/FPS remains NOT RUN.
