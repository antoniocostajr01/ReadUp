# Cycle 0 — Schema and documentation structure

**Date:** 2026-08-05
**Plan:** [`.claude/plans/2026-08-05-cycle-0-schema-and-docs.md`](../plans/2026-08-05-cycle-0-schema-and-docs.md)

## What shipped

Two nullable columns on `Book` (`isbn`, `coverImage`) and the `.claude/`
documentation structure.

## Files touched

**ReadUpBackend** (`<pending: backend commit>`)
- `prisma/schema.prisma` — added `isbn` and `coverImage` to `model Book`.
- `prisma/migrations/<timestamp>_add_book_isbn_and_cover/migration.sql` — generated.

**ReadUp** (`<pending: this commit>`)
- `.claude/handoff/README.md` — handoff format.
- `.claude/handoff/2026-08-05-cycle-0-schema-and-docs.md` — this file.

## Decisions made during implementation

- Migration generated with `--create-only` and applied with `migrate deploy`,
  not `migrate dev`: `DATABASE_URL` points at the production Supabase database
  and `migrate dev` can offer to reset it.

## What was verified

```
<pending: see task-1-report.md>
```

## Open items

- Nothing writes to either column yet. `coverImage` is filled in cycle 2,
  `isbn` in cycle 3.
