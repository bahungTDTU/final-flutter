# Repository guardrails —07/10/2026 Asia/Saigon

Base50f204a68f2b28c449311e4cf99bc8af893900c5. User authorized ruleset creation and branch-only
workflow; new changes on codex/repository-guardrails, not master. No merge, force, bypass,
deployment/release or paid-plan change in this setup. Git author/committer remain Bahung.

Inventory through real authenticated REST API: public repo, default master, Actions enabled,
admin caller, two collaborators with write rights, initial rulesets empty/master not protected.
Credential obtained from existing Git credential manager only in memory; no values logged.

apply_ruleset.py in ignored tmp created/verified ruleset24651991. ruleset.json is actual GET
response, effective-master.json contains active rules for master; verification.json records
Active/no bypass/master protected/feature branch unrestricted. Did not attempt an unauthorized
push/delete to master to "test" protection. API effective policy is the enforcement evidence.

Template and workflow use exact same3 check names, expected source GitHub Actions(app15368),
strict base, PR/1 peer approval/last push approval/stale-dismiss/resolve threads, delete/force
blocks and merge commits. Repo still requires real approval; no reviewer message or forged
approval/contribution. Policy copies in AGENTS/README/BRANCH_WORKFLOW/GITHUB_PUBLISH.

Workflow contains no skipped jobs or path filters, read-only contents permission, timeouts,
latest-run cancellation and pinned action SHAs fetched from publisher tag refs. Flutter3.47.1,
Python3.12/28 existing pinned backend dependencies/Java21 match project. Package version
availability checked on official PyPI. Flutter release manifest lookup returned404 locally;
no version downgrade/mirror or artificial green status was substituted. Hosted CI bootstrap
is verified through the PR/Actions run, not inferred from YAML or local SDK.

Local JSON policy validated and README/Readme byte identity preserved; PyYAML unavailable in
venv, so YAML parsing/running is delegated to actual GitHub Actions. No app code changed;
earlier188Flutter/94backend source tests remain a historical local gate, not a new hosted result.

CI outcome is intentionally not claimed in this pre-push artifact. Current PR/Actions show
actual check status; run responses/logs are collected in ignored tmp for final verification.
If CI fails, keep PR blocked and diagnose rather than relax rules. This branch is not merged
without complete checks and valid peer review. Public ruleset view:
https://github.com/bahungTDTU/final-flutter/rules/24651991
