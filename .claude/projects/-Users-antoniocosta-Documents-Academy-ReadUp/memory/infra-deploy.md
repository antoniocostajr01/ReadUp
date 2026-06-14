---
name: infra-deploy
description: ReadUp backend/DB hosting — Render, Supabase, Resend, env vars, keep-alive.
metadata:
  type: project
---

ReadUp em produção (configurado em 2026-06-13):

- **API:** backend Node/Express hospedado no **Render** (free tier) em `https://readupbackend.onrender.com`. Build: `npm install && npm run build`; start: `npm run start`. Free tier dorme após 15 min → **Cron-Job.org** pinga `GET /` a cada 10 min pra manter acordado.
- **Banco:** **Supabase** (Postgres, projeto `aqemlwdcycksxlozekdi`, região us-east-2). Prisma usa `DATABASE_URL` (pooler 6543, `?pgbouncer=true`) + `DIRECT_URL` (5432, pras migrations via `directUrl` no schema).
- **Email (forgot password):** **Resend** (free). No plano grátis sem domínio verificado, **só envia pro email da conta Resend** (`antonioclaudiocostajr@gmail.com`). Remetente: `onboarding@resend.dev`.
- **Env vars no Render:** `DATABASE_URL`, `DIRECT_URL`, `JWT_SECRET`, `GROQ_API_KEY`, `RESEND_API_KEY`, `RESEND_FROM`, `APPLE_CLIENT_ID=com.antoniocosta.ReadUp`. O `.env` local é gitignored.
- **iOS baseURL:** vem de `BASEURL` no `Secrets.xcconfig` (gitignored) → Info.plist → `AppConfig.baseURL`. No xcconfig usa o truque `https:/$()/...` porque `//` é comentário. Pra dev local, trocar pra localhost no Secrets.

Auth endpoints: `POST /users` (registro), `POST /auth/login`, `POST /auth/apple` (verifica identityToken via lib apple-signin-auth), `POST /auth/forgot-password`, `POST /auth/reset-password`. Ver [[auth-architecture]].
