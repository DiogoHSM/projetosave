# DATA_MODEL.md – Projeto SAVE

## 1. Objetivo
Definir o modelo de dados do Projeto SAVE (Supabase + Postgres), incluindo:
- entidades principais
- relações
- constraints
- enums/estados
- regras de consistência

Observação:
- O banco (tabelas/colunas/funções/RPC) usa nomenclatura em inglês (snake_case).
- A UI usa termos em português (ex.: Discipulador, Discípulo, Discipulado).

---

## 2. Premissas
- Multi-tenant por organização (`org_id`)
- RLS obrigatório em tabelas com dados de usuário/organização
- Conteúdo do professor (gabarito e orientações) não pode ser acessado diretamente via SELECT (somente via RPC/Edge)
- Auditoria mínima via `audit_events`

---

## 3. Convenções

### 3.1 Nomenclatura
- Tabelas e colunas em inglês, snake_case
- Chaves primárias: `id uuid`
- FKs: `<entity>_id uuid`
- Timestamps: `created_at timestamptz`, `updated_at timestamptz`

### 3.2 Soft delete
- Preferir `archived_at` ou `status` em vez de DELETE, em entidades sensíveis (discipulados, conteúdo publicado).

### 3.3 Tipos e enums (sugestão)
- status como `text` com CHECK, ou enum (decisão por migration)
- datas sempre `timestamptz`

---

## 3.5 Funções auxiliares (RLS e permissões)

Para implementar os predicados descritos em `RLS_RULES.md`, o banco deve expor funções SQL *STABLE* (ou *IMMUTABLE* quando possível), sempre em inglês e com snake_case.

### 3.5.1 Predicados base (assinaturas sugeridas)
- `is_member(p_org_id uuid, p_user_id uuid) returns boolean`
- `is_admin_org(p_org_id uuid, p_user_id uuid) returns boolean`
- `is_group_leader(p_org_id uuid, p_user_id uuid) returns boolean`
- `leads_group(p_org_id uuid, p_user_id uuid, p_group_id uuid) returns boolean`
- `shares_group_with_leader(p_org_id uuid, p_leader_user_id uuid, p_member_user_id uuid) returns boolean`

Regras:
- Funções nunca devem depender do frontend para validação.
- Quando o `p_user_id` for omitido em RLS, usar `auth.uid()` internamente (em funções wrappers específicas para policy).

### 3.5.2 Assinatura ativa do discipulador (canonical)
Definição (função conceitual usada por RLS/RPC):
- `has_active_mentor_subscription(p_org_id uuid, p_user_id uuid) returns boolean`

Lógica:
- Se `organizations.type = 'individual'`:
  - retorna true se existir um registro em `org_subscriptions` para `p_org_id` com `status = 'active'` (ou `trialing`) e `current_period_end` >= now() (quando aplicável).
  - o dono da org (ou usuário marcado como owner) é o pagante, mas a assinatura habilita o papel de discipulador naquela org.
- Se `organizations.type = 'church'`:
  - retorna true se:
    1) a org tiver assinatura ativa em `org_subscriptions` (status ativo), **e**
    2) o usuário tiver uma alocação ativa de licença do tipo `mentor` em `org_license_allocations`.
  - isso permite que a igreja controle quais membros são discipuladores via alocação de seats.

Notas:
- Se no MVP você decidir que igrejas não precisam de assinatura recorrente (apenas compra avulsa de seats), a condição (1) pode ser removida, mas a decisão deve ser refletida também em `RLS_RULES.md` e `API_CONTRACTS.md`.

---

## 4. Modelo de Dados

## 4.1 Organizações e usuários

### 4.1.1 organizations
Objetivo:
- Representar uma organização (igreja ou individual).

Campos:
- id uuid (PK)
- type text (church/individual)
- name text
- slug text unique nullable
- contact_email text nullable
- logo_url text nullable
- theme_json jsonb nullable (customização visual simples)
- created_at, updated_at

Constraints:
- CHECK (type in ('church','individual'))

---

### 4.1.2 user_profiles
Objetivo:
- Perfil do usuário (complemento do auth.users).

Campos:
- id uuid (PK, FK auth.users.id)
- full_name text nullable
- phone text nullable
- avatar_url text nullable
- created_at, updated_at

---

### 4.2 Membros e papéis administrativos

### 4.2.1 organizations_users (opcional no MVP)
Observação:
- se usar somente `organization_members`, esta tabela pode ser omitida.

---

### 4.2.2 organization_members
Objetivo:
- Vínculo de usuário com organização e seus papéis administrativos (contexto igreja e individual).

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
- CHECK (status in ('active','inactive'))

Regras de papel (canonical):
- Papéis administrativos são **boolean flags** (não enum).
- Um usuário pode ter ambos `role_admin_org = true` e `role_group_leader = true` (ex.: administrador que também lidera grupos).
- Em caso de conflito de permissões, `role_admin_org` prevalece como acesso mais amplo, mas **não substitui** escopos específicos (ex.: relatórios por grupo).

Convenção de nomenclatura:
- Banco de dados (tabelas/colunas/RPC): inglês (mentor, disciple, org_id).
- Interface (labels/menus): português (Discipulador, Discípulo, Igreja, Grupo).

---

## 4.3 Igreja: grupos e escopo

### 4.3.1 groups
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- name text
- description text nullable
- created_at, updated_at

Constraints:
- unique(org_id, name)

---

### 4.3.2 group_memberships
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- group_id uuid (FK groups.id)
- user_id uuid (FK auth.users.id)
- created_at, updated_at

Constraints:
- unique(group_id, user_id)

---

### 4.3.3 group_leaders
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- group_id uuid (FK groups.id)
- user_id uuid (FK auth.users.id)
- created_at, updated_at

Constraints:
- unique(group_id, user_id)

---

## 4.4 Convites e onboarding

### 4.4.1 invites
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- email text
- role_to_grant text (disciple/mentor/member/admin_org/group_leader) (MVP pode reduzir)
- group_id uuid nullable (FK groups.id)
- license_grants_json jsonb nullable (seats a conceder)
- token_hash text unique
- status text (pending/accepted/revoked/expired)
- expires_at timestamptz nullable
- created_by_user_id uuid (FK auth.users.id)
- created_at, updated_at

Constraints:
- CHECK (status in ('pending','accepted','revoked','expired'))

•	Token de convite
	•	O token enviado por link/e-mail não é armazenado em texto puro
	•	O banco armazena apenas token_hash (ex.: SHA-256)
	•	O token “cru” existe apenas no momento da criação e no link
	•	O aceite do convite busca por token_hash = hash(token_recebido)

---

## 4.5 Pagamentos e licenças

### 4.5.1 org_subscriptions
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- provider text (stripe/other)
- provider_customer_id text nullable
- provider_subscription_id text nullable
- status text (active, past_due, canceled, trialing, etc.)
- current_period_start timestamptz nullable
- current_period_end timestamptz nullable
- created_at, updated_at

---

### 4.5.2 org_license_pool
Objetivo:
- Definir o total de licenças (seats) compradas por uma organização.

Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- disciple_seats_total int default 0
- mentor_seats_total int default 0
- updated_by_user_id uuid nullable
- created_at, updated_at

Regras:
- Não armazenar contadores `*_used` para evitar drift e bugs de conciliação.
- O uso deve ser derivado de `org_license_allocations` (ver view abaixo).

View recomendada (derivada):
- `org_license_pool_usage`:
  - org_id
  - disciple_seats_total
  - disciple_seats_used (COUNT allocations ativas do tipo 'disciple')
  - mentor_seats_total
  - mentor_seats_used (COUNT allocations ativas do tipo 'mentor')
  - disciple_seats_available = total - used
  - mentor_seats_available = total - used

---

### 4.5.3 org_license_allocations
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- group_id uuid nullable (FK groups.id)
- user_id uuid (FK auth.users.id)
- license_type text (disciple/mentor)
- quantity int default 1
- status text (active/revoked)
- granted_by_user_id uuid nullable
- created_at, updated_at

Constraints:
- CHECK (license_type in ('disciple','mentor'))
- CHECK (status in ('active','revoked'))
- unique(org_id, user_id, license_type, group_id)

Observação:
- MVP pode manter `quantity = 1` sempre.
- O “uso” de licenças é calculado por allocations ativas.

Escopo:
	•	group_id IS NULL significa licença no escopo da organização inteira
	•	group_id IS NOT NULL significa que a licença foi concedida no escopo daquele grupo (para controle/limites por líder de grupo)

---

## 4.6 Currículo (conteúdo base)

### 4.6.1 studies
Campos:
- id uuid (PK)
- org_id uuid nullable (NULL = global)
- title text
- description text nullable
- version int default 1
- status text (draft/published/archived)
- created_at, updated_at

Conteúdo global
	•	Conteúdo global do produto deve sempre ter org_id = NULL
	•	Conteúdo específico de uma organização (se habilitado no futuro) usa org_id = <org>
	•	No MVP, considerar apenas org_id = NULL para currículo base, e restringir criação/edição ao admin_platform

---

### 4.6.2 modules
Campos:
- id uuid (PK)
- study_id uuid (FK studies.id)
- title text
- position int
- status text (draft/published/archived)
- created_at, updated_at

Constraints:
- unique(study_id, position)

---

### 4.6.3 lessons
Campos:
- id uuid (PK)
- module_id uuid (FK modules.id)
- title text
- position int
- status text (draft/published/archived)
- created_at, updated_at

Constraints:
- unique(module_id, position)

---

### 4.6.4 lesson_blocks
Objetivo:
- Uma lição é composta por blocos (texto, imagem, vídeo).

Campos:
- id uuid (PK)
- lesson_id uuid (FK lessons.id)
- block_type text (text/image/video)
- content_text text nullable
- media_url text nullable
- caption text nullable
- position int
- created_at, updated_at

Constraints:
- CHECK (block_type in ('text','image','video'))
- unique(lesson_id, position)

---

### 4.6.5 questions
Campos:
- id uuid (PK)
- lesson_id uuid (FK lessons.id)
- question_type text (open_text/multiple_choice/matching/true_false)
- prompt text
- options_json jsonb nullable (para múltipla escolha / matching)
- position int
- created_at, updated_at

Constraints:
- CHECK (question_type in ('open_text','multiple_choice','matching','true_false'))
- unique(lesson_id, position)

---

### 4.6.6 teacher_notes (conteúdo do professor)
Campos:
- id uuid (PK)
- lesson_id uuid (FK lessons.id)
- notes_text text
- created_at, updated_at

Observação:
- Não expor via SELECT direto. Apenas via RPC/Edge.

---

### 4.6.7 answer_keys (gabarito)
Campos:
- id uuid (PK)
- question_id uuid (FK questions.id)
- answer_key_json jsonb
- created_at, updated_at

Observação:
- Não expor via SELECT direto. Apenas via RPC/Edge.

---

## 4.7 Discipulados

### 4.7.1 discipleships
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- mentor_user_id uuid (FK auth.users.id)
- disciple_user_id uuid (FK auth.users.id)
- status text (active/completed/archived)
- started_at timestamptz
- completed_at timestamptz nullable
- archived_at timestamptz nullable
- created_at, updated_at

Constraints:
- CHECK (status in ('active','completed','archived'))

---

## 4.8 Liberação de conteúdo (por lição)

### 4.8.1 lesson_releases
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

### 4.8.3 question_releases
Objetivo:
- Marcar que o **conjunto de perguntas de uma lição** foi liberado para um discipulado.
- A liberação é **por lição** (lesson-level), não por pergunta individual.

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
- status text (draft/submitted/in_review/needs_changes/approved)
- answer_payload jsonb
- submitted_at timestamptz nullable
- created_at, updated_at

Constraints:
- unique(discipleship_id, question_id)

---

### 4.9.2 reviews
Campos:
- id uuid (PK)
- org_id uuid (FK organizations.id)
- discipleship_id uuid (FK discipleships.id)
- lesson_id uuid (FK lessons.id)
- reviewer_user_id uuid (FK auth.users.id)
- decision text (approved/needs_changes/comment_only)
- notes text nullable
- created_at, updated_at

Constraints:
- CHECK (decision in (‘approved’,‘needs_changes’,‘comment_only’))

---

## 4.10 Auditoria e webhooks

### 4.10.1 audit_events
Campos:
- id uuid (PK)
- org_id uuid nullable
- actor_user_id uuid nullable
- event_type text
- entity_type text nullable
- entity_id uuid nullable
- metadata jsonb nullable
- created_at timestamptz

---

### 4.10.2 webhook_logs
Campos:
- id uuid (PK)
- provider text
- event_id text
- status text (received/processed/failed)
- payload jsonb
- error text nullable
- created_at, updated_at

Constraints:
- unique(provider, event_id)