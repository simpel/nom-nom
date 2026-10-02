@AGENTS.md

## Claude Code notes

- All project rules live in `AGENTS.md` (imported above). Edit them there, not here.
- **Design system first.** Before any iOS UI work, read `AGENTS.md` §0, `design-system/README.md` and the `design-system/components/<Name>/README.md` of every component you touch. Use the matching `Core/Components` type; never hand-roll one.
- **Flag gaps out loud.** When the app needs UI the design system has no component for, add a `Core/Design/DS-GAPS.md` entry and say so in your reply: the component, why nothing in `design-system/components/` fits, and what the DS needs to decide.
- After UI changes, run `scripts/ds-lint.sh` and `scripts/ds-coverage.sh`. Both must be clean.
- `AGENTS.md` §9 names Antigravity tools (`run_command`, `replace_file_content`, …). In Claude Code, use Bash, Edit, Write and Read.
