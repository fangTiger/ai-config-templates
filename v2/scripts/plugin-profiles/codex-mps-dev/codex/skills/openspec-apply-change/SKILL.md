---
name: openspec-apply-change
description: Implement tasks from an OpenSpec change. Use when the user wants to start implementing, continue implementation, or work through tasks.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.2.0"
---

Implement tasks from an OpenSpec change.

If `.claude/session-state.md` exists, treat it as the active codex-dev handoff state unless the user explicitly overrides it.

## Mode Detection

- **Orchestrated codex-dev mode**: `.claude/session-state.md` exists, or the prompt / developer-instructions include handoff markers such as task-by-task execution, `FileAllowlist`, `GitBaseline`, or `Executor: Codex`. In this mode Codex is the implementer only.
- **Standalone Codex mode**: no session-state and no handoff markers. In this mode Codex may own the workflow end-to-end: clarify, update proposal/specs, implement, verify, and suggest archive.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists
   - If ambiguous, run `openspec list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>" and how to override (e.g., `/opsx:apply <other>`).

2. **Check status to understand the schema**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - Which artifact contains the tasks (typically "tasks" for spec-driven, check status for others)

3. **Get apply instructions**

   ```bash
   openspec instructions apply --change "<name>" --json
   ```

   This returns:
   - Context file paths (varies by schema - could be proposal/specs/design/tasks or spec/tests/implementation/docs)
   - Progress (total, complete, remaining)
   - Task list with status
   - Dynamic instruction based on current state

   **Handle states:**
   - If `state: "blocked"` (missing artifacts): show message; in standalone mode suggest using `openspec-propose`, in orchestrated mode pause and hand back
   - If `state: "all_done"`: congratulate, suggest archive
   - Otherwise: proceed to implementation

4. **Read context files**

   Read the files listed in `contextFiles` from the apply instructions output.
   The files depend on the schema being used:
   - **spec-driven**: proposal, specs, design, tasks
   - Other schemas: follow the contextFiles from CLI output

   If `.claude/session-state.md` exists, also read it to recover:
   - active task number
   - `FileAllowlist`
   - `GitBaseline`
   - completed vs pending tasks

5. **Show current progress**

   Display:
   - Schema being used
   - Progress: "N/M tasks complete"
   - Remaining tasks overview
   - Dynamic instruction from CLI
   - If present, the active codex-dev task and file allowlist summary from session state

6. **Implement tasks (loop until done or blocked)**

   For each pending task:
   - If the task is explicitly assigned to another executor (`Executor: Claude` / `Executor: Gemini`), stop and hand control back instead of implementing
   - If the user explicitly asked for Claude to directly fix a small issue, stop and hand control back instead of implementing
   - Show which task is being worked on
   - If implementing under codex-dev, stay within the `FileAllowlist` from `.claude/session-state.md`
   - Use `test-driven-development`: write the failing test first, run it and confirm RED, then implement the minimum code for GREEN, then refactor
   - Keep changes minimal and focused
   - Run the task-specific verification command before updating task status
   - Mark task complete in the tasks file: `- [ ]` → `- [x]`
   - Continue to next task

   **Pause if:**
   - Task is unclear → ask for clarification
   - Implementation reveals a design issue → suggest updating artifacts
   - Error or blocker encountered → report and wait for guidance
   - Required edit would exceed the session `FileAllowlist`
   - The next task is not assigned to Codex
   - User interrupts

7. **On completion or pause, show status**

   Display:
   - Tasks completed this session
   - Overall progress: "N/M tasks complete"
   - RED/GREEN/verification evidence for each completed Codex task
   - If all done: suggest archive
   - If paused: explain why and wait for guidance

**Output During Implementation**

```
## Implementing: <change-name> (schema: <schema-name>)

Working on task 3/7: <task description>
[...implementation happening...]
RED: <test command> -> expected failure confirmed
GREEN: <test command> -> pass confirmed
✓ Task complete

Working on task 4/7: <task description>
[...implementation happening...]
✓ Task complete
```

**Output On Completion**

```
## Implementation Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 7/7 tasks complete ✓

### Completed This Session
- [x] Task 1
- [x] Task 2
...

### Evidence
- Task 1: RED `<command>` / GREEN `<command>` / VERIFY `<command>`
- Task 2: RED `<command>` / GREEN `<command>` / VERIFY `<command>`

All tasks complete! Ready to archive this change.
```

**Output On Pause (Issue Encountered)**

```
## Implementation Paused

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 4/7 tasks complete

### Issue Encountered
<description of the issue>

### Why Execution Stopped
- Task assigned to Claude/Gemini, or
- User explicitly requested Claude-only small fix, or
- Required edits exceeded file allowlist, or
- Normal blocker/ambiguity

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
```

**Guardrails**
- Keep going through tasks until done or blocked
- Always read context files before starting (from the apply instructions output)
- If `.claude/session-state.md` exists, treat it as the source of truth for current task and allowed file scope
- In standalone mode, if no handoff markers exist, you may continue the full workflow instead of waiting for Claude orchestration
- Respect `Executor` assignment when present; do not implement Claude/Gemini tasks
- If the request is explicitly a Claude-only small fix, stop and hand back instead of implementing
- Use `test-driven-development` for each implemented task
- Use `verification-before-completion` before claiming a task or change is done
- If task is ambiguous, pause and ask before implementing
- If implementation reveals issues, pause and suggest artifact updates
- Keep code changes minimal and scoped to each task
- Update task checkbox immediately after completing each task
- Pause on errors, blockers, or unclear requirements - don't guess
- Pause on file-allowlist conflicts instead of editing around them
- Use contextFiles from CLI output, don't assume specific file names

**Fluid Workflow Integration**

This skill supports the "actions on a change" model:

- **Can be invoked anytime**: Before all artifacts are done (if tasks exist), after partial implementation, interleaved with other actions
- **Allows artifact updates**: If implementation reveals design issues, suggest updating artifacts - not phase-locked, work fluidly
