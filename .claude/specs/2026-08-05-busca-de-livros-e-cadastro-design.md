# Busca de livros e cadastro — design

**Data:** 2026-08-05
**Status:** aprovado, aguardando plano de implementação
**Repositórios afetados:** `ReadUp` (app iOS) e `ReadUpBackend` (API Node/Prisma)

---

## Problema

Usuários reclamam que a busca devolve livros sem relação com o que foi pesquisado.

A causa não é a qualidade dos dados do Google Books — é o **modelo de dados** dele. A Google Books API indexa *edições* (volumes), não *obras*. Cada reimpressão, print-on-demand, resumo e guia de estudo é um item independente no índice, e o sinal de popularidade (`ratingsCount`) vem vazio na maioria dos registros. Não existe, na resposta, informação suficiente pra distinguir "o livro que o usuário quer" de "derivado genérico com título parecido".

`google-books.service.ts` já tem 384 linhas tentando reconstruir esse conceito por fora: busca por frase exata em `intitle:`/`inauthor:`, re-ranking por recência, popularidade e idioma, regex pra descartar resumos e guias, e listas curadas à mão por gênero. Continua perdendo, porque o dado que falta não está na resposta.

Dois problemas colaterais confirmados durante a investigação:

- A chave do Google já está batendo no teto de quota (`RESOURCE_EXHAUSTED`).
- As seções de gênero não usam busca de verdade: usam `genre-seeds.ts`, listas de títulos escritas à mão, resolvidas uma a uma. É curadoria manual permanente, por gênero e por idioma.

## Solução

Trocar o índice de busca por um que tenha o conceito de obra, e assumir que **nenhuma fonte única cobre o mercado brasileiro** — daí três caminhos de cadastro em vez de um.

### Escolha da API — evidência

Testes feitos contra as APIs reais, não contra documentação.

**Open Library `search.json`, query "harry potter":**

```
1. Harry Potter and the Philosopher's Stone — J. K. Rowling — 23.274 leitores
2. Harry Potter and the Chamber of Secrets  — J. K. Rowling —  6.595
3. Harry Potter and the Prisoner of Azkaban — J. K. Rowling —  5.638
```

Os sete livros canônicos, zero fanfic. A busca é por obra, e `readinglog_count` é um sinal de popularidade real — exatamente o que separa o livro do derivado. Query "sapiens": Harari em 1º com 5.904 leitores, o ruído abaixo com 26 e 12.

**Navegação por gênero, `subject:fantasy&sort=readinglog`:** Harry Potter, A Game of Thrones, O Alquimista, 1984 — sem ruído, com `language:por` funcionando como filtro. Substitui a curadoria manual inteira.

| API | Custo | Relevância | Cobertura BR | Papel |
|---|---|---|---|---|
| Open Library | grátis, sem key | ótima (obras + popularidade) | média | índice primário |
| Google Books | grátis com key, com quota | ruim (edições soltas) | boa | ISBN + fallback |
| ISBNdb | US$ 15–100/mês | fraca (banco de ISBN, não motor de busca) | boa | descartada |
| Hardcover | grátis (GraphQL) | boa | fraca, anglocêntrica | descartada |
| Goodreads | — | — | — | API descontinuada em 2020 |

### Cobertura de ISBN brasileiro — medição

ISBN-13 de edições brasileiras obtidos via Google Books, consultados na Open Library:

| Livro | ISBN | Open Library |
|---|---|---|
| O Alquimista | 9788576651857 | achou (Rocco) — **sem número de páginas** |
| Sapiens | 9788525432186 | achou (L&PM) — 464 páginas |
| Vidas Secas | 9786552270528 | 404 |
| Dom Casmurro | 9786586490077 | 404 |
| O Pequeno Príncipe | 9798525847606 | 404 |
| A Paciente Silenciosa | 9788501116536 | 404 |
| Torto Arado | 9789896605858 | 404 |

**2 de 7**, e uma das duas veio sem número de páginas — dado do qual todo o cálculo de progresso do ReadUp depende. No mesmo teste, em 5 de 12 títulos o **próprio Google** não tinha ISBN (registros de ebook).

Consequência de projeto: o scanner é uma **cadeia**, não uma fonte. E poder corrigir os dados depois não é um extra — é o caminho normal pra livro brasileiro.

---

## Arquitetura

### Backend — motor de busca

Um orquestrador e dois provedores sem inteligência própria:

```
book-search.service.ts      ranqueia, cacheia, localiza título, decide fallback
├── openlibrary.provider    search / browse por subject / lookup por ISBN
└── google-books.provider   lookup por ISBN + fallback de busca livre
```

**Removido:** `genre-seeds.ts` inteiro, o modo `browse`, a tabela `WEIGHTS`, `resolveSeeds`, `scoreFor` e o bônus de match de título. Cerca de 250 das 384 linhas atuais. A Open Library já ranqueia bem; reconstruir o ranking dela por fora repetiria o erro que gerou o problema.

**Mantido:** `resolveLanguage` (stopwords PT/EN, decide se aplica `language:por`) e `normalizeCoverUrl`.

**Filtro sobre os resultados da OL — três regras:**

1. Descarta resultado sem `author_name`.
2. Descarta resultado sem `cover_i`.
3. Se algum resultado tem `readinglog_count >= 50`, descarta os com `readinglog_count < 5`.

A regra 3 é a que mata fanfic e genérico, e é barata porque o sinal já vem na resposta.

**Endpoints:**

| Rota | Auth | Mudança |
|---|---|---|
| `GET /books/search` | pública | mesma rota, motor novo |
| `GET /books/isbn/:isbn` | pública | nova |

As duas rotas precisam ser declaradas **antes** do `authMiddleware` e **antes** de `/:id`, senão o Express casa `isbn` como id de livro e exige token. O `book.routes.ts` já tem esse cuidado documentado para `/search`.

**Título em português.** A Open Library indexa obras com título canônico em inglês. As edições em português existem (20 na obra do primeiro Harry Potter) e são resolvidas via `/works/{key}/editions.json`. Custo medido: 1,9s e 40 KB por obra. Por isso a resolução é limitada aos **10 primeiros resultados**, em paralelo, com cache.

**Cache.** Dois, com justificativas diferentes:

- **Por obra → título e capa em PT, TTL 24h.** É o que paga os 10 requests extras. Sem ele, cada busca custaria ~4s e 400 KB. Edição em português de uma obra não muda; TTL longo é seguro.
- **Por gênero → resposta pronta, TTL 6h.** Seções de gênero disparam a cada abertura do app e são idênticas pra todo usuário do mesmo gênero e idioma. É o que o `seedCache` já faz hoje.

Busca livre digitada **não** é cacheada: cada usuário digita coisa diferente, a taxa de acerto seria baixa e o custo de resultado velho é real.

Ambos são `Map` em memória: morrem no deploy e não são compartilhados entre instâncias. Aceitável na escala atual; vira Redis quando for problema medido. Registrar com comentário `ponytail:`.

### App — três fluxos de cadastro

O `+` da Library ([Library.swift:48](../../ReadUp/Views/Library.swift)) hoje só pula pra aba Search. Vira um `Menu` nativo com três itens: **Escanear código de barras**, **Buscar**, **Cadastrar manualmente**.

**Um formulário, três entradas.** `BookFormView` é usado em todos os casos:

| Entrada | Estado inicial |
|---|---|
| Cadastro manual | vazio |
| Correção pós-importação | preenchido com o que a API trouxe |
| Edição pela BookDetails | preenchido com o livro salvo |

Campos: capa (`PhotosPicker`), título, autor, páginas, ISBN, descrição, status. Obrigatórios: **título** e **páginas > 0** — páginas porque todo o cálculo de progresso e as sessões de leitura dependem dela.

O backend já suporta essa edição: `PUT /books/:id` aceita `title`, `author`, `totalPages`, `details`, `coverUrl`, `status` e `progress`, e `LibraryStore.applyUpdate` já sabe chamar. Falta só a tela.

**Livro importado é uma cópia**, não um espelho da API. O usuário edita o registro dele e nada sobrescreve depois. É o que o schema já faz.

**Scanner.** `DataScannerViewController` (VisionKit) em `UIViewControllerRepresentable`, símbolos `.ean13` e `.ean8`. Deployment target é iOS 18.5/26, então está disponível sem dependência externa. O `Info.plist` **não tem `NSCameraUsageDescription`** — sem essa chave o app crasha ao abrir a câmera.

Cadeia após a leitura:

```
ISBN escaneado
  → Open Library /isbn/{isbn}.json    (grátis, sem key, sem quota)
  → Google Books q=isbn:{isbn}        (melhor em edição brasileira)
  → BookFormView pré-preenchido com o que veio, ISBN incluso
```

### Dados

Uma migration com três mudanças:

```prisma
model User {
  avatar String? @db.Text        // já no schema, migration nunca aplicada
}

model Book {
  isbn       String?             // do scanner; usado no dedupe
  coverImage String? @db.Text    // capa da galeria, base64
}
```

A foto de perfil **já está implementada** no app ([Profile.swift:41](../../ReadUp/Views/Profile.swift), [AuthManager.swift:204](../../ReadUp/ViewModels/AuthManager.swift)) e no backend (`PUT /users/me`, `UserService.updateProfile`). Só não funciona porque a migration nunca rodou. Não é feature nova.

**Capa enviada pelo usuário.** Guardada em `coverImage` (base64) e servida por `GET /books/:id/cover`. Quando `coverImage` existe, o backend devolve `coverUrl = <API>/books/<id>/cover`. Assim `BookCoverView` continua carregando uma URL comum e não precisa mudar.

Alternativas descartadas: base64 direto no `coverUrl` inflaria toda listagem (`GET /books` devolve a biblioteca inteira — 50 livros a ~200 KB dariam 10 MB por carregamento); storage externo (S3/Supabase) adicionaria infra, credenciais e custo antes de haver necessidade medida.

### Casos-limite

| Situação | Comportamento |
|---|---|
| ISBN não encontrado em nenhuma fonte | Formulário abre com o ISBN preenchido e aviso explicando |
| Permissão de câmera negada | Alerta com atalho pros Ajustes e opção de cadastro manual |
| Open Library indisponível | Busca livre cai no Google Books |
| Livro já na biblioteca | Abre o existente em vez de duplicar — casa por ISBN, senão por título + autor |
| Capa muito grande | Comprimida no app antes do envio; teto defensivo no backend, mesmo padrão do avatar |
| Busca com menos de 2 caracteres | Ignorada, como hoje |

---

## Ciclos de implementação

| # | Ciclo | Entrega |
|---|---|---|
| 0 | Migration + estrutura de documentação | Foto de perfil passa a funcionar; colunas novas no banco; pastas do `.claude/` criadas |
| 1 | Motor de busca | Open Library substitui Google em busca e gênero; ~250 linhas removidas |
| 2 | Formulário único | Cadastro manual, edição e capa da galeria |
| 3 | Scanner | Câmera, cadeia de ISBN, fallback pro formulário |
| 4 | Documentação | `CLAUDE.md` consolidado nos dois repositórios |

O ciclo 0 vem primeiro por dois motivos: destrava a foto de perfil, que já está escrita, e cria as colunas de que os ciclos 2 e 3 dependem.

## Critérios de sucesso

- Buscar "harry potter" devolve os livros da série, sem fanfic nem derivado genérico.
- Buscar "sapiens" devolve o livro do Harari em primeiro.
- Seções de gênero funcionam sem nenhuma lista curada à mão.
- Um livro pode ser cadastrado sem nenhuma API, com capa própria.
- Qualquer campo de qualquer livro pode ser corrigido depois, inclusive os importados.
- Escanear o código de barras de um livro brasileiro leva ao cadastro concluído — com dados da API quando existirem, com o formulário pré-preenchido quando não.
- Foto de perfil salva e persiste.

## Estrutura de documentação

```
CLAUDE.md              raiz do repositório (convenção do Claude Code)
.claude/
  specs/               design docs — este documento é o primeiro
  plans/               plano por ciclo, com status de cada etapa
  handoff/             o que mudou em cada ciclo: arquivos, decisões, pendências
  skills/              skills do projeto
```

`ReadUpBackend` é repositório separado e leva o próprio `CLAUDE.md`. Handoffs que cruzam os dois ficam aqui, referenciando o commit de lá.
