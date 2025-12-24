# RLS_RULES.md – Projeto SAVE

## 1. Objetivo
Definir as regras conceituais de Row Level Security (RLS) do Projeto SAVE.

Este documento descreve:
- quem pode ver o quê
- quem pode criar/alterar o quê
- os predicados lógicos usados nas policies

As policies concretas estão mapeadas em `RLS_POLICY_MAP.md`.

Regra inegociável:
- Se uma regra não estiver aqui, ela é proibida.

---

## 2. Princípios gerais

1. Multi-tenant estrito por organização (`org_id`)
2. RLS habilitado em todas as tabelas com dados de usuário/organização
3. `auth.uid()` é a identidade canônica do usuário logado
4. Nenhuma policy depende de dados do frontend
5. Conteúdo sensível do professor nunca é exposto por SELECT direto

---

## 3. Predicados canônicos (conceituais)

Os predicados abaixo devem ser implementados como **funções SQL auxiliares**, conforme definido em `DATA_MODEL.md`.

### 3.1 Predicados de organização

- `is_member(org_id)`
  - true se `auth.uid()` for membro ativo da organização

- `is_admin_org(org_id)`
  - true se `organization_members.role_admin_org = true`

---

### 3.2 Predicados de grupo (igreja)

- `is_group_leader(org_id)`
  - true se o usuário liderar ao menos um grupo da org

- `leads_group(org_id, group_id)`
  - true se o usuário for líder do grupo específico

- `shares_group_with_leader(org_id, leader_user_id, member_user_id)`
  - true se mentor e discípulo pertencem a pelo menos um grupo liderado pelo líder

Observação importante:
- O escopo de `group_leader` é **limitado a usuários que compartilham grupos que ele lidera**
- `group_leader` **não tem acesso global à org**, a menos que também seja `admin_org`
- O escopo de licenças do líder de grupo é determinado por `org_license_allocations.group_id` (não por inferência via group_memberships).

---

### 3.3 Predicados de papel funcional (discipulado)

- `is_mentor(org_id)`
  - true se o usuário:
    - tem licença ativa de mentor (`org_license_allocations`)
    - e `has_active_mentor_subscription(org_id, auth.uid()) = true`

- `is_disciple(org_id)`
  - true se o usuário participa de ao menos um discipulado ativo como discípulo

---

### 3.4 Assinatura ativa do discipulador

Função canônica:
- `has_active_mentor_subscription(org_id, user_id)`

Resumo (ver DATA_MODEL.md para detalhe):
- Org individual:
  - assinatura ativa da org habilita o papel de mentor
- Org igreja:
  - assinatura ativa da org (se aplicável)
  - e licença de mentor alocada ao usuário

Essa função é usada por:
- RLS (bloquear INSERT/UPDATE)
- RPCs (validações explícitas)

---

## 4. Regras por domínio

## 4.1 Organizações e membros

### organizations
- SELECT:
  - permitido apenas para membros da org
- INSERT/UPDATE:
  - apenas admin_platform (fora do escopo RLS comum)

---

### organization_members
- SELECT:
  - membro pode ver seu próprio vínculo
  - admin_org pode ver todos da org
- INSERT:
  - apenas via RPC (convite)
- UPDATE:
  - admin_org pode alterar papéis
- DELETE:
  - proibido (usar status = inactive)

---

## 4.2 Grupos (igreja)

### groups
- SELECT:
  - membros da org
- INSERT/UPDATE:
  - admin_org
- DELETE:
  - proibido

---

### group_memberships
- SELECT:
  - membros do grupo
  - líderes do grupo
  - admin_org
- INSERT/DELETE:
  - admin_org
  - líder do grupo (somente para seus grupos)

---

### group_leaders
- SELECT:
  - membros do grupo
  - admin_org
- INSERT/DELETE:
  - admin_org

---

## 4.3 Convites

### invites
- SELECT:
  - criador do convite
  - admin_org
- INSERT:
  - admin_org
  - group_leader (somente para seus grupos)
- UPDATE:
  - revogar convite:
    - criador
    - admin_org
- DELETE:
  - proibido

---

## 4.4 Licenças

### org_license_pool
- SELECT:
  - admin_org
  - group_leader (somente leitura)
- UPDATE:
  - admin_org
- INSERT:
  - via webhook apenas

---

### org_license_allocations
- SELECT:
  - admin_org (toda a org)
  - o próprio usuário (suas allocations)
  - group_leader (somente allocations escopadas a grupos que ele lidera)

- INSERT/UPDATE:
  - admin_org (qualquer allocation)
  - group_leader (somente se `group_id` for um grupo que ele lidera)

- DELETE:
  - proibido (usar status = revoked)

Regra de escopo (canonical):
- `org_license_allocations.group_id IS NULL` = licença global da organização
  - somente admin_org gerencia/visualiza globalmente
- `org_license_allocations.group_id IS NOT NULL` = licença escopada ao grupo
  - group_leader só pode gerenciar/visualizar se `leads_group(org_id, group_id) = true`

---

## 4.5 Currículo (conteúdo base)

### studies / modules / lessons / lesson_blocks / questions
- SELECT:
  - todos os membros da org
  - apenas status = published
- INSERT/UPDATE/DELETE:
  - admin_platform apenas

---

### teacher_notes / answer_keys
- SELECT:
  - proibido (RLS sempre false)
- Acesso:
  - somente via RPC/Edge Function validando papel de mentor

---

## 4.6 Discipulados

### discipleships
- SELECT:
  - mentor do discipulado
  - disciple do discipulado
  - admin_org
  - group_leader:
    - apenas se mentor e discípulo compartilham grupo que ele lidera
- INSERT:
  - mentor (com assinatura ativa)
- UPDATE:
  - mentor do discipulado
  - admin_org
- DELETE:
  - proibido

---

### lesson_releases
- SELECT:
  - mentor do discipulado
  - disciple do discipulado
- INSERT:
  - mentor do discipulado
- DELETE:
  - proibido

---

### question_releases (por lição)
- SELECT:
  - mentor do discipulado
  - disciple do discipulado
- INSERT:
  - mentor do discipulado
- DELETE:
  - proibido

---

## 4.7 Respostas e revisão

### answers
- SELECT:
  - disciple (suas próprias)
  - mentor do discipulado
  - admin_org
- INSERT:
  - disciple (se perguntas liberadas)
- UPDATE:
  - disciple (status draft / needs_changes)
  - mentor (status in_review / approved)
- DELETE:
  - proibido

---

### reviews
- SELECT:
  - mentor do discipulado
  - admin_org
- INSERT:
  - mentor do discipulado
- UPDATE/DELETE:
  - proibido

---

## 4.8 Auditoria e webhooks

### audit_events
- SELECT:
  - admin_org (somente sua org)
  - admin_platform (global)
- INSERT:
  - sistema/RPC apenas

---

### webhook_logs
- SELECT:
  - admin_platform
- INSERT/UPDATE:
  - Edge Functions apenas

---

## 5. Regras finais
- RLS é sempre deny-by-default.
- Policies devem chamar predicados claros (não lógica inline complexa).
- Se houver dúvida de escopo, negar acesso.
- `RLS_POLICY_MAP.md` é a tradução técnica obrigatória deste documento.