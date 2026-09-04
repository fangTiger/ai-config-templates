# Issue tracker: OpenSpec

> 本文件由 mps profile 安装（`switch-plugin.sh mps`）。
> 它是 `/setup-matt-pocock-skills` Section A 的 **Other** 选项产物——用自定义 workflow
> 描述替代 GitHub / GitLab / Local markdown 三种内置 tracker。
> **不要重跑 `/setup-matt-pocock-skills` 覆盖本文件**；如需重跑，跑完后用 `switch-plugin.sh mps` 恢复。

This repo does **not** use an external issue tracker, and does **not** use `.scratch/`.
Specs and tickets live in **OpenSpec**, under `openspec/`. `openspec/specs/` is the single
source of truth for current system capabilities; `openspec/changes/` holds in-flight work.

## Conventions

- One change per directory: `openspec/changes/<change-id>/`
- `<change-id>` is verb-led and kebab-case, e.g. `add-user-export`, `fix-token-refresh`
- The spec is split across:
  - `openspec/changes/<change-id>/proposal.md` — Why / What Changes / Impact / Acceptance Criteria / Out of Scope
  - `openspec/changes/<change-id>/specs/<capability>/spec.md` — requirement deltas
    (`## ADDED|MODIFIED|REMOVED Requirements`, each with at least one `#### Scenario:`)
  - `openspec/changes/<change-id>/design.md` — technical decisions, when the change spans
    systems, introduces a pattern, or needs a trade-off record
- Tickets are entries in `openspec/changes/<change-id>/tasks.md`
- Triage state is the checkbox on each ticket: `- [ ]` open, `- [x]` done
- Comments and conversation history append under a `## 实测记录` heading at the bottom of `tasks.md`

## Ticket shape: one file per ticket does not apply here

Skills that say **"one file per ticket, never a single combined file"** are describing the
`.scratch/` local-markdown layout. That constraint exists to give each ticket a stable path
and an independent status line. **In OpenSpec both properties are carried by `tasks.md` itself**,
so the constraint is satisfied without splitting files:

- **Stable identity** → the numbered task id (`3.2`), not a filename
- **Independent status** → the per-line checkbox, not a per-file `Status:` line
- **Blocking edges** → a `依赖: 3.1` note on the ticket line, or ordering (blockers first)

Therefore: write tickets as numbered entries in the single `tasks.md`. **Do not create
`openspec/changes/<id>/issues/`, and do not create `.scratch/`.**

Each ticket line carries: the file path it touches, the code change in one clause, and a
verification command. Granularity target is 2–5 minutes per ticket.

## When a skill says "publish to the issue tracker"

Write to the OpenSpec change directory. Never call `gh issue create`, `glab issue create`,
or any Linear/Jira API. Specifically:

- **A spec** → `openspec/changes/<change-id>/proposal.md` plus the spec deltas under
  `openspec/changes/<change-id>/specs/<capability>/spec.md`.
  Create the directory if needed. Then run `openspec validate <change-id> --strict --no-interactive`.
- **Tickets** → append numbered entries to `openspec/changes/<change-id>/tasks.md`.
- **A wayfinding map** → `openspec/changes/<change-id>/design.md` (see below).

After publishing a spec, **stop and wait for user approval** before implementing.
Publishing is not approval.

## When a skill says "fetch the relevant ticket"

Read `openspec/changes/<change-id>/tasks.md` and take the referenced numbered entry.
Run `openspec list` to enumerate in-flight changes and `openspec list --specs` to see
current capabilities. The user will normally pass the change-id and task number directly.

## When a skill says "apply the `ready-for-agent` triage label"

There are no labels. A ticket is agent-grabbable when it is unchecked (`- [ ]`) and its
listed blockers are checked. Do not attempt to create, apply, or read labels.

## Wayfinding operations

Used by `/wayfinder`. The map and its child tickets both live in the change directory.

- **Map**: `openspec/changes/<effort>/design.md` — carries the Notes / Decisions-so-far / Fog body
  under a `## Wayfinding` heading, alongside the normal design decisions
- **Child ticket**: a numbered entry under `## Wayfinding Tickets` in the same `design.md`,
  with the question in the body. Record type inline as `Type: research|prototype|grilling|task`
- **Blocking**: a `依赖: NN` note on the ticket line; unblocked when every listed ticket is resolved
- **Frontier**: scan `## Wayfinding Tickets` for entries that are open, unblocked, and unclaimed;
  lowest number wins
- **Claim**: mark the entry `Status: claimed` and save before any work
- **Resolve**: append the answer under the ticket, mark `Status: resolved`, then append a
  context pointer to Decisions-so-far in the map body

## Archival

When a change is fully implemented, verified, and integrated, run `/openspec:archive`.
That merges the spec deltas into `openspec/specs/<capability>/spec.md` and moves the change
directory to `openspec/changes/archive/YYYY-MM-DD-<change-id>/`.
