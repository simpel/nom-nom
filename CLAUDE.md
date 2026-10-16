@AGENTS.md

## Claude Code notes

- All project rules live in `AGENTS.md` (imported above). Edit them there, not here.
- **Design system first.** Before any iOS UI work, read `AGENTS.md` §0, `design-system/README.md` and the `design-system/components/<Name>/README.md` of every component you touch. Use the matching `Core/Components` type; never hand-roll one.
- **The design system is ours: change it.** When the app needs UI the design system has no component for, add it to the artifact first (README, preview, bundle, `index.d.ts`), re-vendor `design-system/`, then build the Swift counterpart. Never hand-edit the vendored snapshot, never keep a local gap list or interim component. Say in your reply what you added to the design system and why nothing fit.
- After UI changes, run `scripts/ds-lint.sh` and `scripts/ds-coverage.sh`. Both must be clean.
- **Branch from the current release.** Every branch starts from the newest unshipped `origin/release/*` and its PR targets it; if none is active, create the next `release/<x.y>` from `main` first (`AGENTS.md` §11).
- `AGENTS.md` §9 names Antigravity tools (`run_command`, `replace_file_content`, …). In Claude Code, use Bash, Edit, Write and Read.
