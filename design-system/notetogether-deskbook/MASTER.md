# NoteTogether Deskbook — curated layout, 12/10/2026

Flutter Web/Android, student and small-team note library. The user requests a distinctive
layout and explicitly invokes the repository ui-ux-pro-max skill. This specification
extends the existing Editorial Atelier tokens; it changes information placement.

## Skill query and selection

The required design-system query, `creative notebook studio split workbench library`,
returned storytelling/brutalism, black palette, external fonts and GSAP. These are
not suitable for a productive Flutter notebook; the raw recommendation is not adopted.
A single retry, `Bento Grids --domain style`, returned bento-box-grid: varied regions,
negative space, accessible hierarchy, reduced motion and low rendering cost. Adopt
those principles in Flutter, not an HTML/CSS template. Flutter responsive stack data
supports LayoutBuilder; do not introduce GoRouter or replace existing routes.

## Spatial identity

- PC library: indexed destinations across a horizontal masthead; create/search/account
  remain visible. A central notebook title has a vertical bookmark. The 244dp tool
  drawer sits on the right and scrolls independently. No left sidebar on full desktop.
- Pinned notes retain the asymmetric 7:5 shelf and server order. The remaining library
  remains a lazy grid/list. No duplicate catalog, auto-rotating hero or promoted note.
- Full desk only when width >=1180, height >=700 and text scale <1.5. Short/narrow PC
  uses the navigation rail; phone uses bottom destinations and compact app bar.
- Phone: grid/list, quick label chips and full label filtering stay directly accessible.
  Workspace/quick-find move into the visible `Công cụ thư viện` menu.
- PC editor: one `Trang viết` document tab, formatting ribbon, notebook page, separately
  toggled contents drawer and information drawer. These toggles do not change the note.
  Phone retains a single scrollable page and bottom formatting controls.

## Tokens and interaction

Reuse bundled NotoSans, warm paper/obsidian/sage/brass light/dark semantic colors,
48dp touch targets and visible focus states. Navigation labels wrap within allocated
space; long title/body use natural height. No new packages, network fonts, continuous
animations, blurred backdrops or hover-only actions. Preserve reduced motion.

## Non-negotiable boundaries

Keep Home scroll/query/filters and editor controller/ID/base revision/selection across
theme and resize. Only public pin/shared booleans are visible for locked notes.
Never retain private content in an exit animation, title tab or drawer after grant loss.
UI state toggles must not generate content writes or alter sharing/protection payloads.

## Acceptance

Real interaction regression: desktop -> short rail -> phone -> desktop preserves query
and filters; phone tools open working routes; editor drawers preserve selection,
autosaved draft and frozen revision. Run existing privacy/large text/permission tests.
Chrome screenshots at desktop/tablet/phone/short window in light and dark; prove
autosave via isolated API roundtrip. Debug APK compile is not Android runtime acceptance.
Record current-source checks and hashes in a new evidence directory, keep prior snapshots.
