# DEPLOYMENT.md – Projeto SAVE

## 1. Objetivo
Definir como o Projeto SAVE é executado e publicado com segurança:
- ambientes (local, staging, production)
- variáveis de ambiente (secrets)
- Supabase (DB, Auth, Storage, Edge Functions)
- Hosting do frontend (ex: Vercel)
- webhooks de pagamento
- regras de promoção de versão

Regras:
- segredos nunca entram no git
- staging é obrigatório antes de production
- tudo deve ser reproduzível por script

---

## 2. Ambientes

### 2.1 Local
Uso:
- desenvolvimento
- testes
- seed de dados

Características:
- Supabase local (CLI) com Postgres e Auth local
- Storage local
- Sem cobrança real (pagamento em modo sandbox)

---

### 2.2 Staging
Uso:
- validação de releases
- testes de integração reais com webhooks em sandbox

Características:
- Supabase separado do prod
- Frontend publicado em domínio/staging subdomínio
- Webhooks apontando para staging (sandbox)

---

### 2.3 Production
Uso:
- usuários reais
- cobrança real

Características:
- Supabase prod
- Frontend prod
- Webhooks reais
- logs e auditoria permanentes

---

## 3. Plataformas e responsabilidades

### 3.1 Supabase
Responsável por:
- Postgres + RLS
- Auth
- Storage (logos, imagens de lições, downloads)
- Edge Functions (webhooks e operações internas)
- Migrations do schema

---

### 3.2 Frontend hosting (ex: Vercel)
Responsável por:
- build e deploy do frontend
- roteamento
- SSR/ISR se aplicável

Notas:
- não hospedar frontend “em qualquer lugar” sem pipeline; preferir Vercel para reduzir risco com agents.

---

## 4. Domínios e URLs (exemplo)
Definir no projeto:
- `app.projetosave.com` (prod)
- `staging.projetosave.com` (staging)
- `localhost:3000` (local)

Supabase:
- `https://<project>.supabase.co` (prod)
- `https://<project-staging>.supabase.co` (staging)

---

## 5. Variáveis de ambiente

### 5.1 Frontend (public)
Exemplos:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Regras:
- apenas chaves públicas
- nunca colocar service role no frontend

---

### 5.2 Backend / Edge Functions (secret)
Exemplos:
- `SUPABASE_SERVICE_ROLE_KEY` (somente server-side)
- `PAYMENTS_WEBHOOK_SECRET` (Stripe ou provedor)
- `PAYMENTS_API_KEY`
- `APP_BASE_URL` (para links em e-mails)

Regras:
- segredos só em vault / env manager
- nenhum segredo em `.env.example` além de placeholders

---

## 6. Migrations (schema + RLS)

### 6.1 Regras
- toda mudança no DB deve ser migration versionada
- migrations devem rodar em:
  - local
  - staging
  - prod (via pipeline)

### 6.2 Ordem recomendada
1. schema (tabelas, constraints, indexes)
2. funções helper (is_member, is_admin, leads_group etc.)
3. RLS policies
4. RPCs
5. seeds (somente local/staging)

---

## 7. Storage (imagens e mídia)

### 7.1 Buckets sugeridos
- `public-assets` (logos e assets públicos controlados)
- `lesson-media` (imagens e vídeos referenciados em lições)
- `downloads` (arquivos para download)

Regras:
- cada bucket deve ter policy explícita
- mídia de lição pode ser pública ou semi-pública conforme decisão:
  - se conteúdo só deve aparecer para logados, não deixar público

---

## 8. Pagamentos e webhooks

### 8.1 Provedor
Escolher um provedor (ex: Stripe) e padronizar contratos em `API_CONTRACTS.md`.

### 8.2 Webhook endpoint
- Edge Function: `payments_webhook()`

Regras:
- validar assinatura do webhook
- idempotência:
  - registrar em `webhook_logs` com unique(provider, event_id)
- nunca confiar no frontend para liberar acesso

### 8.3 Fluxos
#### Individual
- criar org type `individual`
- ativar subscription no `org_subscriptions`
- provisionar 1 seat de disciple inicial no `org_license_pool`

#### Igreja
- atualizar `org_license_pool` incrementando totals
- manter histórico de compra (futuro: tabela de invoices)

---

## 9. Promoção de releases

### 9.1 Checklist Staging -> Prod
- migrations aplicadas em staging
- testes de banco e integração passam
- testes de webhook em sandbox passam
- verificação manual mínima (TESTING_STRATEGY.md)

### 9.2 Rollback
- frontend: rollback via plataforma (Vercel)
- DB: preferir migrations reversíveis quando possível
- nunca editar schema manualmente em prod

---

## 10. Observabilidade mínima

### 10.1 Logs
- Edge Functions: logs do Supabase
- DB: `audit_events` para rastrear ações sensíveis
- Webhooks: `webhook_logs`

### 10.2 Alertas (futuro)
- falhas recorrentes em webhooks
- spikes de erros 403 (RLS)
- spikes de 500

---

## 11. Regras finais
- Local sempre deve conseguir subir com 1 comando.
- Staging deve ser o espelho do prod.
- Acesso só é liberado por backend (RLS/RPC/webhook), nunca por frontend.