# Dashboard — interaction refinement, 14/10/2026

Extends MASTER.md and the existing Atelier tokens. Audience: students and small teams;
stack: Flutter Web/Android. Keep paper/obsidian/sage/brass, NotoSans, the desktop
masthead/right drawer, asymmetric pinned shelf, compact rail and phone navigation.

The user identifies the dashboard as the main source of lag. The explicitly requested
global ui-ux-pro-max skill was read. Local UX searches selected Reduced Motion,
Excessive Motion and Duration Timing; the Flutter search selected local rebuild scope,
paint isolation and profiling. No new dependency, external font or continuous animation.

- Keep the interactive card rectangle fixed. Animate its painted surface over 180ms,
  easeOutCubic: hover/focus lifts 2dp, press scales to .985. Popup controls keep their
  own gestures. Keyboard focus remains on the native InkWell.
- Draw the 2dp primary focus ring above the opaque body, without intercepting taps
  or adding semantics. Tab selection and Enter activation are tested in both themes.
- Use a restrained shadow: inactive blur6/offset2, active blur14/offset5; a .09 accent
  tint confirms press. The static body has a separate paint boundary. Shadow changes
  are design choices; this QA does not isolate their GPU cost.
- Respect disableAnimations: zero duration and no translation/scale. Never retain
  old private children in an exit animation.
- Connection updates refresh only the sync control. Profile, label, note, draft,
  conflict and relevant error changes still refresh the library.
- Keep only the mounted card's bounded visible excerpt; immediately replace it on
  content/ID/lock changes. Never add a full-text private cache or search index.
- Clear-all cancels the pending search timer before clearing query and filters.

Current acceptance and limitations: docs/DASHBOARD_MOTION_AND_PERFORMANCE.md and
evidence/2026-10-14-dashboard-polish/INDEX.md. Widget workload counts are not FPS.
