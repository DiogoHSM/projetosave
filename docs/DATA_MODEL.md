# DATA_MODEL.md

## Objetivo
Modelo conceitual de dados do Projeto SAVE. Este documento evita que agentes inventem tabelas/relacionamentos.

## Convenções
- Multi-tenant: tabelas sensíveis possuem org_id quando aplicável.
- IDs: uuid.
- Timestamps: created_at, updated_at, etc.
- Conteúdo global vs dados da org.

## Entidades principais
### Organizações
- organizations
- organization_members
- user_preferences

### Grupos (igreja)
- groups
- group_memberships
- group_leaders
- org_group_leader_quotas

### Licenças e billing
- org_subscriptions
- org_license_pool
- org_license_allocations
- discounts

### Convites e onboarding
- invites

### Conteúdo (global)
- studies
- modules
- lessons
- lesson_blocks
- questions
- lesson_teacher_notes
- question_answer_keys

### Fluxo de discipulado
- discipleships
- lesson_releases
- question_releases
- answers
- reviews

### Gamificação
- achievements
- user_achievements

### Auditoria e operações
- audit_events
- webhook_logs
- notifications_outbox

## Relacionamentos (alto nível)
- User ↔ Organizations (N:N via organization_members)
- Organizations ↔ Groups (1:N)
- Users ↔ Groups (N:N via group_memberships)
- Lessons ↔ LessonBlocks (1:N)
- Lessons ↔ Questions (1:N)
- Discipleship ↔ Releases/Answers/Reviews (1:N)

## Campos sensíveis
- Lista de campos/tabelas sensíveis (a preencher)

