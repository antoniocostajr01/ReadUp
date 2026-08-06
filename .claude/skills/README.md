# Skills used on this project

This project's development workflow leans on Claude Code's [Superpowers](https://github.com/obra/superpowers)
skill set. The skill definitions themselves are not project files — they live in the
Superpowers plugin and are shared across projects. This file only records which ones
this project's workflow uses, and when each applies here.

## Workflow skills, in the order they fire

1. **`superpowers:brainstorming`** — before any new feature. Explores the idea through
   one question at a time, proposes 2-3 approaches with a recommendation, and produces
   a design doc under `.claude/specs/`. Nothing is implemented until the user approves
   the design.
2. **`superpowers:writing-plans`** — turns an approved spec into a step-by-step
   implementation plan under `.claude/plans/`, broken into small TDD tasks with the
   exact code and test cases to write. Assumes zero prior context about the codebase.
3. **`superpowers:subagent-driven-development`** — executes a plan by dispatching one
   fresh subagent per task, reviewing each task's diff before moving to the next, and
   running a full-branch review at the end. Used for the backend work in cycle 1
   (Open Library search engine).
4. **`task-planner-orchestrator`** (project-local skill) — an alternative to the
   Superpowers execution flow: turns a request into a `TaskCreate` task list with a
   dependency graph, groups independent tasks into parallel waves, and dispatches
   Sonnet subagents per wave. Used when the user explicitly asks for parallel
   subagent execution.

## Why a design doc always comes first

Every cycle in `.claude/plans/` traces back to a spec in `.claude/specs/` that the user
read and approved before any code was written. That is `brainstorming`'s hard gate: no
implementation skill runs until a design exists and is approved. This matters on this
project specifically because search relevance and profile-photo storage both had
real trade-offs (API cost and coverage, payload size on `GET /books`) that were worth
deciding deliberately rather than discovering mid-implementation.

## Where the actual skill instructions live

Not in this repository. They are read fresh from the Superpowers plugin (and this
project's own `task-planner-orchestrator` skill) each time they are invoked, so this
file will drift out of sync with their exact instructions over time — treat it as an
index of what runs and why, not as a copy of how each skill works internally.
