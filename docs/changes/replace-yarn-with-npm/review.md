# Review: replace-yarn-with-npm

## Round 1 — 2026-10-19T09:06Z — a99ee28 (codex)

No findings.

## Round 2 — 2026-10-19T09:30Z — a99ee28 (claude)

- [ ] Important: `package-lock.json` resolves `tailwindcss@4.3.3` (an auto-installed peer of `@herb-tools/tailwind-class-sorter`) that `yarn.lock` never contained; plan step 3 says a pair missing from `yarn.lock` stops the phase with a `Decision needed:` line, and adding dependencies is out of scope — `package-lock.json:437` → dismissed: Etienne accepted the npm-resolved dev-only peer on 2026-10-19
