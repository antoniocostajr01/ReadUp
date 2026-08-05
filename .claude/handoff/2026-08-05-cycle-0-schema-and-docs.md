# Cycle 0 — Schema and documentation structure

**Date:** 2026-08-05
**Plan:** [`.claude/plans/2026-08-05-cycle-0-schema-and-docs.md`](../plans/2026-08-05-cycle-0-schema-and-docs.md)

## What shipped

Two nullable columns on `Book` (`isbn`, `coverImage`) and the `.claude/`
documentation structure.

## Files touched

**ReadUpBackend** (`4c2eb08`)
- `prisma/schema.prisma` — added `isbn` and `coverImage` to `model Book`.
- `prisma/migrations/20260805134652_add_book_isbn_and_cover/migration.sql` — generated.

**ReadUp** (`b0933a6`)
- `.claude/handoff/README.md` — handoff format.
- `.claude/handoff/2026-08-05-cycle-0-schema-and-docs.md` — this file.

## Decisions made during implementation

- Migration generated with `--create-only` and applied with `migrate deploy`,
  not `migrate dev`: `DATABASE_URL` points at the production Supabase database
  and `migrate dev` can offer to reset it.

## What was verified

Generated SQL, reviewed before it was applied:

```sql
-- AlterTable
ALTER TABLE "Book" ADD COLUMN     "coverImage" TEXT,
ADD COLUMN     "isbn" TEXT;
```

Additive only — two nullable columns on one table, no `DROP`, no `ALTER COLUMN`,
no other table touched.

```
$ npx prisma migrate status
Datasource "db": PostgreSQL database "postgres", schema "public" at "aws-1-us-east-2.pooler.supabase.com:5432"

6 migrations found in prisma/migrations

Database schema is up to date!
```

`npx tsc --noEmit` passed with no errors after `prisma generate`.

The migration was applied to the production Supabase database with
`prisma migrate deploy`, as the plan specified. This was verified independently
after the fact, not just reported: the SQL above was re-read from the committed
migration file and the status re-run from the controlling session.

## Open items

- Nothing writes to either column yet. `coverImage` is filled in cycle 2,
  `isbn` in cycle 3.
