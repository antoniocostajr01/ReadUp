# Cycle 0 — Schema and Documentation Structure — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the two `Book` columns that cycles 2 and 3 depend on, and create the documentation structure the whole project will use.

**Architecture:** Two nullable columns via a Prisma migration applied with `migrate deploy` (never `migrate dev`, because `DATABASE_URL` points at the production Supabase database). Documentation folders under `.claude/`.

**Tech Stack:** Prisma 6, PostgreSQL (Supabase), Node 26.

**Spec:** [`.claude/specs/2026-08-05-book-search-and-entry-design.md`](../specs/2026-08-05-book-search-and-entry-design.md)

## Global Constraints

- All `.md` files in this project are written in **English**, including handoffs and plans.
- `DATABASE_URL` points at **production** (Supabase pooler). Never run `prisma migrate dev` or `prisma migrate reset` against it. Use `--create-only` to generate, then `migrate deploy` to apply.
- Both new columns must be **nullable**. Existing rows must not require a backfill.
- Backend repository: `/Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend`. App repository: `/Users/antoniocosta/Documents/Academy/ReadUp`.
- Profile photo is already implemented and its migration is already applied. Do not touch it.

---

### Task 1: Add `isbn` and `coverImage` to the Book model

**Files:**
- Modify: `ReadUpBackend/prisma/schema.prisma` (model `Book`)
- Create: `ReadUpBackend/prisma/migrations/<timestamp>_add_book_isbn_and_cover/migration.sql` (generated)

**Interfaces:**
- Consumes: nothing.
- Produces: `Book.isbn: string | null` and `Book.coverImage: string | null` in the Prisma client. Cycle 2 writes `coverImage`; cycle 3 writes `isbn`.

- [ ] **Step 1: Confirm the database has no pending drift**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx prisma migrate status
```

Expected: `Database schema is up to date!` and 5 migrations found. If it reports drift or pending migrations, **stop** and report — do not continue.

- [ ] **Step 2: Add the two fields to the schema**

In `prisma/schema.prisma`, inside `model Book`, add the two fields after `coverUrl`:

```prisma
model Book {
  id         String     @id @default(uuid())
  userId     String
  title      String
  author     String?
  totalPages Int
  details    String?
  coverUrl   String?
  isbn       String?
  coverImage String?    @db.Text
  status     BookStatus @default(reading)
  progress   Int        @default(0)
  createdAt  DateTime   @default(now())

  user User @relation(fields: [userId], references: [id])

  sessions ReadingSession[]
}
```

- [ ] **Step 3: Generate the migration without applying it**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx prisma migrate dev --name add_book_isbn_and_cover --create-only
```

`--create-only` writes the SQL file and does not touch the database.

- [ ] **Step 4: Read the generated SQL and verify it is additive**

Read `prisma/migrations/<timestamp>_add_book_isbn_and_cover/migration.sql`.

Expected content — two `ADD COLUMN` statements and nothing else:

```sql
-- AlterTable
ALTER TABLE "Book" ADD COLUMN     "coverImage" TEXT,
ADD COLUMN     "isbn" TEXT;
```

If the file contains `DROP`, `ALTER COLUMN`, or any statement touching another table, **stop** and report.

- [ ] **Step 5: Apply the migration to the database**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx prisma migrate deploy
```

Expected: `1 migration applied`.

- [ ] **Step 6: Verify the columns exist**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx prisma migrate status
```

Expected: `Database schema is up to date!` with 6 migrations found.

- [ ] **Step 7: Verify the Prisma client typechecks against the new fields**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx prisma generate && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add prisma/schema.prisma prisma/migrations
git commit -m "feat: add isbn and coverImage columns to Book"
```

---

### Task 2: Create the documentation structure

**Files:**
- Create: `ReadUp/.claude/plans/` (this file already lives here)
- Create: `ReadUp/.claude/handoff/2026-08-05-cycle-0-schema-and-docs.md`
- Create: `ReadUp/.claude/handoff/README.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the handoff format every later cycle follows.

- [ ] **Step 1: Write the handoff format guide**

Create `.claude/handoff/README.md`:

```markdown
# Handoffs

One file per development cycle, named `YYYY-MM-DD-cycle-N-<topic>.md`.

A handoff answers, for someone who was not there:

- **What shipped** — the deliverable, in one sentence.
- **Files touched** — grouped by repository, with what changed in each.
- **Decisions made during implementation** — anything decided while coding that
  the plan did not already specify, and why.
- **What was verified** — the commands run and their result. Not "tests pass" —
  the actual command and the actual output.
- **Open items** — what was deliberately left out, and what would trigger doing it.

Written in English. Commits are referenced by short SHA, with the repository
named, because this project spans two repositories.
```

- [ ] **Step 2: Write the cycle 0 handoff**

Create `.claude/handoff/2026-08-05-cycle-0-schema-and-docs.md`, filling in the real SHAs and the real command output from Task 1:

```markdown
# Cycle 0 — Schema and documentation structure

**Date:** 2026-08-05
**Plan:** [`.claude/plans/2026-08-05-cycle-0-schema-and-docs.md`](../plans/2026-08-05-cycle-0-schema-and-docs.md)

## What shipped

Two nullable columns on `Book` (`isbn`, `coverImage`) and the `.claude/`
documentation structure.

## Files touched

**ReadUpBackend** (`<short SHA>`)
- `prisma/schema.prisma` — added `isbn` and `coverImage` to `model Book`.
- `prisma/migrations/<timestamp>_add_book_isbn_and_cover/migration.sql` — generated.

**ReadUp** (`<short SHA>`)
- `.claude/handoff/README.md` — handoff format.
- `.claude/handoff/2026-08-05-cycle-0-schema-and-docs.md` — this file.

## Decisions made during implementation

- Migration generated with `--create-only` and applied with `migrate deploy`,
  not `migrate dev`: `DATABASE_URL` points at the production Supabase database
  and `migrate dev` can offer to reset it.

## What was verified

```
$ npx prisma migrate status
<paste the real output>
```

## Open items

- Nothing writes to either column yet. `coverImage` is filled in cycle 2,
  `isbn` in cycle 3.
```

- [ ] **Step 3: Verify the structure exists**

```bash
cd /Users/antoniocosta/Documents/Academy/ReadUp && ls -1 .claude/specs .claude/plans .claude/handoff
```

Expected: the spec, both plan files, and both handoff files.

- [ ] **Step 4: Commit**

```bash
cd /Users/antoniocosta/Documents/Academy/ReadUp
git add .claude/
git commit -m "docs: add cycle 0 handoff and handoff format guide"
```

---

## Done when

- `npx prisma migrate status` reports 6 migrations and a schema that is up to date.
- `npx tsc --noEmit` passes in the backend.
- `.claude/specs/`, `.claude/plans/` and `.claude/handoff/` all exist and are committed.
- No existing behavior changed — nothing reads or writes the new columns yet.
