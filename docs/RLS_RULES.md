# RLS_RULES.md

## Objetivo
Regras explícitas de acesso por tabela (SELECT/INSERT/UPDATE/DELETE). Fonte de verdade para criação de policies.

## Princípios
- Deny by default.
- Policies específicas por operação.
- Checagens de org + papel + escopo (grupo) + assinatura ativa.

## Papéis
- admin_platform (global)
- admin_org (igreja)
- group_leader (igreja)
- user (normal)

## Regras por tabela
### organizations
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

### organization_members
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

### groups
- SELECT:
- INSERT/UPDATE/DELETE:

### group_memberships
- SELECT:
- INSERT/UPDATE/DELETE:

### invites
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

### org_license_pool / org_license_allocations / org_group_leader_quotas
- SELECT:
- INSERT/UPDATE/DELETE:

### discipleships
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

### lesson_releases / question_releases
- SELECT:
- INSERT:
- UPDATE/DELETE:

### answers / reviews
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

### Conteúdo global (studies/modules/lessons/lesson_blocks/questions)
- SELECT (app):
- INSERT/UPDATE/DELETE (somente admin_platform):

### Conteúdo do professor (lesson_teacher_notes / question_answer_keys)
- SELECT direto: proibido (exceto admin_platform)
- Acesso: via RPC com checagens

### audit_events / webhook_logs
- SELECT:
- INSERT:

## Casos de teste de permissão (a preencher)
- Caso 1:
- Caso 2:

