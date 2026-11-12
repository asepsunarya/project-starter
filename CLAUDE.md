# Project: [NAMA PROJECT]

<!--
  Dari project-starter (claude-starter + replica-starter + watermarks-starter).
  Isi bagian dalam [kurung], hapus yang tidak relevan, dan jaga file ini
  tetap pendek. Workflow panjang ada di .claude/skills/, checklist bersama
  ada di .claude/references/.
-->

Rules file for AI coding agents working in this repository. It is loaded into
every session, so keep it short and current. Long workflows live in
`.claude/skills/`; shared checklists live in `.claude/references/`.

## Tech Stack

- [Frontend: e.g. Next.js 15, React 19, TypeScript 5, Tailwind CSS 4]
- [Backend: e.g. Node 22, Fastify, PostgreSQL 16, Prisma]
- [Tooling: e.g. pnpm, Vitest, Playwright, ESLint, Prettier]

## Commands

| Task            | Command                                   |
|-----------------|-------------------------------------------|
| Install         | `[pnpm install]`                          |
| Dev server      | `[pnpm dev]`                              |
| Build           | `[pnpm build]`                            |
| Test (all)      | `[pnpm test]`                             |
| Test (one file) | `[pnpm test -- path/to/file.test.ts]`     |
| Lint / format   | `[pnpm lint]` / `[pnpm format]`           |
| Type check      | `[pnpm typecheck]`                        |

Starter tooling, already working (`make help` lists everything):

| Task                         | Command                                  |
|------------------------------|------------------------------------------|
| Tool tests                   | `make test`                              |
| Parity score vs original     | `make parity`                            |
| Leftover original branding   | `make sweep AVOID='Original Name'`       |
| Watermarks service           | `make serve` (or `make up` for Docker)   |
| Inspect / clean a file       | `make inspect FILE=x` / `make clean FILE=x` |

Run the relevant checks before claiming a task is done. "Seems right" is not evidence.

## Project Structure

```
src/
  [app/         → routes / pages]
  [components/  → UI components]
  [lib/         → shared utilities, validation, errors]
  [server/      → services, data access]
tests/          → [or colocated: Foo.ts → Foo.test.ts]
  replica/      → starter: unit tests for the Replica tools
  watermarks/   → starter: unit tests for the Watermarks service
replica/        → Replica workspace: recon, features.csv, design tokens, launch
service/        → Watermarks cleaning engine + HTTP server (vendored)
config/         → Watermarks rewrite strategy
work/in, out    → files to clean and their results (not committed)
docs/           → ADRs (docs/adr/), specs, ideas
tasks/          → tasks/plan.md and tasks/todo.md written by /plan
```

## Code Conventions

- [Named exports; no default exports]
- [Functional components with hooks; no class components]
- [Colocate tests next to source: `Button.tsx` → `Button.test.tsx`]
- [Validate input at the boundary with Zod; throw `AppError`, never raw errors]
- [Reuse helpers in `src/lib/` before writing new ones]
- Code reveals intent through names and structure. No dead code, no debug output, no commented-out blocks.

## Boundaries

**Always**
- Read the file (and its tests) before editing it; copy an existing pattern instead of inventing one.
- Run tests, lint, and type check before committing.
- Keep changes scoped to the task. Touch only what you were asked to touch.

**Ask first**
- Database schema or migration changes
- New dependencies (state the size and the reason)
- Changes to auth, permissions, payments, or anything irreversible
- Deleting code that "seems unused"

**Never**
- Commit secrets or `.env*` files
- Silence failing tests, lower thresholds, or add suppressions to get green
- Force-push to shared branches
- Invent requirements the spec does not cover: stop and ask

## How to Work

These behaviours apply at all times (see the `using-agent-skills` skill):

1. **Surface assumptions** before non-trivial work: list them and ask for correction.
2. **Manage confusion.** When the spec and the code disagree, stop and ask. Do not guess.
3. **Push back** when an approach has a concrete downside; propose an alternative, then accept the decision.
4. **Prefer the boring solution.** If 100 lines would do, do not write 1000.
5. **Scope discipline.** No drive-by refactors; never remove things you do not understand.
6. **Verify, do not assume.** Every task ends with evidence: test output, build result, runtime check.

For multi-step work, emit a short plan first and proceed unless redirected.

## Workflow

Skills in `.claude/skills/` activate automatically from their descriptions.
The slash commands are the entry points:

| Phase       | Command                      | Skill(s) and artifacts                                              |
|-------------|------------------------------|---------------------------------------------------------------------|
| Define      | `/spec`                      | spec-driven-development → `SPEC.md`                                 |
| Quality bar | `/constraints`               | constraint-driven-development → `CONSTRAINTS.md`                    |
| Plan        | `/plan`                      | planning-and-task-breakdown → `tasks/plan.md`, `tasks/todo.md`      |
| Build       | `/build` or `/build auto`    | incremental-implementation + test-driven-development                |
| Verify      | `/test`                      | test-driven-development (Prove-It pattern for bugs)                 |
| Review      | `/review`, `/code-simplify`  | code-review-and-quality, code-simplification                        |
| Ship        | `/ship`                      | shipping-and-launch (fans out to code-reviewer, security-auditor, test-engineer) |
| Perf audit  | `/webperf`                   | web-performance-auditor subagent (web apps only; single persona, no fan-out) |

Typical paths:
- New feature: `/spec` → `/plan` → `/build` (repeat per task) → `/review` → `/ship`
- Bug fix: debugging-and-error-recovery → `/test` (failing test first) → `/review`
- Unclear request: interview-me or idea-refine before `/spec`

Specialist subagents live in `.claude/agents/`. They never call each other;
the user or a slash command does the orchestration.

If `CONSTRAINTS.md` exists, read it before writing code and never weaken it to make a change pass.

## Product workflow: Replica

Use the `/replica-*` skills to rebuild what an existing app **does**:

```
recon -> architect -> design -> build -> backend -> test -> diff -> entrepreneur -> brand -> launch -> deploy
```

Each skill reads what the previous one wrote under `replica/`. App code goes
in the project root (`app/` or `src/`), decided during `/replica-architect`.
During `/replica-build`, the Boundaries, How to Work and Definition of Done in
this file still apply.

Non-negotiable:
- Rebuild **functions and flows**, never the original's code, logo, copy or content. Clean-room.
- Public sources and the user's own accounts only. No scraping, no reading JS bundles or private APIs.
- Screenshots in `replica/screens/` are reference only and never ship.
- `make sweep AVOID='Original Name'` must be clean before deploy.

## Content provenance: Watermarks

| Skill | Needs the service? |
|---|---|
| `/remove-ai-marks` | Yes. Check `/health` on `WATERMARKS_SERVICE_URL` (default `http://127.0.0.1:8765`); if it is down, stop and tell the user. Do not run the cleaning scripts locally instead. |
| `/clean-user-facing-text` | No, self-contained. |

A PostToolUse hook in `.claude/settings.json` runs
`service/scripts/hook_written_file.py --mode check` on every Write/Edit. It
only reports marks; it does not change files unless switched to `--mode clean`
or `WATERMARKS_HOOK_MODE=clean`.

Non-negotiable:
- Only for content the user owns or is authorised to process. Refuse when the goal is hiding AI assistance where disclosure is required (academic, platform, regulation). See `.claude/skills/remove-ai-marks/references/ethics.md`.
- Never claim a result is "undetectable" or "human-written". Report verified removal (Unicode, metadata) separately from best-effort rewrites.
- When rewriting prose, never change code, commands, paths, numbers, quotes or mandatory disclosures.
- Do not clean files outside `work/` unless the user asks.

## Vendored starter files

`.claude/{skills,commands,agents,references,hooks}`, `service/` and
`tests/{replica,watermarks}/` are overwritten by `scripts/sync-starters.sh`.
Do not hand-edit them; put local customisation in this file or `.claude/rules/`.

## Definition of Done

A task is done only when its acceptance criteria are met **and** the standing
bar in `.claude/references/definition-of-done.md` holds: verified at runtime,
covered by a test that fails without the change and passes with it, no
regressions, lint and types clean, scoped to the task, and documented where
public behaviour changes.

## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`. The body explains *why*.
- One logical change per commit, ~100 lines target; split anything over ~1000.
- Keep refactors separate from behaviour changes.
- Commit only when the user asks, or when a command defines the commit step (`/build` commits once per task; `/ship` never commits).
- Branch names: `feature/<desc>`, `fix/<desc>`, `chore/<desc>`.

## Patterns

[Paste one short example of a well-written module in this project's style:
a component, a service, or a test. Agents copy what they see.]
