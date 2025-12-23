# PAGES_AND_ROUTES.md

## Objetivo
Mapa de rotas/telas do Projeto SAVE com requisitos de acesso.

## Regras gerais de UI
- Sempre mostrar organização ativa e modo atual.
- Não renderizar ações sem permissão (além de depender de RLS).
- Falhar fechado: se não tem dados, não mostra.

## Rotas públicas
- /
- /auth/login
- /auth/register
- /auth/forgot-password
- /auth/callback

## App (autenticado)
### Contexto
- /app/context (selecionar org e modo)

### Discípulo
- /app/disciple
- /app/disciple/discipleships
- /app/disciple/discipleships/[id]
- /app/disciple/lessons/[lessonId]
- /app/disciple/lessons/[lessonId]/questions
- /app/disciple/achievements

### Discipulador
- /app/mentor
- /app/mentor/discipleships
- /app/mentor/discipleships/[id]
- /app/mentor/review-queue
- /app/mentor/invites
- /app/mentor/teacher/lessons/[lessonId]
- /app/mentor/reports

### Igreja (admin_org / group_leader)
- /app/church/members
- /app/church/members/[id]
- /app/church/groups
- /app/church/groups/[id]
- /app/church/licenses
- /app/church/quotas
- /app/church/audit
- /app/church/branding
- /app/church/reports

## Admin Platform
- /platform-admin
- /platform-admin/content/studies
- /platform-admin/content/modules
- /platform-admin/content/lessons
- /platform-admin/content/lessons/[id]
- /platform-admin/content/questions
- /platform-admin/content/publish
- /platform-admin/gamification
- /platform-admin/discounts
- /platform-admin/audit
- /platform-admin/payments-webhooks

