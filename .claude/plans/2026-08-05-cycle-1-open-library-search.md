# Cycle 1 — Open Library Search Engine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Google Books with Open Library as the search index, so that searching "harry potter" returns the Rowling series instead of fanfic and generic derivatives.

**Architecture:** One orchestrating service (`book-search.service.ts`) over two dumb providers. Open Library answers free-text search and genre browsing; Google Books survives only as a fallback when Open Library returns nothing. Portuguese titles are resolved from the work's editions, cached. Roughly 250 lines of ranking heuristics are deleted, because Open Library's work-level index and `readinglog_count` already carry the signal those heuristics were trying to reconstruct.

**Tech Stack:** Node 26, TypeScript 6 (CommonJS), Express 5, `node:test` (no new dependencies).

**Spec:** [`.claude/specs/2026-08-05-book-search-and-entry-design.md`](../specs/2026-08-05-book-search-and-entry-design.md)

## Global Constraints

- **Backend-only cycle.** The HTTP contract of `GET /books/search` does not change: same query parameters (`q`, `lang`, `maxResults`, `startIndex`, `mode`) and same JSON shape. The iOS app is not touched in this cycle and must keep working without a rebuild.
- All `.md` files are written in **English**.
- **No new npm dependencies.** Tests run on `node:test`, which ships with Node.
- Tests run against **compiled JavaScript**: `tsc && node --test "dist/**/*.test.js"`. Do not run `node --test` directly on `.ts` files — Node's strip-only mode rejects TypeScript parameter properties (`constructor(private x: T)`) and requires explicit `.ts` extensions on relative imports, which conflicts with this project's `module: CommonJS`.
- Never call the live Open Library API from a test. Every test stubs `globalThis.fetch` with `mock.method`.
- Open Library requires no API key. Google Books uses `process.env.GOOGLE_BOOKS_API_KEY`, which already exists in `.env`.
- Open Library language codes are MARC three-letter codes: `pt` → `por`, `en` → `eng`.
- Comments in code stay in **Portuguese**, matching the existing codebase.

## File Structure

**Created — `ReadUpBackend/src/services/search/`**

| File | Responsibility |
|---|---|
| `ttl-cache.ts` | In-memory `Map` with expiry. Nothing else. |
| `language.ts` | Decide the result language from the query and the device locale. |
| `openlibrary.provider.ts` | Talk to Open Library: search, subject browse, localized edition. Maps to DTO. No orchestration. |
| `google-books.provider.ts` | Talk to Google Books: free-text fallback only. No ranking. |
| `book-search.service.ts` | Orchestrate: filter, localize, cache, decide fallback. |

Each of the five gets a `.test.ts` sibling except `google-books.provider.ts`, whose only logic is a URL and a field mapping already covered through the service test.

**Deleted**

- `src/services/google-books.service.ts` (384 lines)
- `src/services/genre-seeds.ts`

**Modified**

- `src/controllers/book.controller.ts` — swap the service.
- `src/dtos/book.dto.ts` — trim `SearchBookDTO`.
- `package.json` — add the `test` script.
- `tsconfig.json` — nothing. Test files compile with everything else.

---

### Task 1: Test runner and TTL cache

**Files:**
- Create: `ReadUpBackend/src/services/search/ttl-cache.ts`
- Create: `ReadUpBackend/src/services/search/ttl-cache.test.ts`
- Modify: `ReadUpBackend/package.json` (scripts)

**Interfaces:**
- Consumes: nothing.
- Produces: `class TtlCache<T>` with `constructor(ttlMs: number)`, `get(key: string): T | undefined`, `set(key: string, value: T): void`. Used by Task 5.

- [ ] **Step 1: Add the test script**

In `package.json`, replace the placeholder `test` script:

```json
"test": "tsc && node --test \"dist/**/*.test.js\""
```

- [ ] **Step 2: Write the failing test**

Create `src/services/search/ttl-cache.test.ts`:

```ts
import { test, mock } from 'node:test';
import assert from 'node:assert';
import { TtlCache } from './ttl-cache';

test('devolve o valor guardado antes do TTL vencer', () => {
    const cache = new TtlCache<string>(1000);
    cache.set('k', 'v');
    assert.equal(cache.get('k'), 'v');
});

test('descarta o valor depois do TTL vencer', () => {
    mock.timers.enable({ apis: ['Date'] });
    const cache = new TtlCache<string>(1000);
    cache.set('k', 'v');
    mock.timers.tick(1000);
    assert.equal(cache.get('k'), undefined);
    mock.timers.reset();
});

test('devolve undefined para chave que nunca foi guardada', () => {
    const cache = new TtlCache<string>(1000);
    assert.equal(cache.get('ausente'), undefined);
});
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: FAIL — `tsc` reports `Cannot find module './ttl-cache'`.

- [ ] **Step 4: Write the implementation**

Create `src/services/search/ttl-cache.ts`:

```ts
/**
 * Cache em memória com expiração. Usado pelo book-search pra não repetir chamadas
 * caras à Open Library (edição localizada e seções de gênero).
 *
 * ponytail: Map em memória — morre a cada deploy e não é compartilhado entre
 * instâncias. Vira Redis quando rodar mais de uma instância, não antes.
 */
export class TtlCache<T> {
    private entries = new Map<string, { at: number; value: T }>();
    private ttlMs: number;

    constructor(ttlMs: number) {
        this.ttlMs = ttlMs;
    }

    get(key: string): T | undefined {
        const entry = this.entries.get(key);
        if (!entry) return undefined;
        if (Date.now() - entry.at >= this.ttlMs) {
            this.entries.delete(key);
            return undefined;
        }
        return entry.value;
    }

    set(key: string, value: T): void {
        this.entries.set(key, { at: Date.now(), value });
    }
}
```

Note: `private ttlMs` is declared as a field and assigned in the constructor body rather than as a constructor parameter property. This is deliberate — see Global Constraints.

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add package.json src/services/search/ttl-cache.ts src/services/search/ttl-cache.test.ts
git commit -m "test: add node:test runner and TtlCache"
```

---

### Task 2: Language resolution

**Files:**
- Create: `ReadUpBackend/src/services/search/language.ts`
- Create: `ReadUpBackend/src/services/search/language.test.ts`

**Interfaces:**
- Consumes: nothing.
- Produces: `resolveLanguage(query: string, deviceLang?: string): 'pt' | 'en'` and `toMarcLanguage(lang: 'pt' | 'en'): string`. Used by Tasks 3 and 5.

This is the one piece of `google-books.service.ts` worth keeping. It is being moved, not rewritten, and gains tests it never had.

- [ ] **Step 1: Write the failing test**

Create `src/services/search/language.test.ts`:

```ts
import { test } from 'node:test';
import assert from 'node:assert';
import { resolveLanguage, toMarcLanguage } from './language';

test('diacrítico exclusivo do português força pt', () => {
    assert.equal(resolveLanguage('o senhor dos anéis', 'en'), 'pt');
});

test('stopwords em inglês forçam en mesmo com aparelho em pt', () => {
    assert.equal(resolveLanguage('the lord of the rings', 'pt'), 'en');
});

test('stopwords em português forçam pt mesmo com aparelho em en', () => {
    assert.equal(resolveLanguage('a menina que roubava livros', 'en'), 'pt');
});

test('sem sinal de idioma mantém o idioma do aparelho', () => {
    assert.equal(resolveLanguage('sapiens', 'pt'), 'pt');
    assert.equal(resolveLanguage('sapiens', 'en'), 'en');
});

test('idioma não suportado cai para en', () => {
    assert.equal(resolveLanguage('sapiens', 'fr'), 'en');
    assert.equal(resolveLanguage('sapiens', undefined), 'en');
});

test('normaliza variante regional do aparelho', () => {
    assert.equal(resolveLanguage('sapiens', 'pt-BR'), 'pt');
});

test('converte para o código MARC de três letras usado pela Open Library', () => {
    assert.equal(toMarcLanguage('pt'), 'por');
    assert.equal(toMarcLanguage('en'), 'eng');
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: FAIL — `Cannot find module './language'`.

- [ ] **Step 3: Write the implementation**

Create `src/services/search/language.ts`:

```ts
/**
 * Decide em que idioma os resultados devem vir.
 *
 * Regra: segue o idioma do aparelho, MAS se a query estiver claramente em outro
 * idioma, esse idioma ganha. Ex.: aparelho em pt + "the lord of the rings" → en.
 */

export type SupportedLanguage = 'pt' | 'en';

const SUPPORTED: SupportedLanguage[] = ['pt', 'en'];

// Stopwords servem só pra inferir o idioma da query — não entram na busca.
const PT_STOPWORDS = new Set([
    'o', 'os', 'a', 'as', 'um', 'uma', 'uns', 'umas', 'de', 'do', 'da', 'dos', 'das',
    'no', 'na', 'nos', 'nas', 'e', 'que', 'com', 'para', 'por', 'em', 'ao', 'aos',
    'meu', 'minha', 'seu', 'sua', 'não', 'é', 'são',
]);

const EN_STOPWORDS = new Set([
    'the', 'of', 'and', 'an', 'to', 'in', 'on', 'for', 'with', 'is', 'are', 'my',
    'your', 'from', 'at', 'as', 'about', 'how',
]);

// A Open Library usa códigos MARC de três letras.
const MARC: Record<SupportedLanguage, string> = { pt: 'por', en: 'eng' };

function normalize(code?: string): SupportedLanguage {
    if (!code) return 'en';
    const base = code.toLowerCase().split('-')[0] as SupportedLanguage;
    return SUPPORTED.includes(base) ? base : 'en';
}

export function resolveLanguage(query: string, deviceLang?: string): SupportedLanguage {
    const q = query.toLowerCase();

    // Diacríticos que só existem em português: sinal forte, decide sozinho.
    if (/[ãõç]/.test(q)) return 'pt';

    const tokens = q.replace(/[^a-zà-ú\s]/gi, ' ').split(/\s+/).filter(Boolean);
    let pt = 0;
    let en = 0;
    for (const token of tokens) {
        if (PT_STOPWORDS.has(token)) pt++;
        if (EN_STOPWORDS.has(token)) en++;
    }

    if (en > pt) return 'en';
    if (pt > en) return 'pt';
    return normalize(deviceLang);
}

export function toMarcLanguage(lang: SupportedLanguage): string {
    return MARC[lang];
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: PASS, 10 tests total.

- [ ] **Step 5: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add src/services/search/language.ts src/services/search/language.test.ts
git commit -m "refactor: extract language resolution with tests"
```

---

### Task 3: Open Library provider — search, browse and DTO mapping

**Files:**
- Create: `ReadUpBackend/src/services/search/openlibrary.provider.ts`
- Create: `ReadUpBackend/src/services/search/openlibrary.provider.test.ts`
- Modify: `ReadUpBackend/src/dtos/book.dto.ts`

**Interfaces:**
- Consumes: `resolveLanguage`, `toMarcLanguage`, `SupportedLanguage` from Task 2.
- Produces:
  - `interface OpenLibraryDoc` — the fields requested from `search.json`.
  - `filterDocs(docs: OpenLibraryDoc[]): OpenLibraryDoc[]`
  - `toDTO(doc: OpenLibraryDoc): SearchBookDTO`
  - `searchWorks(query: string, lang: SupportedLanguage, limit: number, offset: number): Promise<OpenLibraryDoc[]>`
  - `browseSubject(subject: string, lang: SupportedLanguage, limit: number): Promise<OpenLibraryDoc[]>`

  All used by Task 5.

- [ ] **Step 1: Trim the search DTO**

In `src/dtos/book.dto.ts`, replace `SearchBookDTO` with:

```ts
/** Resultado de busca de livro. Espelha o `SearchBook` do app. */
export interface SearchBookDTO {
    id: string;
    title: string;
    author: string | null;
    totalPages: number;
    details: string | null;
    coverUrl: string | null;
    language: string;
    publishedDate: string | null;
}
```

`averageRating` and `ratingsCount` are removed: the app never decoded them ([GoogleBooksModels.swift](../../ReadUp/Models/GoogleBooksModels.swift) has no such keys) and Open Library does not supply them in a comparable form. Removing them keeps the DTO honest about what it carries.

- [ ] **Step 2: Write the failing test**

Create `src/services/search/openlibrary.provider.test.ts`:

```ts
import { test, mock, afterEach } from 'node:test';
import assert from 'node:assert';
import {
    filterDocs,
    toDTO,
    searchWorks,
    browseSubject,
    OpenLibraryDoc,
} from './openlibrary.provider';

/** Doc mínimo válido; cada teste sobrescreve só o que interessa. */
function doc(overrides: Partial<OpenLibraryDoc> = {}): OpenLibraryDoc {
    return {
        key: '/works/OL1W',
        title: 'Um Livro',
        author_name: ['Alguém'],
        cover_i: 123,
        readinglog_count: 100,
        ...overrides,
    };
}

/** Troca o fetch global por um que devolve `body`, e registra as URLs chamadas. */
function stubFetch(body: unknown): { urls: string[] } {
    const urls: string[] = [];
    mock.method(globalThis, 'fetch', async (url: string) => {
        urls.push(String(url));
        return new Response(JSON.stringify(body), { status: 200 });
    });
    return { urls };
}

afterEach(() => mock.restoreAll());

test('descarta resultado sem autor', () => {
    const kept = filterDocs([doc(), doc({ key: '/works/OL2W', author_name: undefined })]);
    assert.equal(kept.length, 1);
    assert.equal(kept[0].key, '/works/OL1W');
});

test('descarta resultado sem capa', () => {
    const kept = filterDocs([doc(), doc({ key: '/works/OL2W', cover_i: undefined })]);
    assert.equal(kept.length, 1);
});

test('descarta obscuro quando existe um resultado popular', () => {
    const kept = filterDocs([
        doc({ key: '/works/OL1W', readinglog_count: 5000 }),
        doc({ key: '/works/OL2W', readinglog_count: 2 }),
    ]);
    assert.deepEqual(kept.map(d => d.key), ['/works/OL1W']);
});

test('mantém todos quando nenhum resultado é popular — sem base de comparação', () => {
    const kept = filterDocs([
        doc({ key: '/works/OL1W', readinglog_count: 4 }),
        doc({ key: '/works/OL2W', readinglog_count: 2 }),
    ]);
    assert.equal(kept.length, 2);
});

test('converte doc em DTO com id sem o prefixo /works/', () => {
    const dto = toDTO(doc({
        key: '/works/OL82563W',
        title: 'Harry Potter and the Philosopher\'s Stone',
        author_name: ['J. K. Rowling', 'Mary GrandPré'],
        cover_i: 15155833,
        number_of_pages_median: 302,
        first_publish_year: 1997,
        description: 'Uma sinopse.',
        language: ['por', 'eng'],
    }));

    assert.equal(dto.id, 'OL82563W');
    assert.equal(dto.author, 'J. K. Rowling, Mary GrandPré');
    assert.equal(dto.totalPages, 302);
    assert.equal(dto.publishedDate, '1997');
    assert.equal(dto.details, 'Uma sinopse.');
    assert.equal(dto.coverUrl, 'https://covers.openlibrary.org/b/id/15155833-M.jpg');
});

test('aceita description no formato objeto que a OL às vezes devolve', () => {
    const description = { type: '/type/text', value: 'Texto.' } as OpenLibraryDoc['description'];
    const dto = toDTO(doc({ description }));
    assert.equal(dto.details, 'Texto.');
});

test('DTO sobrevive a doc sem páginas, sem ano e sem sinopse', () => {
    const dto = toDTO(doc({
        number_of_pages_median: undefined,
        first_publish_year: undefined,
        description: undefined,
    }));
    assert.equal(dto.totalPages, 0);
    assert.equal(dto.publishedDate, null);
    assert.equal(dto.details, null);
});

test('searchWorks pede os campos certos e filtra por idioma MARC', async () => {
    const { urls } = stubFetch({ docs: [doc()] });
    await searchWorks('harry potter', 'pt', 20, 0);

    const url = urls[0];
    assert.ok(url.startsWith('https://openlibrary.org/search.json?'));
    assert.ok(url.includes('language=por'));
    assert.ok(url.includes('limit=20'));
    assert.ok(url.includes('offset=0'));
    assert.ok(url.includes('readinglog_count'));
    assert.ok(url.includes('description'));
});

test('browseSubject ordena por readinglog e cita assunto com espaço', async () => {
    const { urls } = stubFetch({ docs: [doc()] });
    await browseSubject('science fiction', 'en', 12);

    const url = decodeURIComponent(urls[0]);
    assert.ok(url.includes('sort=readinglog'));
    assert.ok(url.includes('subject:"science fiction"'));
    assert.ok(url.includes('language=eng'));
});

test('devolve lista vazia quando a Open Library responde erro', async () => {
    mock.method(globalThis, 'fetch', async () => new Response('boom', { status: 500 }));
    assert.deepEqual(await searchWorks('qualquer', 'pt', 20, 0), []);
});

test('devolve lista vazia quando o fetch lança', async () => {
    mock.method(globalThis, 'fetch', async () => { throw new Error('offline'); });
    assert.deepEqual(await searchWorks('qualquer', 'pt', 20, 0), []);
});
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: FAIL — `Cannot find module './openlibrary.provider'`.

- [ ] **Step 4: Write the implementation**

Create `src/services/search/openlibrary.provider.ts`:

```ts
import { SearchBookDTO } from '../../dtos/book.dto';
import { SupportedLanguage, toMarcLanguage } from './language';

/**
 * Cliente da Open Library (https://openlibrary.org/developers/api). Sem key, sem quota.
 *
 * A diferença que motivou a troca do Google Books: a OL indexa OBRAS, não edições.
 * Uma busca por "harry potter" devolve os sete livros da série, não cada reimpressão,
 * resumo e guia de estudo. E `readinglog_count` (quantas pessoas têm o livro na
 * estante) é o sinal de popularidade que separa a obra do derivado.
 */

const SEARCH_ENDPOINT = 'https://openlibrary.org/search.json';
const COVER_ENDPOINT = 'https://covers.openlibrary.org/b/id';

// Só os campos que usamos: resposta menor, busca mais rápida.
const SEARCH_FIELDS = [
    'key',
    'title',
    'author_name',
    'cover_i',
    'number_of_pages_median',
    'readinglog_count',
    'first_publish_year',
    'description',
    'language',
].join(',');

// Acima disso, um resultado é "conhecido"; abaixo do outro, é ruído.
const POPULAR_THRESHOLD = 50;
const OBSCURE_THRESHOLD = 5;

export interface OpenLibraryDoc {
    key: string;
    title?: string;
    author_name?: string[];
    cover_i?: number;
    number_of_pages_median?: number;
    readinglog_count?: number;
    first_publish_year?: number;
    // A OL devolve ora string, ora { type, value }.
    description?: string | { value?: string };
    language?: string[];
}

interface SearchResponse {
    docs?: OpenLibraryDoc[];
}

/**
 * Corta o ruído em três regras. Nada de score composto: a OL já ordena por
 * relevância, e reconstruir o ranking dela por fora foi exatamente o erro que
 * tornou a busca antiga ruim.
 */
export function filterDocs(docs: OpenLibraryDoc[]): OpenLibraryDoc[] {
    const usable = docs.filter(doc =>
        Boolean(doc.title) &&
        Boolean(doc.author_name && doc.author_name.length > 0) &&
        typeof doc.cover_i === 'number'
    );

    // Se a busca tem algum resultado claramente popular, os quase-desconhecidos são
    // derivados (fanfic, resumo, edição genérica). Sem nenhum popular não há base de
    // comparação — pode ser um livro de nicho legítimo — e mantemos tudo.
    const hasPopular = usable.some(doc => (doc.readinglog_count ?? 0) >= POPULAR_THRESHOLD);
    if (!hasPopular) return usable;

    return usable.filter(doc => (doc.readinglog_count ?? 0) >= OBSCURE_THRESHOLD);
}

function descriptionText(description: OpenLibraryDoc['description']): string | null {
    if (!description) return null;
    const text = typeof description === 'string' ? description : description.value;
    const trimmed = text?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
}

export function workIdFromKey(key: string): string {
    return key.replace('/works/', '');
}

export function coverUrlFor(coverId?: number): string | null {
    return typeof coverId === 'number' ? `${COVER_ENDPOINT}/${coverId}-M.jpg` : null;
}

export function toDTO(doc: OpenLibraryDoc): SearchBookDTO {
    return {
        id: workIdFromKey(doc.key),
        title: doc.title ?? 'Untitled',
        author: doc.author_name?.join(', ') ?? null,
        totalPages: doc.number_of_pages_median ?? 0,
        details: descriptionText(doc.description),
        coverUrl: coverUrlFor(doc.cover_i),
        // A obra existe em vários idiomas; quem manda no rótulo é o idioma pedido,
        // resolvido pelo serviço. Aqui devolvemos o primeiro conhecido só como dica.
        language: doc.language?.[0] ?? 'eng',
        publishedDate: doc.first_publish_year ? String(doc.first_publish_year) : null,
    };
}

/** GET na OL devolvendo os docs; qualquer falha vira lista vazia (o serviço decide o fallback). */
async function fetchDocs(params: URLSearchParams): Promise<OpenLibraryDoc[]> {
    try {
        const response = await fetch(`${SEARCH_ENDPOINT}?${params.toString()}`);
        if (!response.ok) {
            console.error('Open Library error:', response.status);
            return [];
        }
        const data = (await response.json()) as SearchResponse;
        return data.docs ?? [];
    } catch (error) {
        console.error('Open Library unreachable:', error);
        return [];
    }
}

export async function searchWorks(
    query: string,
    lang: SupportedLanguage,
    limit: number,
    offset: number
): Promise<OpenLibraryDoc[]> {
    return fetchDocs(new URLSearchParams({
        q: query,
        language: toMarcLanguage(lang),
        fields: SEARCH_FIELDS,
        limit: String(limit),
        offset: String(offset),
    }));
}

export async function browseSubject(
    subject: string,
    lang: SupportedLanguage,
    limit: number
): Promise<OpenLibraryDoc[]> {
    // Assunto com espaço precisa de aspas, senão a OL quebra em dois termos soltos.
    const term = subject.includes(' ') ? `"${subject}"` : subject;
    return fetchDocs(new URLSearchParams({
        q: `subject:${term}`,
        // Popularidade em vez de relevância: numa vitrine de gênero o usuário quer os
        // livros que as pessoas realmente leem, não o match textual mais próximo.
        sort: 'readinglog',
        language: toMarcLanguage(lang),
        fields: SEARCH_FIELDS,
        limit: String(limit),
    }));
}
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: PASS, 21 tests total.

- [ ] **Step 6: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add src/services/search/openlibrary.provider.ts src/services/search/openlibrary.provider.test.ts src/dtos/book.dto.ts
git commit -m "feat: add Open Library provider with relevance filtering"
```

---

### Task 4: Localized edition resolution

**Files:**
- Modify: `ReadUpBackend/src/services/search/openlibrary.provider.ts`
- Modify: `ReadUpBackend/src/services/search/openlibrary.provider.test.ts`

**Interfaces:**
- Consumes: `workIdFromKey`, `coverUrlFor` from Task 3.
- Produces: `localizedEdition(workId: string, lang: SupportedLanguage): Promise<LocalizedEdition | null>` where

```ts
interface LocalizedEdition {
    title: string;
    coverUrl: string | null;
    totalPages: number | null;
}
```

  Used by Task 5.

Open Library indexes works under their canonical English title, so "harry potter" yields *Harry Potter and the Philosopher's Stone* rather than *a Pedra Filosofal*. The Portuguese editions are on the work's editions endpoint. The `editions` sub-object of `search.json` returns `numFound: 0` in practice and cannot be used for this.

- [ ] **Step 1: Write the failing test**

Append to `src/services/search/openlibrary.provider.test.ts`:

```ts
test('localizedEdition escolhe a primeira edição no idioma pedido', async () => {
    const { urls } = stubFetch({
        entries: [
            { title: 'Harry Potter and the Sorcerer\'s Stone', languages: [{ key: '/languages/eng' }], covers: [1], number_of_pages: 309 },
            { title: 'Harry Potter e a Pedra Filosofal', languages: [{ key: '/languages/por' }], covers: [42], number_of_pages: 264 },
        ],
    });

    const edition = await localizedEdition('OL82563W', 'pt');

    assert.ok(urls[0].includes('/works/OL82563W/editions.json'));
    assert.equal(edition?.title, 'Harry Potter e a Pedra Filosofal');
    assert.equal(edition?.coverUrl, 'https://covers.openlibrary.org/b/id/42-M.jpg');
    assert.equal(edition?.totalPages, 264);
});

test('localizedEdition devolve null quando não há edição no idioma', async () => {
    stubFetch({
        entries: [
            { title: 'Only English', languages: [{ key: '/languages/eng' }], covers: [1] },
        ],
    });
    assert.equal(await localizedEdition('OL1W', 'pt'), null);
});

test('localizedEdition ignora edição sem título', async () => {
    stubFetch({
        entries: [
            { languages: [{ key: '/languages/por' }], covers: [1] },
            { title: 'Título Válido', languages: [{ key: '/languages/por' }], covers: [2] },
        ],
    });
    const edition = await localizedEdition('OL1W', 'pt');
    assert.equal(edition?.title, 'Título Válido');
});

test('localizedEdition tolera edição sem capa e sem páginas', async () => {
    stubFetch({
        entries: [{ title: 'Sem Nada', languages: [{ key: '/languages/por' }] }],
    });
    const edition = await localizedEdition('OL1W', 'pt');
    assert.equal(edition?.coverUrl, null);
    assert.equal(edition?.totalPages, null);
});

test('localizedEdition devolve null quando a Open Library falha', async () => {
    mock.method(globalThis, 'fetch', async () => new Response('boom', { status: 500 }));
    assert.equal(await localizedEdition('OL1W', 'pt'), null);
});
```

Add `localizedEdition` to the import block at the top of the file.

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: FAIL — `localizedEdition` is not exported.

- [ ] **Step 3: Write the implementation**

Append to `src/services/search/openlibrary.provider.ts`:

```ts
const WORKS_ENDPOINT = 'https://openlibrary.org/works';
// 50 edições cobrem os idiomas populares sem baixar o catálogo inteiro da obra.
const EDITIONS_LIMIT = 50;

export interface LocalizedEdition {
    title: string;
    coverUrl: string | null;
    totalPages: number | null;
}

interface EditionEntry {
    title?: string;
    languages?: { key: string }[];
    covers?: number[];
    number_of_pages?: number;
}

interface EditionsResponse {
    entries?: EditionEntry[];
}

/**
 * Acha a edição da obra no idioma pedido, pra mostrar "Harry Potter e a Pedra
 * Filosofal" em vez do título canônico em inglês.
 *
 * Custa ~1,9s e 40 KB por obra — por isso o serviço resolve só os primeiros
 * resultados e guarda em cache.
 */
export async function localizedEdition(
    workId: string,
    lang: SupportedLanguage
): Promise<LocalizedEdition | null> {
    const marc = toMarcLanguage(lang);
    try {
        const response = await fetch(`${WORKS_ENDPOINT}/${workId}/editions.json?limit=${EDITIONS_LIMIT}`);
        if (!response.ok) return null;

        const data = (await response.json()) as EditionsResponse;
        const match = (data.entries ?? []).find(entry =>
            Boolean(entry.title) &&
            entry.languages?.some(language => language.key === `/languages/${marc}`)
        );
        if (!match) return null;

        return {
            title: match.title as string,
            coverUrl: coverUrlFor(match.covers?.[0]),
            totalPages: match.number_of_pages ?? null,
        };
    } catch (error) {
        console.error('Open Library editions unreachable:', error);
        return null;
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: PASS, 26 tests total.

- [ ] **Step 5: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add src/services/search/openlibrary.provider.ts src/services/search/openlibrary.provider.test.ts
git commit -m "feat: resolve localized edition titles from Open Library"
```

---

### Task 5: Search service orchestration

**Files:**
- Create: `ReadUpBackend/src/services/search/google-books.provider.ts`
- Create: `ReadUpBackend/src/services/search/book-search.service.ts`
- Create: `ReadUpBackend/src/services/search/book-search.service.test.ts`

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces: `class BookSearchService` with

```ts
search(options: { query: string; lang?: string; maxResults?: number; startIndex?: number }): Promise<SearchBookDTO[]>
browse(options: { subject: string; lang?: string; maxResults?: number }): Promise<SearchBookDTO[]>
```

  Used by Task 6.

- [ ] **Step 1: Write the Google Books fallback provider**

Create `src/services/search/google-books.provider.ts`:

```ts
import { SearchBookDTO } from '../../dtos/book.dto';
import { SupportedLanguage } from './language';

/**
 * Google Books reduzido ao papel de rede de segurança: só entra quando a Open
 * Library não devolve nada (fora do ar, ou título brasileiro que ela não indexa).
 *
 * Sem ranking, sem re-score, sem curadoria — tudo isso vivia aqui e foi deletado
 * porque tentava reconstruir "obra canônica" a partir de um índice de edições.
 */

const ENDPOINT = 'https://www.googleapis.com/books/v1/volumes';

interface GoogleVolume {
    id: string;
    volumeInfo?: {
        title?: string;
        authors?: string[];
        description?: string;
        pageCount?: number;
        language?: string;
        publishedDate?: string;
        imageLinks?: { thumbnail?: string; smallThumbnail?: string };
    };
}

interface GoogleResponse {
    items?: GoogleVolume[];
}

function normalizeCoverUrl(url?: string): string | null {
    if (!url) return null;
    // O edge=curl quebra o render da capa; http quebra em ATS.
    return url.replace(/^http:\/\//, 'https://').replace('&edge=curl', '').trim();
}

function toDTO(volume: GoogleVolume): SearchBookDTO {
    const info = volume.volumeInfo ?? {};
    return {
        id: volume.id,
        title: info.title ?? 'Untitled',
        author: info.authors?.join(', ') ?? null,
        totalPages: info.pageCount ?? 0,
        details: info.description?.trim() ?? null,
        coverUrl: normalizeCoverUrl(info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail),
        language: info.language ?? 'en',
        publishedDate: info.publishedDate ?? null,
    };
}

export async function searchFallback(
    query: string,
    lang: SupportedLanguage,
    limit: number
): Promise<SearchBookDTO[]> {
    const apiKey = process.env.GOOGLE_BOOKS_API_KEY;
    if (!apiKey) return [];

    const params = new URLSearchParams({
        q: `"${query.replace(/"/g, '')}"`,
        langRestrict: lang,
        printType: 'books',
        maxResults: String(Math.min(limit, 40)),
        key: apiKey,
    });

    try {
        const response = await fetch(`${ENDPOINT}?${params.toString()}`);
        if (!response.ok) return [];
        const data = (await response.json()) as GoogleResponse;
        return (data.items ?? [])
            .filter(volume => Boolean(volume.volumeInfo?.title))
            .map(toDTO);
    } catch (error) {
        console.error('Google Books fallback unreachable:', error);
        return [];
    }
}
```

- [ ] **Step 2: Write the failing test**

Create `src/services/search/book-search.service.test.ts`:

```ts
import { test, mock, afterEach } from 'node:test';
import assert from 'node:assert';
import { BookSearchService } from './book-search.service';

afterEach(() => mock.restoreAll());

/**
 * Stub de fetch por rota. Cada chamada escolhe a resposta pelo trecho da URL,
 * porque um search dispara search.json e várias editions.json.
 */
function stubRoutes(routes: { match: string; body: unknown; status?: number }[]): { urls: string[] } {
    const urls: string[] = [];
    mock.method(globalThis, 'fetch', async (url: string) => {
        const target = String(url);
        urls.push(target);
        const route = routes.find(r => target.includes(r.match));
        if (!route) return new Response('{}', { status: 404 });
        return new Response(JSON.stringify(route.body), { status: route.status ?? 200 });
    });
    return { urls };
}

const HP_DOC = {
    key: '/works/OL82563W',
    title: 'Harry Potter and the Philosopher\'s Stone',
    author_name: ['J. K. Rowling'],
    cover_i: 15155833,
    number_of_pages_median: 302,
    readinglog_count: 23274,
    first_publish_year: 1997,
    description: 'Sinopse.',
};

const FANFIC_DOC = {
    key: '/works/OL999W',
    title: 'Harry Potter Fan Story',
    author_name: ['Anônimo'],
    cover_i: 5,
    readinglog_count: 1,
};

const PT_EDITIONS = {
    entries: [
        { title: 'Harry Potter e a Pedra Filosofal', languages: [{ key: '/languages/por' }], covers: [42], number_of_pages: 264 },
    ],
};

test('busca devolve a obra popular e corta o derivado obscuro', async () => {
    stubRoutes([
        { match: 'search.json', body: { docs: [HP_DOC, FANFIC_DOC] } },
        { match: 'editions.json', body: PT_EDITIONS },
    ]);

    const results = await new BookSearchService().search({ query: 'harry potter', lang: 'pt' });

    assert.equal(results.length, 1);
    assert.equal(results[0].id, 'OL82563W');
});

test('busca em português substitui título e capa pela edição PT', async () => {
    stubRoutes([
        { match: 'search.json', body: { docs: [HP_DOC] } },
        { match: 'editions.json', body: PT_EDITIONS },
    ]);

    const results = await new BookSearchService().search({ query: 'harry potter', lang: 'pt' });

    assert.equal(results[0].title, 'Harry Potter e a Pedra Filosofal');
    assert.equal(results[0].coverUrl, 'https://covers.openlibrary.org/b/id/42-M.jpg');
    assert.equal(results[0].totalPages, 264);
});

test('mantém o dado da obra quando a edição PT não tem páginas', async () => {
    stubRoutes([
        { match: 'search.json', body: { docs: [HP_DOC] } },
        { match: 'editions.json', body: { entries: [{ title: 'Pedra Filosofal', languages: [{ key: '/languages/por' }] }] } },
    ]);

    const results = await new BookSearchService().search({ query: 'harry potter', lang: 'pt' });

    assert.equal(results[0].title, 'Pedra Filosofal');
    assert.equal(results[0].totalPages, 302, 'cai para number_of_pages_median da obra');
});

test('busca em inglês não chama editions.json', async () => {
    const { urls } = stubRoutes([{ match: 'search.json', body: { docs: [HP_DOC] } }]);

    await new BookSearchService().search({ query: 'harry potter', lang: 'en' });

    assert.equal(urls.filter(u => u.includes('editions.json')).length, 0);
});

test('cai no Google quando a Open Library não devolve nada', async () => {
    const { urls } = stubRoutes([
        { match: 'openlibrary.org/search.json', body: { docs: [] } },
        { match: 'googleapis.com', body: { items: [{ id: 'g1', volumeInfo: { title: 'Torto Arado', authors: ['Itamar Vieira Junior'], pageCount: 264 } }] } },
    ]);
    process.env.GOOGLE_BOOKS_API_KEY = 'test-key';

    const results = await new BookSearchService().search({ query: 'torto arado', lang: 'pt' });

    assert.ok(urls.some(u => u.includes('googleapis.com')));
    assert.equal(results[0].title, 'Torto Arado');
});

test('query com menos de dois caracteres não chama rede nenhuma', async () => {
    const { urls } = stubRoutes([{ match: 'search.json', body: { docs: [HP_DOC] } }]);

    const results = await new BookSearchService().search({ query: 'h', lang: 'pt' });

    assert.deepEqual(results, []);
    assert.equal(urls.length, 0);
});

test('browse por gênero usa cache na segunda chamada', async () => {
    const { urls } = stubRoutes([
        { match: 'search.json', body: { docs: [HP_DOC] } },
        { match: 'editions.json', body: PT_EDITIONS },
    ]);

    const service = new BookSearchService();
    await service.browse({ subject: 'fantasy', lang: 'pt' });
    const afterFirst = urls.length;
    await service.browse({ subject: 'fantasy', lang: 'pt' });

    assert.equal(urls.length, afterFirst, 'segunda chamada não bateu na rede');
});

test('browse aceita o prefixo subject: que o app já envia', async () => {
    const { urls } = stubRoutes([
        { match: 'search.json', body: { docs: [HP_DOC] } },
        { match: 'editions.json', body: PT_EDITIONS },
    ]);

    await new BookSearchService().browse({ subject: 'subject:fantasy', lang: 'pt' });

    const url = decodeURIComponent(urls[0]);
    assert.ok(url.includes('q=subject:fantasy'));
    assert.ok(!url.includes('subject:subject:'), 'prefixo não pode ser duplicado');
});

test('pede mais que o limite à OL, porque o filtro descarta parte', async () => {
    const { urls } = stubRoutes([
        { match: 'search.json', body: { docs: [HP_DOC] } },
        { match: 'editions.json', body: PT_EDITIONS },
    ]);

    await new BookSearchService().search({ query: 'harry potter', lang: 'pt', maxResults: 20 });

    assert.ok(urls[0].includes('limit=40'), 'sem sobrebusca a página sai curta e o scroll infinito para cedo');
});

test('respeita maxResults', async () => {
    const docs = Array.from({ length: 30 }, (_, i) => ({ ...HP_DOC, key: `/works/OL${i}W` }));
    stubRoutes([
        { match: 'search.json', body: { docs } },
        { match: 'editions.json', body: PT_EDITIONS },
    ]);

    const results = await new BookSearchService().search({ query: 'harry potter', lang: 'pt', maxResults: 5 });

    assert.equal(results.length, 5);
});
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: FAIL — `Cannot find module './book-search.service'`.

- [ ] **Step 4: Write the implementation**

Create `src/services/search/book-search.service.ts`:

```ts
import { SearchBookDTO } from '../../dtos/book.dto';
import { resolveLanguage, SupportedLanguage } from './language';
import { browseSubject, filterDocs, localizedEdition, searchWorks, toDTO, LocalizedEdition } from './openlibrary.provider';
import { searchFallback } from './google-books.provider';
import { TtlCache } from './ttl-cache';

/**
 * Orquestra a busca de livros: Open Library como índice, Google Books como rede
 * de segurança, edição localizada e cache.
 */

const DEFAULT_MAX_RESULTS = 20;
const MAX_RESULTS_CAP = 40;
const MIN_QUERY_LENGTH = 2;
// Resolver a edição PT custa um request por obra; só vale pros que aparecem primeiro.
const LOCALIZE_LIMIT = 10;
// Pedimos mais que o limite porque o filtro descarta parte. Sem isso, uma página que
// chega cheia da OL sai curta daqui, e o app interpreta lista curta como "acabou" e
// para o scroll infinito. Páginas podem repetir item; o app já deduplica por id.
const OVERFETCH_FACTOR = 2;

// Edição em português de uma obra não muda: TTL longo é seguro.
const EDITION_TTL_MS = 24 * 60 * 60 * 1000;
// Vitrine de gênero é igual pra todo usuário do mesmo idioma e abre a cada sessão.
const GENRE_TTL_MS = 6 * 60 * 60 * 1000;

// Busca livre digitada NÃO é cacheada: cada usuário digita algo diferente, o acerto
// seria baixo e o custo de resultado velho é real.
const editionCache = new TtlCache<LocalizedEdition | null>(EDITION_TTL_MS);
const genreCache = new TtlCache<SearchBookDTO[]>(GENRE_TTL_MS);

export interface SearchOptions {
    query: string;
    lang?: string;
    maxResults?: number;
    startIndex?: number;
}

export interface BrowseOptions {
    subject: string;
    lang?: string;
    maxResults?: number;
}

export class BookSearchService {
    async search(options: SearchOptions): Promise<SearchBookDTO[]> {
        const query = options.query.trim();
        if (query.length < MIN_QUERY_LENGTH) return [];

        const lang = resolveLanguage(query, options.lang);
        const limit = this.clampLimit(options.maxResults);
        const offset = Math.max(options.startIndex ?? 0, 0);

        const docs = filterDocs(await searchWorks(query, lang, limit * OVERFETCH_FACTOR, offset));

        // Open Library vazia: fora do ar, ou título brasileiro que ela não indexa.
        if (docs.length === 0) {
            return searchFallback(query, lang, limit);
        }

        return this.localize(docs.slice(0, limit).map(toDTO), lang);
    }

    async browse(options: BrowseOptions): Promise<SearchBookDTO[]> {
        // O app manda `subject:fantasy`; a query aqui é só o assunto.
        const subject = options.subject.replace(/^subject:/i, '').trim().toLowerCase();
        if (subject.length === 0) return [];

        const lang = this.normalizeLang(options.lang);
        const limit = this.clampLimit(options.maxResults);

        const cacheKey = `${subject}:${lang}`;
        const cached = genreCache.get(cacheKey);
        if (cached) return cached.slice(0, limit);

        const docs = filterDocs(await browseSubject(subject, lang, limit));
        const results = await this.localize(docs.map(toDTO), lang);

        genreCache.set(cacheKey, results);
        return results;
    }

    private clampLimit(maxResults?: number): number {
        return Math.min(Math.max(maxResults ?? DEFAULT_MAX_RESULTS, 1), MAX_RESULTS_CAP);
    }

    private normalizeLang(lang?: string): SupportedLanguage {
        return lang?.toLowerCase().startsWith('pt') ? 'pt' : 'en';
    }

    /**
     * Troca título e capa pelos da edição no idioma do usuário. Só os primeiros
     * resultados, em paralelo, com cache por obra — cada obra custa ~1,9s e 40 KB.
     * Em inglês não faz nada: o título da obra já é o canônico em inglês.
     */
    private async localize(books: SearchBookDTO[], lang: SupportedLanguage): Promise<SearchBookDTO[]> {
        if (lang !== 'pt') return books;

        const head = books.slice(0, LOCALIZE_LIMIT);
        const tail = books.slice(LOCALIZE_LIMIT);

        const localized = await Promise.all(head.map(async book => {
            const cacheKey = `${book.id}:${lang}`;
            let edition = editionCache.get(cacheKey);
            if (edition === undefined) {
                edition = await localizedEdition(book.id, lang);
                editionCache.set(cacheKey, edition);
            }
            if (!edition) return book;

            return {
                ...book,
                title: edition.title,
                coverUrl: edition.coverUrl ?? book.coverUrl,
                // A edição costuma não trazer páginas; a mediana da obra é melhor que zero.
                totalPages: edition.totalPages ?? book.totalPages,
                language: 'por',
            };
        }));

        return [...localized, ...tail];
    }
}
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm test
```

Expected: PASS, 36 tests total.

- [ ] **Step 6: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add src/services/search/google-books.provider.ts src/services/search/book-search.service.ts src/services/search/book-search.service.test.ts
git commit -m "feat: add book search orchestration over Open Library"
```

---

### Task 6: Wire the controller and delete the old engine

**Files:**
- Modify: `ReadUpBackend/src/controllers/book.controller.ts:1-27`
- Delete: `ReadUpBackend/src/services/google-books.service.ts`
- Delete: `ReadUpBackend/src/services/genre-seeds.ts`

**Interfaces:**
- Consumes: `BookSearchService` from Task 5.
- Produces: `GET /books/search` served by the new engine, with the same request and response contract.

- [ ] **Step 1: Swap the service in the controller**

In `src/controllers/book.controller.ts`, replace the import on line 3 and the field on line 8:

```ts
import { BookSearchService } from '../services/search/book-search.service';
```

```ts
private bookSearchService = new BookSearchService();
```

Then replace the `search` handler (lines 10–27) with:

```ts
    // Busca de livros: Open Library como índice, Google Books como fallback.
    // `mode=browse` é a vitrine por gênero; qualquer outro valor é busca livre.
    search = async (req: AuthRequest, res: Response): Promise<void> => {
        try {
            const q = (req.query.q as string | undefined)?.trim() ?? '';
            const lang = req.query.lang as string | undefined;
            const maxResults = req.query.maxResults ? Number(req.query.maxResults) : undefined;

            const results = req.query.mode === 'browse'
                ? await this.bookSearchService.browse({ subject: q, lang, maxResults })
                : await this.bookSearchService.search({
                    query: q,
                    lang,
                    maxResults,
                    startIndex: req.query.startIndex ? Number(req.query.startIndex) : undefined,
                });

            res.status(200).json(results);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };
```

The `country` query parameter is dropped: Open Library has no equivalent, and the app never sent it.

- [ ] **Step 2: Delete the old engine**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git rm src/services/google-books.service.ts src/services/genre-seeds.ts
```

- [ ] **Step 3: Verify nothing else references the deleted files**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && grep -rn "google-books.service\|genre-seeds\|GoogleBooksService" src/
```

Expected: no output. If anything appears, fix that import before continuing.

- [ ] **Step 4: Verify the build and the full suite**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npx tsc --noEmit && npm test
```

Expected: no type errors, 36 tests passing.

- [ ] **Step 5: Commit**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend
git add src/controllers/book.controller.ts
git commit -m "feat: serve /books/search from Open Library, delete Google ranking layer"
```

---

### Task 7: Verify against the live API and hand off

**Files:**
- Create: `ReadUp/.claude/handoff/2026-08-05-cycle-1-open-library-search.md`

**Interfaces:**
- Consumes: the running server.
- Produces: evidence that the spec's success criteria hold against the real Open Library, not against stubs.

Every test so far stubs `fetch`. This task is the only one that touches the live API, and it is the one that answers the question the user actually asked.

- [ ] **Step 1: Start the server**

```bash
cd /Users/antoniocosta/Desktop/Projects/ReadUp/ReadUpBackend && npm run dev
```

Leave it running in a background shell.

- [ ] **Step 2: Verify the search that motivated this whole cycle**

```bash
curl -s "http://localhost:3000/books/search?q=harry%20potter&lang=pt&maxResults=8" | grep -o '"title":"[^"]*"'
```

Expected: Harry Potter titles by Rowling, in Portuguese where an edition exists. No fanfic, no study guides, no "The Americana Annual".

If the port is not 3000, check `src/server.ts` for the actual value and use that in every step below.

- [ ] **Step 3: Verify the second success criterion**

```bash
curl -s "http://localhost:3000/books/search?q=sapiens&lang=pt&maxResults=5" | grep -o '"title":"[^"]*"\|"author":"[^"]*"'
```

Expected: Harari's *Sapiens* first.

- [ ] **Step 4: Verify genre browsing with no curated list**

```bash
curl -s "http://localhost:3000/books/search?q=subject:fantasy&mode=browse&lang=pt&maxResults=6" | grep -o '"title":"[^"]*"'
```

Expected: recognizable, popular fantasy. `genre-seeds.ts` no longer exists, so this comes entirely from Open Library.

- [ ] **Step 5: Verify the cache actually saves the round trip**

```bash
time curl -s -o /dev/null "http://localhost:3000/books/search?q=subject:fantasy&mode=browse&lang=pt"
time curl -s -o /dev/null "http://localhost:3000/books/search?q=subject:fantasy&mode=browse&lang=pt"
```

Expected: the second call is dramatically faster (cache hit). Record both numbers in the handoff.

- [ ] **Step 6: Verify the app still works untouched**

Build and run the iOS app against this backend. Open the Search tab, confirm genre sections load, type "harry potter", confirm results appear with covers, and open one result to confirm the details sheet shows a synopsis and a page count.

This is the real assertion of the cycle's central constraint: the app was not modified and did not need to be.

- [ ] **Step 7: Write the handoff**

Create `.claude/handoff/2026-08-05-cycle-1-open-library-search.md` following the format in `.claude/handoff/README.md`. Include:

- The real `curl` output from Steps 2–4, pasted, not summarized.
- The two timings from Step 5.
- The final line count removed: `git show --stat` for the Task 6 commit.
- Any behavior that differs from the plan, and why.

- [ ] **Step 8: Commit**

```bash
cd /Users/antoniocosta/Documents/Academy/ReadUp
git add .claude/handoff/
git commit -m "docs: add cycle 1 handoff for Open Library search"
```

---

## Done when

- `npm test` passes with 36 tests in the backend.
- `npx tsc --noEmit` reports no errors.
- `GET /books/search?q=harry potter` returns the Rowling series and nothing else.
- `GET /books/search?q=subject:fantasy&mode=browse` returns popular fantasy with no curated seed list in the repository.
- `google-books.service.ts` and `genre-seeds.ts` no longer exist.
- The iOS app works against the new backend **with no code changes**.
- The handoff records real command output, not claims.
