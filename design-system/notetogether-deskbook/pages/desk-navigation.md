# Desktop navigation —14/10/2026

Focused override of MASTER.md. Keep the horizontal masthead and three destinations
in their existing order. Target: Flutter Web desktop, students and small teams.

The explicitly requested global ui-ux-pro-max skill was read. Verified UX matches:
Navigation/Active State and Typography/Contrast Readability. Flutter responsive
guidance applies to the existing constraints; routing-library and SDK-version
recommendations are outside this visual refinement.

- Replace decorative ordinals and the wide underline with a framed three-part
  navigation strip. Reuse surfaceContainerLow/outlineVariant; radius14, inset4/gap4.
- Use Material icons for notes, collaboration and AI. Titles are NotoSans14,
  weight600/700; semantic onSurface text for inactive items.
- Selected item: opaque primary background, onPrimary text/icon and a checkmark.
  Color is supplemented by the mark, weight and selected semantics.
- Each native TextButton has a minimum52dp height, padding12, radius10. Reserve
  the trailing check space in every item so changing selection keeps its hit bounds.
  Labels wrap naturally rather than being clipped.
- Hover/press use .06/.12 foreground overlays; keyboard focus has a2dp border.
  Native style transitions use the existing180ms token; reduced motion uses zero.
- Merge each button's selected flag/name/action into a single semantics node.
  Decorative icons are excluded. Retain native Tab/Enter behavior.
- Masthead vertical inset12 keeps the stronger navigation compact. The phone and
  short-window navigation still use the existing NavigationBar/NavigationRail.

No note/editor/sync/permission mutation, extra dependency, blur, repeating animation
or exit transition. Preserve Home query/filter/scroll when changing destinations
and resizing. Acceptance is recorded separately from dashboard-motion evidence.
