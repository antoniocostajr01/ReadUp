# Cycle 2 — Unified Book Form Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One form (`BookFormView`) that both creates a book from scratch and edits an
existing one — with a user-supplied cover photo — reachable from the Library's `+`
menu and from a book's detail sheet.

**Architecture:** Backend gains two thin additions to the existing `Book` CRUD: the
`isbn`/`coverImage` fields flow through `CreateBookDTO`/`UpdateBookDTO` exactly like
every other optional field already does, and a new public `GET /books/:id/cover`
route serves the stored image so `BookCoverView`'s plain `AsyncImage` keeps working
unchanged. App-side, one `BookFormView` + `BookFormViewModel` pair serves both
`.create` and `.edit(Book)` modes; `LibraryStore` gains the two calls the form needs.

The spec's design describes three entry points into the form ("manual entry",
"post-import correction", "editing from BookDetailsSheet") but only two real UI
screens are needed: a book imported from search is a normal library book the instant
it's saved, so "correcting" it right after import and "editing" it a week later are
the same operation on the same screen. This plan builds `.create` (empty, reached
from Library's `+`) and `.edit(Book)` (prefilled, reached from a book's detail
sheet) — there is no separate "just imported, review before it's real" step.

**Tech Stack:** Same as cycle 1 — Node 26/TypeScript/Express/Prisma on the backend,
SwiftUI/`@Observable` on the app. No new dependencies on either side.

**Spec:** [`.claude/specs/2026-08-05-book-search-and-entry-design.md`](../specs/2026-08-05-book-search-and-entry-design.md)

## Global Constraints

- **Both repos, in order.** Backend tasks (1–2) land and are verified live before any
  app task starts — the app tasks call the endpoints backend Task 2 creates.
  Backend: `/Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend`, branch
  `feat/unified-book-form`, based on `main` (already contains cycle 1). App:
  `/Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp`, branch
  `feat/unified-book-form`, based on `main`.
- **`GET /books/:id/cover` is a public, unauthenticated route**, declared in
  `book.routes.ts` alongside `/search`, before `authMiddleware`. This is a deliberate
  choice, not an oversight: `BookCoverView` renders covers through a plain
  `AsyncImage(url:)`, which cannot attach an `Authorization` header, so an
  authenticated route would just show a broken image. Every other cover URL in this
  app (Google Books, Open Library thumbnails) is already a public URL — a book's `id`
  is a non-guessable UUID, so this keeps the same trust level. It returns 404 for a
  missing book or a book with no `coverImage`; it does not check ownership. If this
  trade-off is unacceptable later, the fix is a short-lived signed URL, not something
  to build speculatively now.
- **No test coverage added to `book.controller.ts`, `book.service.ts`, or
  `book.repository.ts`.** That whole layer has zero tests today — this plan follows
  that existing convention rather than introducing a new one mid-feature. It stays
  matched with `tsc --noEmit` and a live curl round-trip per backend task, the same
  way `POST /books` was verified before this cycle. `node:test` coverage under
  `src/services/search/` is untouched and keeps passing (36 tests).
- **No XCTest target exists in this project** (confirmed: zero test targets in
  `ReadUp.xcodeproj`). App tasks are verified by a clean build
  (`xcodebuild ... build`) plus a concrete simulator walkthrough per task — this plan
  does not invent a test target as a side effect of a form.
- **Reuse the existing image-compression code path**, not a new one: Profile.swift
  already resizes to 512px and compresses to JPEG at quality 0.7 for the avatar.
  Task 3 extracts it once so the form's cover picker uses the identical logic.
- **Reuse the existing localization scaffold.** `Localization+AddBook.swift` and its
  `addBook.*` keys in `Localizable.xcstrings` already exist, in English and
  Portuguese, unused anywhere. Task 5 wires them in rather than inventing new keys,
  and adds only the two genuinely missing ones (`isbnPlaceholder`, and the two
  Library-menu item labels).
- Code comments follow the existing codebase convention: **Portuguese**. `.md` files:
  **English**.

## File Structure

**Backend — modified only, nothing new:**

| File | Change |
|---|---|
| `prisma/schema.prisma` | none — `isbn`/`coverImage` already exist (cycle 0) |
| `src/dtos/book.dto.ts` | `isbn?`/`coverImage?` on `CreateBookDTO`/`UpdateBookDTO`; `BookResponseDTO` unchanged shape, `coverUrl` semantics extended |
| `src/repositories/book.repository.ts` | pass `isbn`/`coverImage` through on create/update |
| `src/services/book.service.ts` | size cap on `coverImage`; derive `coverUrl` from `coverImage` when present; new `getCover(id)` |
| `src/controllers/book.controller.ts` | build `baseUrl` from `req`, pass to service; new `getCover` handler |
| `src/routes/book.routes.ts` | new public `GET /:id/cover` |
| `src/server.ts` | `app.set('trust proxy', true)` so `req.protocol` is correct behind Render |

**App:**

| File | Change |
|---|---|
| `ReadUp/Extensions/UIImage+Compression.swift` | new — extracted from Profile.swift |
| `ReadUp/Views/Profile.swift` | use the extracted helper, no behavior change |
| `ReadUp/Models/Book.swift` | add `isbn: String?` |
| `ReadUp/Services/BookService.swift` | add `isbn`/`coverImage` to both payload structs |
| `ReadUp/Localizations/Localization+AddBook.swift` | add `.isbnPlaceholder` |
| `ReadUp/Localizations/Localization+Library.swift` | add two menu-item keys |
| `ReadUp/Localizations/Localization+BookDetails.swift` | add `.editBook` |
| `ReadUp/Localizable.xcstrings` | new keys, EN + PT-BR |
| `ReadUp/ViewModels/BookFormViewModel.swift` | new |
| `ReadUp/Views/BookFormView.swift` | new |
| `ReadUp/ViewModels/LibraryStore.swift` | new `createBook(from formValues)`, extend edit path |
| `ReadUp/Views/Library.swift` | `+` becomes a `Menu` (Search / Add Manually) |
| `ReadUp/Views/BookDetailsSheet.swift` | overflow menu gains "Edit" for `.library` source |

---

### Task 1: Persist `isbn` and `coverImage` on create/update

**Files:**
- Modify: `ReadUpBackend/src/dtos/book.dto.ts`
- Modify: `ReadUpBackend/src/repositories/book.repository.ts`
- Modify: `ReadUpBackend/src/services/book.service.ts`

**Interfaces:**
- Consumes: nothing new — `isbn`/`coverImage` columns already exist on `Book`
  (migration `20260805134652_add_book_isbn_and_cover`, cycle 0).
- Produces: `CreateBookDTO`/`UpdateBookDTO` accept `isbn?: string` and
  `coverImage?: string`. `BookService` throws `'Cover image is too large.'` past the
  cap. Used by Task 2 (cover derivation) and by the app's Task 6 (form save).

- [ ] **Step 1: Add the fields to both DTOs**

In `src/dtos/book.dto.ts`, add to both `CreateBookDTO` and `UpdateBookDTO`:

```ts
    isbn?: string;
    coverImage?: string;
```

Place them after `coverUrl` in each interface, matching the model's field order.

- [ ] **Step 2: Pass them through the repository**

In `src/repositories/book.repository.ts`, add to the `create` method's `data` object
(after `coverUrl: data.coverUrl,`):

```ts
                isbn: data.isbn,
                coverImage: data.coverImage,
```

`update` already spreads `data` directly into Prisma's `data` — no change needed
there, since `UpdateBookDTO` now includes the two fields and Prisma ignores
`undefined` values.

- [ ] **Step 3: Cap the size and wire it into create/update**

In `src/services/book.service.ts`, add near the top of the class, matching the
existing pattern in `src/services/user.service.ts`:

```ts
// Limite defensivo do tamanho da capa em base64 (~2MB). O app já comprime antes de enviar.
const MAX_COVER_IMAGE_LENGTH = 2_000_000;
```

(as a module-level constant, same placement style as `MAX_AVATAR_LENGTH` in
`user.service.ts` — outside the class, above it.)

Add a private validation method and call it from both `createBook` and `updateBook`:

```ts
    private validateCoverImage(coverImage?: string): void {
        if (coverImage !== undefined && coverImage.length > MAX_COVER_IMAGE_LENGTH) {
            throw new Error('Cover image is too large.');
        }
    }
```

```ts
    async createBook(data: CreateBookDTO, userId: string): Promise<BookResponseDTO> {
        this.validateCoverImage(data.coverImage);
        const book = await this.bookRepository.create(data, userId);
        return this.toResponseDTO(book);
    }
```

```ts
    async updateBook(id: string, userId: string, data: UpdateBookDTO): Promise<BookResponseDTO> {
        this.validateCoverImage(data.coverImage);
        await this.findAndAuthorize(id, userId);
        const updated = await this.bookRepository.update(id, data);
        return this.toResponseDTO(updated);
    }
```

- [ ] **Step 4: Typecheck**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 5: Live round-trip**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm run dev
```

In another shell, using a real JWT for a test user (or the token the app already has
from a logged-in session — check `KeychainHelper` output, or sign up a throwaway
account via `POST /auth/register` first):

```bash
TOKEN="<paste a valid JWT here>"
curl -s -X POST http://localhost:3000/books \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Teste Cycle 2","totalPages":100,"isbn":"9780000000000","coverImage":"'"$(printf 'not-a-real-jpeg' | base64)"'"}'
```

Expected: `201`, response JSON does not need to echo `isbn`/`coverImage` yet
(`BookResponseDTO` is untouched in this task — that's Task 2). Then:

```bash
curl -s http://localhost:3000/books -H "Authorization: Bearer $TOKEN" | grep -o '"title":"Teste Cycle 2"'
```

Expected: the book is there. Delete it afterward via `DELETE /books/<id>` to leave the
test database clean.

- [ ] **Step 6: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git checkout -b feat/unified-book-form
git add src/dtos/book.dto.ts src/repositories/book.repository.ts src/services/book.service.ts
git commit -m "feat: persist isbn and coverImage on Book create/update"
```

---

### Task 2: Serve the cover image and derive `coverUrl`

**Files:**
- Modify: `ReadUpBackend/src/server.ts`
- Modify: `ReadUpBackend/src/services/book.service.ts`
- Modify: `ReadUpBackend/src/controllers/book.controller.ts`
- Modify: `ReadUpBackend/src/routes/book.routes.ts`

**Interfaces:**
- Consumes: `MAX_COVER_IMAGE_LENGTH` pattern and `coverImage` field from Task 1.
- Produces: `GET /books/:id/cover` → raw JPEG bytes, 404 if absent.
  `BookResponseDTO.coverUrl` is `` `${baseUrl}/books/${id}/cover` `` when
  `coverImage` is set, else the stored `coverUrl` (search-imported books), else
  `null`. Used by the app's `BookCoverView` unchanged (Task 6 confirms this).

- [ ] **Step 1: Trust Render's proxy**

In `src/server.ts`, add right after `const app = express();`:

```ts
// Render termina o TLS e repassa via X-Forwarded-Proto; sem isso, req.protocol
// sempre reporta "http" e a URL de capa gerada abaixo quebraria em produção.
app.set('trust proxy', true);
```

- [ ] **Step 2: Add `getCover` to the service**

In `src/services/book.service.ts`, add a method that returns the raw buffer and lets
the controller decide the HTTP shape:

```ts
    /** Devolve os bytes da capa enviada pelo usuário, ou null se o livro não tem uma. */
    async getCoverImage(id: string): Promise<Buffer | null> {
        const book = await this.bookRepository.findById(id);
        if (!book?.coverImage) return null;
        return Buffer.from(book.coverImage, 'base64');
    }
```

- [ ] **Step 3: Derive `coverUrl` in `toResponseDTO`**

Still in `book.service.ts`, change `toResponseDTO` to take a `baseUrl` and prefer the
derived URL when a `coverImage` exists:

```ts
    private toResponseDTO(book: any, baseUrl: string): BookResponseDTO {
        return {
            id: book.id,
            title: book.title,
            author: book.author,
            totalPages: book.totalPages,
            details: book.details,
            coverUrl: book.coverImage ? `${baseUrl}/books/${book.id}/cover` : book.coverUrl,
            status: book.status,
            progress: book.progress,
            userId: book.userId,
            createdAt: book.createdAt,
        };
    }
```

Update the four call sites in the same file to pass `baseUrl` through — each public
method (`createBook`, `getUserBooks`, `getBookById`, `updateBook`) gains a `baseUrl:
string` parameter, threaded to `toResponseDTO`:

```ts
    async createBook(data: CreateBookDTO, userId: string, baseUrl: string): Promise<BookResponseDTO> {
        this.validateCoverImage(data.coverImage);
        const book = await this.bookRepository.create(data, userId);
        return this.toResponseDTO(book, baseUrl);
    }

    async getUserBooks(userId: string, baseUrl: string): Promise<BookResponseDTO[]> {
        const books = await this.bookRepository.findByUserId(userId);
        return books.map(book => this.toResponseDTO(book, baseUrl));
    }

    async getBookById(id: string, userId: string, baseUrl: string): Promise<BookResponseDTO> {
        const book = await this.findAndAuthorize(id, userId);
        return this.toResponseDTO(book, baseUrl);
    }

    async updateBook(id: string, userId: string, data: UpdateBookDTO, baseUrl: string): Promise<BookResponseDTO> {
        this.validateCoverImage(data.coverImage);
        await this.findAndAuthorize(id, userId);
        const updated = await this.bookRepository.update(id, data);
        return this.toResponseDTO(updated, baseUrl);
    }
```

(`books.map(this.toResponseDTO)` becomes `books.map(book => this.toResponseDTO(book,
baseUrl))` because `toResponseDTO` now takes two arguments — the old point-free form
would pass the array index as `baseUrl`.)

- [ ] **Step 4: Wire the controller**

In `src/controllers/book.controller.ts`, add a helper and the new handler, and pass
`baseUrl` through the four existing handlers:

```ts
    private baseUrlFor(req: AuthRequest): string {
        return `${req.protocol}://${req.get('host')}`;
    }
```

Update `create`, `getAll`, `getById`, `update` to pass `this.baseUrlFor(req)` as the
new last argument to their matching service calls (e.g.
`this.bookService.createBook(req.body, req.userId!, this.baseUrlFor(req))`).

Add the new handler (no auth, so no `req.userId!`):

```ts
    // Serve a capa que o usuário enviou. Pública de propósito — ver book.routes.ts.
    getCover = async (req: Request, res: Response): Promise<void> => {
        try {
            const buffer = await this.bookService.getCoverImage(req.params.id as string);
            if (!buffer) {
                res.status(404).end();
                return;
            }
            res.setHeader('Content-Type', 'image/jpeg');
            res.status(200).send(buffer);
        } catch {
            res.status(404).end();
        }
    };
```

Add `Request` to the `express` import at the top of the file (currently only
`Response` is imported).

- [ ] **Step 5: Add the public route**

In `src/routes/book.routes.ts`, add the new route in the public block, above
`bookRoutes.use(authMiddleware);`, next to `/search`:

```ts
bookRoutes.get('/search', bookController.search);
bookRoutes.get('/:id/cover', bookController.getCover);
```

- [ ] **Step 6: Typecheck**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 7: Live verification**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm run dev
```

```bash
TOKEN="<valid JWT>"
# 1x1 red pixel JPEG, valid bytes — base64 below decodes to a real (tiny) JPEG
COVER='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAj/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k='
curl -s -X POST http://localhost:3000/books \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Cover Test","totalPages":10,"coverImage":"'"$COVER"'"}' > /tmp/created.json
cat /tmp/created.json
```

Expected: response includes `"coverUrl":"http://localhost:3000/books/<id>/cover"`.

```bash
BOOK_ID=$(grep -o '"id":"[^"]*"' /tmp/created.json | head -1 | cut -d'"' -f4)
curl -sI "http://localhost:3000/books/$BOOK_ID/cover"
```

Expected: `HTTP/1.1 200 OK` and `Content-Type: image/jpeg`, with no `Authorization`
header sent — confirming the route really is public.

```bash
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:3000/books/00000000-0000-0000-0000-000000000000/cover"
```

Expected: `404`.

Delete the test book afterward:

```bash
curl -s -X DELETE "http://localhost:3000/books/$BOOK_ID" -H "Authorization: Bearer $TOKEN"
```

- [ ] **Step 8: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add src/server.ts src/services/book.service.ts src/controllers/book.controller.ts src/routes/book.routes.ts
git commit -m "feat: serve user-uploaded book covers via public /books/:id/cover"
```

Do not merge or push this branch yet — the app tasks below need it running locally
(`npm run dev`) to verify against, and the whole cycle merges together at the end.

---

### Task 3: Extract the shared image-compression helper

**Files:**
- Create: `ReadUp/Extensions/UIImage+Compression.swift`
- Modify: `ReadUp/Views/Profile.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `UIImage.compressedBase64(maxDimension: CGFloat = 512, quality: CGFloat =
  0.7) -> String?`. Used by Task 6's `BookFormViewModel`.

This is Profile.swift's existing `compressedBase64(from:)` static method, moved
verbatim to an extension and given a second caller. No behavior change.

- [ ] **Step 1: Create the extension**

Create `ReadUp/Extensions/UIImage+Compression.swift`:

```swift
import UIKit

/// Redimensiona e comprime uma imagem para envio ao backend como base64 leve.
/// Usado pela foto de perfil e pela capa de livro cadastrada manualmente.
extension UIImage {
    func compressedBase64(maxDimension: CGFloat = 512, quality: CGFloat = 0.7) -> String? {
        let largestSide = max(size.width, size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        guard let jpeg = resized.jpegData(compressionQuality: quality) else { return nil }
        return jpeg.base64EncodedString()
    }
}
```

- [ ] **Step 2: Replace Profile.swift's copy**

In `ReadUp/Views/Profile.swift`, remove the private static method:

```swift
    /// Redimensiona (máx. 512px) e comprime a imagem em JPEG, devolvendo base64 leve pro backend.
    private static func compressedBase64(from data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 512
        let largestSide = max(image.size.width, image.size.height)
        let scale = largestSide > maxDimension ? maxDimension / largestSide : 1
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.7) else { return nil }
        return jpeg.base64EncodedString()
    }
```

And its one call site:

```swift
                if let data = try? await item.loadTransferable(type: Data.self),
                   let base64 = Self.compressedBase64(from: data) {
```

becomes:

```swift
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let base64 = image.compressedBase64() {
```

- [ ] **Step 3: Build**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
xcodebuild -project ReadUp.xcodeproj -scheme ReadUp -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -10
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
git add ReadUp/Extensions/UIImage+Compression.swift ReadUp/Views/Profile.swift
git commit -m "refactor: extract image compression into a shared UIImage extension"
```

---

### Task 4: `Book` model and `BookService` payloads

**Files:**
- Modify: `ReadUp/Models/Book.swift`
- Modify: `ReadUp/Services/BookService.swift`

**Interfaces:**
- Consumes: nothing new from the app side.
- Produces: `Book.isbn: String?`; `CreateBookPayload`/`UpdateBookPayload` gain
  `isbn: String?` and `coverImage: String?`. Used by Task 6.

- [ ] **Step 1: Add `isbn` to the model**

In `ReadUp/Models/Book.swift`, add `isbn` to the stored properties, `CodingKeys`, both
initializers:

```swift
    var isbn: String?
```

`CodingKeys` gains `case isbn` in the list on the `case id, title, author, details,
coverUrl, status, progress` line. The memberwise `init` gains `isbn: String? = nil`
as a parameter (with a default, so every existing call site keeps compiling), assigned
to `self.isbn = isbn`. The `Decodable` `init(from:)` gains:

```swift
        isbn = try c.decodeIfPresent(String.self, forKey: .isbn)
```

`coverImage` is deliberately NOT added to this model — the backend never sends the
raw base64 back (see `.claude/specs/2026-08-05-book-search-and-entry-design.md`,
"User-supplied covers": the app only ever sees `coverUrl`).

- [ ] **Step 2: Add the two fields to both payloads**

In `ReadUp/Services/BookService.swift`, add to `CreateBookPayload` (with defaults, so
the existing search-import call site in `LibraryStore.addBook(from:status:)` keeps
compiling untouched):

```swift
    let isbn: String? = nil
    let coverImage: String? = nil
```

And to `UpdateBookPayload`:

```swift
    var isbn: String?
    var coverImage: String?
```

Both structs already rely on synthesized `Encodable` conformance, which omits `nil`
optionals automatically (the file's own comment confirms this is the existing,
relied-upon behavior) — no encoder changes needed.

- [ ] **Step 3: Build**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
xcodebuild -project ReadUp.xcodeproj -scheme ReadUp -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -10
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
git add ReadUp/Models/Book.swift ReadUp/Services/BookService.swift
git commit -m "feat: add isbn/coverImage to Book model and payloads"
```

---

### Task 5: Localization

**Files:**
- Modify: `ReadUp/Localizations/Localization+AddBook.swift`
- Modify: `ReadUp/Localizations/Localization+Library.swift`
- Modify: `ReadUp/Localizations/Localization+BookDetails.swift`
- Modify: `ReadUp/Localizable.xcstrings`

**Interfaces:**
- Consumes: nothing.
- Produces: `Localization.AddBook.isbnPlaceholder`, `Localization.Library.addManually`,
  `Localization.Library.searchOption`, `Localization.BookDetails.editBook`. Used by
  Task 7 (Library menu and the book-details overflow menu) and Task 6 (form).

- [ ] **Step 1: Add the ISBN placeholder case**

In `ReadUp/Localizations/Localization+AddBook.swift`, add `case isbnPlaceholder` to
the enum and `case .isbnPlaceholder: "addBook.isbnPlaceholder"` to `key`.

- [ ] **Step 2: Add the "Edit Book" case**

`Localization+BookDetails.swift` has no key for opening the edit form (it has
`deleteBook`/`changeStatus` for the other two overflow-menu actions, but nothing for
editing). Add `case editBook` to the enum and `case .editBook: "bookDetails.editBook"`
to `key`.

- [ ] **Step 3: Add the two Library menu-item cases**

In `ReadUp/Localizations/Localization+Library.swift`, add:

```swift
        case searchOption
        case addManually
```

and to `key`:

```swift
            case .searchOption: "library.addMenu.search"
            case .addManually: "library.addMenu.addManually"
```

- [ ] **Step 4: Add the four keys to Localizable.xcstrings**

Read the file, find the `"strings"` object (alphabetically ordered), and insert four
new entries in alphabetical position, matching the existing format exactly (see
`addBook.titlePlaceholder` for the shape to copy):

```json
    "addBook.isbnPlaceholder" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "ISBN (optional)"
          }
        },
        "pt-BR" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "ISBN (opcional)"
          }
        }
      }
    },
```

```json
    "bookDetails.editBook" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Edit Book"
          }
        },
        "pt-BR" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Editar Livro"
          }
        }
      }
    },
```

```json
    "library.addMenu.addManually" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Add Manually"
          }
        },
        "pt-BR" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Cadastrar Manualmente"
          }
        }
      }
    },
```

```json
    "library.addMenu.search" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Search"
          }
        },
        "pt-BR" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Buscar"
          }
        }
      }
    },
```

Preserve the file's trailing `"sourceLanguage"`/`"version"` keys and overall JSON
validity — after editing, verify with:

```bash
node -e "JSON.parse(require('fs').readFileSync('/Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp/ReadUp/Localizable.xcstrings','utf8')); console.log('valid')"
```

Expected: `valid`.

- [ ] **Step 5: Build**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
xcodebuild -project ReadUp.xcodeproj -scheme ReadUp -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -10
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 6: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
git add ReadUp/Localizations/Localization+AddBook.swift ReadUp/Localizations/Localization+Library.swift ReadUp/Localizations/Localization+BookDetails.swift ReadUp/Localizable.xcstrings
git commit -m "feat: add localization for the book form and library add-menu"
```

---

### Task 6: `BookFormView` and `BookFormViewModel`

**Files:**
- Create: `ReadUp/ViewModels/BookFormViewModel.swift`
- Create: `ReadUp/Views/BookFormView.swift`
- Modify: `ReadUp/ViewModels/LibraryStore.swift`

**Interfaces:**
- Consumes: `Localization.AddBook.*` (Task 5), `UIImage.compressedBase64()` (Task 3),
  `CreateBookPayload`/`UpdateBookPayload` with `isbn`/`coverImage` (Task 4),
  `POST /books` and `PUT /books/:id` from `BookService` (unchanged signatures).
- Produces: `struct BookFormView: View` with `init(mode: BookFormViewModel.Mode,
  onSaved: @escaping () -> Void)`; `LibraryStore.createManualBook(_:) async ->
  Bool` and an extended `updateBook(_:with:) async -> Bool`. Used by Task 7.

- [ ] **Step 1: Extend `LibraryStore` with the two save paths**

In `ReadUp/ViewModels/LibraryStore.swift`, add near `addBook(from:status:)`:

```swift
    /// Cria um livro cadastrado manualmente (sem passar pela busca).
    @discardableResult
    func createManualBook(_ payload: CreateBookPayload) async -> Bool {
        guard let token else { return false }
        do {
            let book = try await bookService.createBook(payload, token: token)
            books.append(book)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Atualiza os campos editáveis de um livro existente (formulário de edição).
    @discardableResult
    func updateBook(_ book: Book, with payload: UpdateBookPayload) async -> Bool {
        guard let token else { return false }
        do {
            let updated = try await bookService.updateBook(id: book.id, payload, token: token)
            if let index = books.firstIndex(where: { $0.id == updated.id }) {
                books[index] = updated
            }
            for i in sessions.indices where sessions[i].book.id == updated.id {
                sessions[i].book = updated
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
```

(`updateBook(_:with:)` is deliberately public and named differently from the
existing private `applyUpdate` — it needs to report success/failure to the form,
which `applyUpdate`'s current callers don't need.)

- [ ] **Step 2: Write the view model**

Create `ReadUp/ViewModels/BookFormViewModel.swift`:

```swift
import Foundation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class BookFormViewModel {
    enum Mode {
        case create
        case edit(Book)

        var book: Book? {
            if case .edit(let book) = self { return book }
            return nil
        }
    }

    let mode: Mode

    var title: String
    var author: String
    var pagesText: String
    var isbn: String
    var details: String
    var status: BookStatus
    var coverImage: UIImage?

    var selectedPhoto: PhotosPickerItem?
    var isSaving = false
    var errorMessage: String?

    /// Base64 comprimido da nova capa, se o usuário trocou; nil = manter a capa atual.
    private var newCoverBase64: String?

    init(mode: Mode) {
        self.mode = mode
        let book = mode.book
        title = book?.title ?? ""
        author = book?.author ?? ""
        pagesText = book.map { $0.numberOfPages > 0 ? String($0.numberOfPages) : "" } ?? ""
        isbn = book?.isbn ?? ""
        details = book?.details ?? ""
        status = book?.status ?? .iWantToRead
        coverImage = nil
    }

    var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (Int(pagesText) ?? 0) > 0
    }

    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        coverImage = image
        newCoverBase64 = image.compressedBase64()
    }

    @discardableResult
    func save(store: LibraryStore) async -> Bool {
        guard isSaveEnabled else { return false }
        isSaving = true
        defer { isSaving = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedAuthor = author.trimmingCharacters(in: .whitespaces)
        let trimmedIsbn = isbn.trimmingCharacters(in: .whitespaces)
        let pages = Int(pagesText) ?? 0

        let success: Bool
        switch mode {
        case .create:
            let payload = CreateBookPayload(
                title: trimmedTitle,
                author: trimmedAuthor.isEmpty ? nil : trimmedAuthor,
                totalPages: pages,
                details: details.isEmpty ? nil : details,
                coverUrl: nil,
                status: status.rawValue,
                isbn: trimmedIsbn.isEmpty ? nil : trimmedIsbn,
                coverImage: newCoverBase64
            )
            success = await store.createManualBook(payload)
        case .edit(let book):
            let payload = UpdateBookPayload(
                title: trimmedTitle,
                author: trimmedAuthor,
                totalPages: pages,
                details: details,
                status: status.rawValue,
                isbn: trimmedIsbn,
                coverImage: newCoverBase64
            )
            success = await store.updateBook(book, with: payload)
        }

        if !success {
            errorMessage = store.errorMessage ?? "Could not save this book."
        }
        return success
    }
}
```

- [ ] **Step 3: Write the view**

Create `ReadUp/Views/BookFormView.swift`:

```swift
import PhotosUI
import SwiftUI

/// Um formulário, dois modos: cadastro manual (vazio) e edição (pré-preenchido).
/// Ver `.claude/specs/2026-08-05-book-search-and-entry-design.md`.
struct BookFormView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: BookFormViewModel
    let onSaved: () -> Void

    init(mode: BookFormViewModel.Mode, onSaved: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: BookFormViewModel(mode: mode))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        coverPicker
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField(Localization.AddBook.titlePlaceholder.string, text: $viewModel.title)
                    TextField(Localization.AddBook.authorPlaceholder.string, text: $viewModel.author)
                    TextField(Localization.AddBook.pagesPlaceholder.string, text: $viewModel.pagesText)
                        .keyboardType(.numberPad)
                    TextField(Localization.AddBook.isbnPlaceholder.string, text: $viewModel.isbn)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section {
                    Picker(Localization.AddBook.selectStatus.string, selection: $viewModel.status) {
                        ForEach(BookStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                Section {
                    TextEditor(text: $viewModel.details)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if viewModel.details.isEmpty {
                                Text(Localization.AddBook.detailsPlaceholder.string)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
            .navigationTitle(Localization.AddBook.saveBook.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.Generic.cancel.string) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.AddBook.saveBook.string) {
                        Task {
                            if await viewModel.save(store: store) {
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isSaveEnabled || viewModel.isSaving)
                }
            }
            .onChange(of: viewModel.selectedPhoto) { _, item in
                Task { await viewModel.handlePhotoSelection(item) }
            }
        }
    }

    @ViewBuilder
    private var coverPicker: some View {
        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images, photoLibrary: .shared()) {
            ZStack(alignment: .bottomTrailing) {
                if let image = viewModel.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 171)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else if let existingUrl = viewModel.mode.book?.coverUrl {
                    BookCoverView(coverUrl: existingUrl, width: 120, height: 171, cornerRadius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                        .frame(width: 120, height: 171)
                        .overlay {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                }
                Image(systemName: "camera.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(Color.emphasis))
                    .offset(x: 4, y: 4)
            }
        }
        .disabled(viewModel.isSaving)
    }
}

#Preview {
    BookFormView(mode: .create)
        .environment(LibraryStore())
}
```

- [ ] **Step 4: Build**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
xcodebuild -project ReadUp.xcodeproj -scheme ReadUp -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. This task is not reachable from the UI yet — Task 7
wires the entry points. A build pass is the only signal available here.

- [ ] **Step 5: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
git add ReadUp/ViewModels/BookFormViewModel.swift ReadUp/Views/BookFormView.swift ReadUp/ViewModels/LibraryStore.swift
git commit -m "feat: add BookFormView for manual entry and editing"
```

---

### Task 7: Wire the entry points and verify end to end

**Files:**
- Modify: `ReadUp/Views/Library.swift`
- Modify: `ReadUp/Views/BookDetailsSheet.swift`

**Interfaces:**
- Consumes: `BookFormView` (Task 6), `Localization.Library.searchOption` /
  `.addManually` (Task 5).
- Produces: nothing further downstream — this is the last task of the cycle.

- [ ] **Step 1: Turn the Library `+` into a menu**

In `ReadUp/Views/Library.swift`, add state:

```swift
    @State private var isShowingAddManually = false
```

Replace the toolbar's `Button`:

```swift
                Button {
                    tabState.goToSearchTab()
                } label: {
                    Image(systemName: "plus")
                }
```

with:

```swift
                Menu {
                    Button {
                        tabState.goToSearchTab()
                    } label: {
                        Label(Localization.Library.searchOption.string, systemImage: "magnifyingglass")
                    }
                    Button {
                        isShowingAddManually = true
                    } label: {
                        Label(Localization.Library.addManually.string, systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "plus")
                }
```

Add a second sheet modifier next to the existing `.sheet(item: $selectedBook)`:

```swift
        .sheet(isPresented: $isShowingAddManually) {
            BookFormView(mode: .create)
        }
```

- [ ] **Step 2: Add "Edit" to the book detail sheet's overflow menu**

In `ReadUp/Views/BookDetailsSheet.swift`, add state:

```swift
    @State private var isShowingEditForm = false
```

In the `toolbar`'s `Menu` (the one guarded by `if case .library = source`), add a
button above the existing "Change Status" one:

```swift
                            Button {
                                isShowingEditForm = true
                            } label: {
                                Label(Localization.BookDetails.editBook.string, systemImage: "pencil")
                            }
```

(`.editBook` is the key Task 5 added to `Localization+BookDetails.swift` — this
codebase has full localization coverage everywhere else, so this menu item follows
that convention rather than a hardcoded string.)

Add the sheet, right next to the existing `.sheet(isPresented: $showAuth)`:

```swift
            .sheet(isPresented: $isShowingEditForm) {
                if case .library(let book) = source {
                    BookFormView(mode: .edit(book)) {
                        dismiss()
                    }
                }
            }
```

The `onSaved` closure dismisses the whole detail sheet after a successful edit,
matching how "Change Status" and "Delete" already dismiss after mutating —
`BookDetailsSheet`'s `source` is a value captured at presentation time, not
reactive to `store.books` changes, so keeping it open with stale data would be the
actual bug here.

- [ ] **Step 3: Build**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
xcodebuild -project ReadUp.xcodeproj -scheme ReadUp -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: End-to-end simulator verification**

With the backend from Task 2 running locally (`npm run dev` in ReadUpBackend) and
`BASEURL` in `ReadUp/Secrets.xcconfig` temporarily pointed at
`http:/$()/localhost:3000` (revert after testing — do not commit this change):

1. Launch the app, log in with a real or test account.
2. Library tab → `+` → confirm the menu shows "Search" and "Add Manually".
3. Tap "Add Manually" → fill title + pages (required) → pick a cover photo from the
   simulator's photo library → Save.
4. Confirm the new book appears in the Library list with its cover.
5. Open it → overflow menu → "Edit Book" → change the title → Save.
6. Confirm the Library list reflects the new title.
7. Confirm the cover still renders (proves `GET /books/:id/cover` works through
   `BookCoverView`'s plain `AsyncImage`, unauthenticated, exactly as designed).

Revert `Secrets.xcconfig` back to the production `BASEURL` afterward — it must not
ship pointed at localhost.

- [ ] **Step 5: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUp
git add ReadUp/Views/Library.swift ReadUp/Views/BookDetailsSheet.swift
git commit -m "feat: wire manual entry and editing into Library and book details"
```

---

## Done when

- Backend `feat/unified-book-form` branch: `npx tsc --noEmit` clean, the Task 2 live
  curl sequence passes (create with cover → `coverUrl` points at `/books/:id/cover` →
  that URL returns `image/jpeg` with no auth header → unknown id returns 404).
- `npm test` in the backend still reports 36/36 (cycle 1's suite untouched).
- App `feat/unified-book-form` branch builds clean.
- A book can be created from the Library `+` menu with no search involved, with a
  user-picked cover, and it appears correctly in the Library.
- An existing library book's title, author, pages, ISBN, details, status, and cover
  can all be changed through the same form and the change persists after reopening
  the book.
- Neither branch is merged to `main` yet — that is a deliberate checkpoint for the
  user, same as cycle 1.
