# LabelManager — 14–15/10/2026

Inherit Deskbook/Atelier Master and bundled NotoSans; no new palette or dependencies.
One modal, max width640, max height720/90% available room. Keyboard inset outside
SafeArea; compact padding12 vs24. Header/search/result count/offline/error states and
lazy rows scroll together; fixed footer Wrap keeps Close/Sync/Add reachable.

Cards use surface/border tokens. Label text wraps naturally, only one48dp native menu
beside it. Conflict explanation/action are below the row; never a long trailing button.
Native focus/pressed semantics, no layout transforms, blur, repeated entrance animations.
Search is literal Unicode and account-scoped; empty catalogue and no-result messages differ.
Account/token gate removes private name/search/form and disables mutations after session change.

Skill queries: first UX result Z-index did not fit; retry Truncation long content matched.
Flutter lazy list rebuilds matched ListView.builder/avoid eager children. Adopt lazy
SliverList implementation in the real app, not an HTML template.

Validate real CRUD/server ACK plus unchanged note content; compact/landscape/keyboard inset/
large text/both themes/remote catalogue updates/account changes. Report mounted rows as
workload, not FPS. Native IME/screen readers/device frame profile need actual target evidence.
