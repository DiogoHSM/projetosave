# DATA_MODEL.md – Projeto SAVE

## 1. Objetivo
Definir o modelo de dados do Projeto SAVE de forma conceitual e precisa, para orientar:
- criação do schema no Postgres (Supabase)
- criação das policies de RLS
- criação de RPCs e Edge Functions
- desenvolvimento do frontend

Este documento evita que agents inventem tabelas, campos ou relações.

---

## 2. Convenções

### 2.1 Identificadores e timestamps
- Chaves primárias: `id uuid`
- Timestamps padrão: `created_at timestamptz`, `updated_at timestamptz`
- Soft delete quando necessário: `status` e opcionalmente `deleted_at timestamptz`

### 2.2 Multi-tenant
- Entidades ligadas à operação de uma organização devem ter `org_id`.
- Conteúdo base (currículo) é global e não tem `org_id`.

### 2.3 Papéis e permissões
- Papéis administrativos são no contexto de `organization_members`.
- Conteúdo do professor (gabaritos e orientações) é sensível e deve ser protegido (sem SELECT direto, somente RPC).

### 2.4 Storage
- Imagens e arquivos ficam no Supabase Storage.
- As tabelas armazenam apenas metadados e URLs (ou `storage_path`).

---

## 3. Domínios e enums recomendados

### 3.1 organizations.type
- `individual`
- `church`

### 3.2 organization_members.status
- `active`
- `inactive`

### 3.3 invites.status
- `pending`
- `accepted`
- `revoked`
- `expired`

### 3.4 discipleships.status
- `active`
- `completed`
- `archived`

### 3.5 lesson_blocks.type
- `rich_text`
- `image`
- `video`
- `download`
- `callout`

### 3.6 questions.type
- `open_text`
- `multiple_choice`
- `matching`
- `true_false`

### 3.7 answers.status
- `draft`
- `submitted`
- `in_review`
- `needs_changes`
- `approved`

---

## 4. Entidades e tabelas

## 4.1 Identidade e preferências

### 4.1.1 users (Supabase Auth)
- Fonte: `auth.users` (não duplicar)
- Dados de perfil opcionais podem ficar em `public.user_profiles` se necessário.

Opcional:
#### public.user_profiles
Campos:
- id uuid (FK auth.users.id, PK)
- display_name text
- avatar_url text
- created_at, updated_at

### 4.1.2 user_preferences
Objetivo:
- Guardar preferências do usuário, incluindo contexto ativo.

Campos:
- id uuid (PK)
- user_id uuid (FK auth.users.id, unique)
- active_org_id uuid (FK organizations.id, nullable)
- active_mode text (ex: `mentor` ou `disciple`, nullable)
- ui_prefs jsonb (tema, etc.)
- created_at, updated_at

---

## 4.2 Organizações e memberships

### 4.2.1 organizations
Campos:
- id uuid (PK)
- type text (individual, church)
- name text
- owner_user_id uuid (FK auth.users.id, nullable)
- status text (active/inactive)
- created_at, updated_at

Notas:
- Branding pode ficar em tabela separada (recomendado), mas não é obrigatório no MVP.

### 4.2.2 organization_members
Objetivo:
- Vínculo de usuário com organização e seus papéis administrativos.

Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- user_id uuid (FK auth.users.id)
- status text (active/inactive)
- role_admin_org boolean default false
- role_group_leader boolean default false
- created_at, updated_at

Constraints:
- unique(org_id, user_id)

---

## 4.3 Igreja: grupos e escopo

### 4.3.1 groups
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- name text
- description text nullable
- status text (active/inactive)
- created_at, updated_at

### 4.3.2 group_memberships
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- group_id uuid (FK groups.id)
- user_id uuid (FK auth.users.id)
- created_at, updated_at

Constraints:
- unique(org_id, group_id, user_id)

### 4.3.3 group_leaders
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- group_id uuid (FK groups.id)
- leader_user_id uuid (FK auth.users.id)
- created_at, updated_at

Constraints:
- unique(org_id, group_id, leader_user_id)

### 4.3.4 org_group_leader_quotas
Objetivo:
- Controlar limite de distribuição do líder de grupo.

Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- leader_user_id uuid (FK auth.users.id)
- quota_disciple_seats int default 0
- quota_mentor_seats int default 0
- scope_group_id uuid (FK groups.id, nullable)
- created_at, updated_at

---

## 4.4 Convites

### 4.4.1 invites
Objetivo:
- Convite por e-mail para entrar na org e opcionalmente entrar em grupos e receber licenças.

Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- email text
- token_hash text
- status text (pending/accepted/revoked/expired)
- expires_at timestamptz
- invited_by_user_id uuid (FK auth.users.id)

- invited_role_admin_org boolean default false
- invited_role_group_leader boolean default false

- invited_as_mentor boolean default false
- invited_as_disciple boolean default true

- group_id uuid (FK groups.id, nullable)
  - Importante: quando convite é criado por group_leader, group_id deve estar preenchido e referenciar um grupo que ele lidera

- grant_disciple_seats int default 0
- grant_mentor_seats int default 0

- accepted_by_user_id uuid nullable
- accepted_at timestamptz nullable

- created_at, updated_at

Notas:
- Token nunca em texto puro.
- Convites são criados e aceitos via RPC, não via client.

---

## 4.5 Licenças e billing

### 4.5.1 org_subscriptions
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- provider text (stripe, etc.)
- provider_customer_id text nullable
- provider_subscription_id text nullable
- status text (active, past_due, canceled, trialing, etc.)
- current_period_start timestamptz nullable
- current_period_end timestamptz nullable
- created_at, updated_at

### 4.5.2 org_license_pool
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- disciple_seats_total int default 0
- disciple_seats_used int default 0
- mentor_seats_total int default 0
- mentor_seats_used int default 0
- updated_by_user_id uuid nullable
- created_at, updated_at

### 4.5.3 org_license_allocations (ajustado para bater com RLS_POLICY_MAP)
Objetivo:
- Alocar seats para um usuário dentro da org, com escopo opcional por grupo.

Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- user_id uuid (FK auth.users.id)

- group_id uuid (FK groups.id, nullable)
  - Para org church: recomendado preencher group_id quando a alocação for controlada por um líder de grupo
  - Para org individual: normalmente null

- disciple_seats_allocated int default 0
- mentor_seats_allocated int default 0

- created_at, updated_at

Constraints:
- unique(org_id, user_id, group_id)

Motivo do formato:
- O RLS_POLICY_MAP usa `leads_group(org_id, group_id)` para permitir que líderes vejam alocações do seu grupo.
- Se `group_id` não existir aqui, a policy precisaria de joins em group_memberships. Para reduzir complexidade, mantemos group_id.

### 4.5.4 discounts
Campos:
- id uuid (PK)
- user_id uuid (FK auth.users.id)
- org_id uuid (FK organizations.id, nullable)
- provider_coupon_id text nullable
- percentage_off int nullable
- amount_off_cents int nullable
- currency text nullable
- valid_until timestamptz nullable
- reason text
- created_at, updated_at

---

## 4.6 Conteúdo global

### 4.6.1 studies
Campos:
- id uuid (PK)
- title text
- description text nullable
- status text (draft/published/archived)
- version int default 1
- created_at, updated_at

### 4.6.2 modules
Campos:
- id uuid (PK)
- study_id uuid (FK studies.id)
- title text
- order_index int
- status text (draft/published/archived)
- created_at, updated_at

### 4.6.3 lessons
Campos:
- id uuid (PK)
- module_id uuid (FK modules.id)
- title text
- order_index int
- estimated_minutes int nullable
- status text (draft/published/archived)
- created_at, updated_at

### 4.6.4 lesson_blocks
Campos:
- id uuid (PK)
- lesson_id uuid (FK lessons.id)
- type text (rich_text/image/video/download/callout)
- order_index int
- title text nullable
- content_markdown text nullable
- media_url text nullable
- storage_path text nullable
- caption text nullable
- metadata jsonb nullable
- created_at, updated_at

### 4.6.5 questions
Campos:
- id uuid (PK)
- lesson_id uuid (FK lessons.id)
- type text
- order_index int
- prompt text
- help_text text nullable
- config jsonb
- created_at, updated_at

Nota:
- Gabarito não fica aqui. Vai para `question_answer_keys`.

---

## 4.7 Conteúdo do professor (sensível)

### 4.7.1 lesson_teacher_notes
Campos:
- id uuid (PK)
- lesson_id uuid (FK lessons.id)
- notes_markdown text
- tips jsonb nullable
- common_mistakes jsonb nullable
- created_at, updated_at

Nota:
- Sem SELECT direto no app. Somente via RPC.

### 4.7.2 question_answer_keys
Campos:
- id uuid (PK)
- question_id uuid (FK questions.id)
- answer_key jsonb
- created_at, updated_at

Nota:
- Sem SELECT direto no app. Somente via RPC.

---

## 4.8 Fluxo do discipulado

### 4.8.1 discipleships
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- mentor_user_id uuid (FK auth.users.id)
- disciple_user_id uuid (FK auth.users.id)
- status text (active/completed/archived)
- started_at timestamptz
- completed_at timestamptz nullable
- archived_at timestamptz nullable
- notes text nullable
- created_at, updated_at

### 4.8.2 lesson_releases
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- discipleship_id uuid (FK discipleships.id)
- lesson_id uuid (FK lessons.id)
- released_by_user_id uuid (FK auth.users.id)
- released_at timestamptz
- created_at, updated_at

Constraints:
- unique(discipleship_id, lesson_id)

### 4.8.3 question_releases
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- discipleship_id uuid (FK discipleships.id)
- lesson_id uuid (FK lessons.id)
- released_by_user_id uuid (FK auth.users.id)
- released_at timestamptz
- created_at, updated_at

Constraints:
- unique(discipleship_id, lesson_id)

---

## 4.9 Respostas e revisão

### 4.9.1 answers
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- discipleship_id uuid (FK discipleships.id)
- lesson_id uuid (FK lessons.id)
- question_id uuid (FK questions.id)
- disciple_user_id uuid (FK auth.users.id)
- status text
- answer_payload jsonb
- submitted_at timestamptz nullable
- created_at, updated_at

Constraints:
- unique(discipleship_id, question_id)

### 4.9.2 reviews
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- discipleship_id uuid (FK discipleships.id)
- lesson_id uuid (FK lessons.id)
- question_id uuid (FK questions.id)
- answer_id uuid (FK answers.id)
- reviewer_user_id uuid (FK auth.users.id)
- decision text (approved/needs_changes/comment_only)
- notes_markdown text nullable
- created_at timestamptz

Nota:
- Sem update/delete (histórico).

---

## 4.10 Gamificação

### 4.10.1 achievements
Campos:
- id uuid (PK)
- code text unique
- title text
- description text
- category text
- icon_url text nullable
- rules jsonb
- created_at, updated_at

### 4.10.2 user_achievements
Campos:
- id uuid (PK)
- user_id uuid (FK auth.users.id)
- achievement_id uuid (FK achievements.id)
- earned_at timestamptz
- metadata jsonb nullable
- created_at, updated_at

Constraints:
- unique(user_id, achievement_id)

---

## 4.11 Auditoria e logs

### 4.11.1 audit_events
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id, nullable)
- actor_user_id uuid (FK auth.users.id, nullable)
- action text
- entity_type text
- entity_id uuid nullable
- metadata jsonb
- created_at timestamptz

### 4.11.2 webhook_logs
Campos:
- id uuid (PK)
- provider text
- event_id text
- status text (received/processed/failed)
- payload jsonb
- error text nullable
- received_at timestamptz
- processed_at timestamptz nullable

Constraints:
- unique(provider, event_id)

### 4.11.3 notifications_outbox
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id, nullable)
- user_id uuid (FK auth.users.id, nullable)
- channel text
- template text
- payload jsonb
- status text (pending/sent/failed)
- attempts int default 0
- scheduled_for timestamptz nullable
- sent_at timestamptz nullable
- created_at, updated_at

---

## 5. Relações e cardinalidades (resumo)
- auth.users ↔ organizations: N:N via organization_members
- organizations ↔ groups: 1:N
- auth.users ↔ groups: N:N via group_memberships
- groups ↔ group_leaders: 1:N
- lessons ↔ lesson_blocks: 1:N
- lessons ↔ questions: 1:N
- auth.users ↔ discipleships: 1:N como mentor e 1:N como disciple
- discipleships ↔ lesson_releases: 1:N
- discipleships ↔ question_releases: 1:N
- discipleships ↔ answers: 1:N
- answers ↔ reviews: 1:N

---

## 6. Notas críticas para implementação segura
- Teacher tables sem SELECT direto para usuários comuns.
- Convites, licenças e encerramento via RPC/Edge Function.
- `org_license_allocations` possui `group_id` para alinhar com policies baseadas em `leads_group(org_id, group_id)`.