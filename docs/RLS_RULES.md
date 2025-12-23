# RLS_RULES.md – Projeto SAVE

## 1. Objetivo
Este documento define as regras de Row Level Security (RLS) por tabela para o Projeto SAVE.

Regras gerais:
- Deny by default.
- Toda tabela sensível deve ter RLS habilitado.
- Policies devem ser mínimas e específicas.
- Se não houver policy explícita para a operação, deve falhar.
- Conteúdo do professor não pode ter SELECT direto (somente RPC).

---

## 2. Conceitos e predicados padrão (para usar nas policies)
Definições conceituais (implementar como SQL helpers, views ou subqueries):

### 2.1 Identidade
- `uid()` = `auth.uid()`

### 2.2 Membership
- `is_member(org_id)`:
  - existe linha em `organization_members` com `org_id` e `user_id = uid()` e `status = 'active'`

### 2.3 Papéis administrativos (igreja)
- `is_admin_org(org_id)`:
  - membership com `role_admin_org = true` (ou role enum contendo admin_org)
- `is_group_leader(org_id)`:
  - membership com `role_group_leader = true` (ou role enum contendo group_leader)

### 2.4 Discipulador e assinatura
- `has_active_mentor_subscription(org_id)`:
  - para org individual: subscription ativa do dono (ou do próprio usuário, conforme modelagem)
  - para org igreja: ou assinatura da org ativa, ou licenças de discipulador válidas para o usuário
  - regra do MVP: “discipulador só pode operar se sua capacidade de discipulador estiver ativa na org”

### 2.5 Escopo de grupo (líder de grupo)
- `leads_group(org_id, group_id)`:
  - existe linha em `group_leaders` com `org_id`, `group_id` e `leader_user_id = uid()`
- `is_in_group(org_id, group_id, user_id)`:
  - existe linha em `group_memberships` com `org_id`, `group_id` e `user_id`

### 2.6 Escopo de discipulado
- `is_disciple_in_discipleship(discipleship_id)`:
  - `discipleships.id = discipleship_id` e `discipleships.disciple_user_id = uid()`
- `is_mentor_in_discipleship(discipleship_id)`:
  - `discipleships.id = discipleship_id` e `discipleships.mentor_user_id = uid()`

### 2.7 Admin Platform (global)
- `is_admin_platform()`:
  - regra de “claims” do auth (ex: `auth.jwt()->>'role' = 'admin_platform'`)
  - ou tabela `platform_admins` com `user_id = uid()`

Observação:
- Sempre que possível, preferir checagens por membership e org_id (mais simples de auditar).

---

## 3. Regras por tabela (CRUD)

### 3.1 organizations
Objetivo: restringir acesso ao contexto do usuário.

- SELECT:
  - permitido se `is_member(id)` OU `is_admin_platform()`
- INSERT:
  - proibido via client
  - permitido apenas via Edge Function/RPC (ex: criação automática na compra)
- UPDATE:
  - permitido se `is_admin_platform()`
  - permitido se `is_admin_org(id)` para campos de branding/configurações da org igreja (se esses campos estiverem aqui; caso contrário, usar tabela separada)
- DELETE:
  - proibido (no MVP)

### 3.2 organization_members
- SELECT:
  - permitido se `is_member(org_id)` (membros podem ver lista básica de membros da própria org, com campos mínimos)
  - recomendado: limitar colunas sensíveis via view (ex: não expor email)
- INSERT:
  - proibido via client (usar RPC accept_invite)
  - permitido apenas via RPC/Edge Function
- UPDATE:
  - permitido ao próprio usuário para campos não administrativos (ex: preferências), se existirem aqui
  - permitido se `is_admin_org(org_id)` para:
    - ativar/inativar membro
    - atribuir papéis administrativos (admin_org e group_leader)
- DELETE:
  - proibido (no MVP)
  - preferir soft delete (status)

### 3.3 user_preferences
- SELECT:
  - permitido se `user_id = uid()`
- INSERT:
  - permitido se `user_id = uid()`
- UPDATE:
  - permitido se `user_id = uid()`
- DELETE:
  - permitido se `user_id = uid()`

---

## 4. Igreja: grupos e memberships

### 4.1 groups
- SELECT:
  - permitido se `is_member(org_id)`
- INSERT:
  - permitido se `is_admin_org(org_id)`
  - permitido se `is_group_leader(org_id)` apenas se o produto permitir líderes criarem grupos; padrão: somente admin
- UPDATE:
  - permitido se `is_admin_org(org_id)`
  - permitido se `is_group_leader(org_id)` somente para grupos que lidera e somente para campos permitidos (ex: nome e descrição), se desejado
- DELETE:
  - proibido no MVP (soft delete com status)
  - permitido apenas se `is_admin_org(org_id)`

### 4.2 group_memberships
- SELECT:
  - permitido se `is_member(org_id)` e:
    - (a) o usuário está no grupo (self visibility), OU
    - (b) `is_admin_org(org_id)`, OU
    - (c) `leads_group(org_id, group_id)`
- INSERT (adicionar membro ao grupo):
  - permitido se `is_admin_org(org_id)`
  - permitido se `leads_group(org_id, group_id)` (líder do grupo pode adicionar membros ao próprio grupo)
- UPDATE:
  - permitido se `is_admin_org(org_id)` ou `leads_group(org_id, group_id)`
  - recomendado: poucas colunas atualizáveis
- DELETE (remover membro do grupo):
  - permitido se `is_admin_org(org_id)` ou `leads_group(org_id, group_id)`

### 4.3 group_leaders
- SELECT:
  - permitido se `is_member(org_id)`
- INSERT (atribuir líder):
  - permitido se `is_admin_org(org_id)`
- DELETE (remover líder):
  - permitido se `is_admin_org(org_id)`
- UPDATE:
  - idealmente não existe (usar insert/delete)

### 4.4 org_group_leader_quotas
- SELECT:
  - permitido se `is_admin_org(org_id)`
  - permitido se `is_group_leader(org_id)` apenas para ver sua própria quota
- INSERT/UPDATE/DELETE:
  - permitido apenas se `is_admin_org(org_id)`

---

## 5. Convites

### 5.1 invites
Observação: convite é operação sensível. Recomenda-se criar e aceitar via RPC/Edge Function. Ainda assim, RLS deve proteger.

- SELECT:
  - permitido se `is_admin_platform()`
  - permitido se `is_admin_org(org_id)` ou `is_group_leader(org_id)` com filtro:
    - group_leader só pode ver convites criados para grupos que lidera (se invite tiver group_id)
  - permitido ao próprio convidado somente se houver mecanismo seguro (normalmente não; o convidado usa token, não SELECT)
- INSERT:
  - proibido via client
  - permitido apenas via RPC (create_invite) com checagens de quota e escopo
- UPDATE:
  - proibido via client
  - permitido via RPC para revogar/reemitir/expirar
- DELETE:
  - proibido (manter para auditoria)

---

## 6. Licenças e billing (org igreja e individual)

### 6.1 org_subscriptions
- SELECT:
  - permitido se `is_admin_platform()`
  - permitido se `is_admin_org(org_id)` para ver status da org igreja
  - permitido em org individual para o dono/discipulador (definir regra pelo modelo)
- INSERT/UPDATE:
  - proibido via client
  - permitido apenas via Edge Function (webhook) ou RPC administrativa
- DELETE:
  - proibido

### 6.2 org_license_pool
- SELECT:
  - permitido se `is_admin_org(org_id)`
  - permitido se `is_group_leader(org_id)` apenas leitura parcial (opcional), ou não permitir
- INSERT/UPDATE:
  - proibido via client
  - permitido apenas via webhook (Edge Function) e RPC administrativa
- DELETE:
  - proibido

### 6.3 org_license_allocations
- SELECT:
  - permitido se `is_admin_org(org_id)`
  - permitido se `is_group_leader(org_id)` apenas para alocações dentro dos seus grupos (se houver escopo), ou somente próprias
  - permitido ao usuário ver sua própria alocação (se `user_id = uid()`)
- INSERT/UPDATE/DELETE:
  - proibido via client
  - permitido via RPC (allocate_license, revoke_license) com checagens de pool e quota

### 6.4 discounts
- SELECT:
  - permitido se `is_admin_platform()`
  - permitido se `user_id = uid()` para descontos do próprio usuário
  - permitido se `is_admin_org(org_id)` se houver desconto por org (opcional)
- INSERT/UPDATE/DELETE:
  - proibido via client
  - permitido via admin_platform ou automação (conclusão do discipulado)

---

## 7. Conteúdo global (publicação e leitura)

### 7.1 studies, modules, lessons, lesson_blocks, questions
Objetivo: leitura ampla, escrita apenas admin_platform.

- SELECT:
  - permitido para usuários autenticados (ou público, se desejado)
  - conteúdo “bloqueado” não deve ser filtrado por RLS aqui, e sim por releases do discipulado (a liberação real depende do fluxo)
- INSERT/UPDATE/DELETE:
  - permitido apenas se `is_admin_platform()`

Observação:
- Mesmo que o conteúdo seja global, a liberação para discípulo não deve ocorrer por esconder registros de lessons, e sim por permitir acesso ao “conteúdo liberado” por meio de releases (seção 8).

---

## 8. Conteúdo do professor (altamente sensível)

### 8.1 lesson_teacher_notes
- SELECT:
  - proibido para usuários comuns (sem policy)
  - permitido somente se `is_admin_platform()`
- INSERT/UPDATE/DELETE:
  - permitido somente se `is_admin_platform()`

Acesso no app:
- exclusivamente via RPC `get_teacher_lesson(...)` (security definer) que valida:
  - is_member(org_id)
  - papel permitido (discipulador, group_leader, admin_org)
  - assinatura ativa quando aplicável

### 8.2 question_answer_keys
Mesmas regras de `lesson_teacher_notes`.

---

## 9. Fluxo de discipulado e releases

### 9.1 discipleships
Dados sensíveis por org e por vínculo (mentor e disciple).

- SELECT:
  - permitido se `is_member(org_id)` e:
    - (a) `mentor_user_id = uid()` ou `disciple_user_id = uid()`
    - (b) `is_admin_org(org_id)`
    - (c) `is_group_leader(org_id)` e discipulado pertence a alguém de grupo que ele lidera (requer regra de escopo, ver abaixo)
- INSERT (criar discipulado):
  - permitido se `is_member(org_id)` e `has_active_mentor_subscription(org_id)`
  - somente se `mentor_user_id = uid()`
  - exige licenças disponíveis (recomendado via RPC create_discipleship)
- UPDATE:
  - permitido ao mentor do vínculo para:
    - status do discipulado (active, completed, archived)
    - metadados do acompanhamento
  - permitido a admin_org em casos administrativos (opcional)
- DELETE:
  - proibido (soft delete ou status)

Escopo de líder de grupo:
- group_leader só vê discipulados onde mentor ou discípulo pertence a algum grupo que ele lidera.
- Isso deve ser implementado com join em `group_memberships` de mentor e/ou discípulo, ou com tabela auxiliar de escopo.

### 9.2 lesson_releases
Representa liberação de lição para um discipulado.

- SELECT:
  - permitido se `is_disciple_in_discipleship(discipleship_id)` ou `is_mentor_in_discipleship(discipleship_id)`
  - permitido se admin_org na mesma org
  - permitido se group_leader dentro do escopo
- INSERT (liberar lição):
  - permitido somente ao mentor do vínculo (`is_mentor_in_discipleship`)
  - exige assinatura ativa e discipulado active
- UPDATE:
  - geralmente não necessário (criar novo release ou ter status)
- DELETE:
  - proibido (manter histórico)

### 9.3 question_releases
Representa liberação de questões para um discipulado e lição.

- SELECT:
  - mesmas regras de lesson_releases
- INSERT:
  - permitido somente ao mentor do vínculo
  - exige que a lição já esteja liberada
- UPDATE/DELETE:
  - proibido no MVP

---

## 10. Respostas e revisões

### 10.1 answers
- SELECT:
  - permitido se:
    - discípulo do vínculo (ver suas próprias respostas)
    - mentor do vínculo (ver respostas do discípulo)
    - admin_org na org
    - group_leader no escopo
- INSERT:
  - permitido somente ao discípulo do vínculo
  - exige que as questões estejam liberadas
  - para rascunho: status draft
  - para envio: status submitted
- UPDATE:
  - permitido somente ao discípulo enquanto status = draft ou needs_changes
  - permitido ao mentor para mudar status para in_review/approved/etc somente via review (preferir tabela reviews)
- DELETE:
  - proibido no MVP

### 10.2 reviews
- SELECT:
  - permitido ao mentor do vínculo
  - permitido ao discípulo do vínculo (para ver feedback)
  - permitido ao admin_org
  - permitido ao group_leader no escopo
- INSERT:
  - permitido ao mentor do vínculo
  - permitido ao admin_org
  - permitido ao group_leader somente no escopo
- UPDATE/DELETE:
  - proibido (histórico imutável)

---

## 11. Gamificação

### 11.1 achievements (definições globais)
- SELECT:
  - permitido a todos (ou autenticados)
- INSERT/UPDATE/DELETE:
  - permitido somente se `is_admin_platform()`

### 11.2 user_achievements
- SELECT:
  - permitido se `user_id = uid()`
  - permitido se admin_org na mesma org, se houver vínculo org (opcional)
- INSERT/UPDATE:
  - proibido via client
  - permitido via job/RPC interna (server-side)
- DELETE:
  - proibido

---

## 12. Auditoria e logs

### 12.1 audit_events
- SELECT:
  - permitido se `is_admin_platform()`
  - permitido se `is_admin_org(org_id)`
  - permitido se `is_group_leader(org_id)` com filtro de escopo (apenas eventos de seus grupos)
  - opcional: permitir ao próprio usuário ver eventos onde é o actor (somente os próprios)
- INSERT:
  - permitido via RPC/Edge Functions (não via client direto)
- UPDATE/DELETE:
  - proibido

### 12.2 webhook_logs
- SELECT:
  - permitido somente se `is_admin_platform()`
  - opcional: admin_org pode ver eventos resumidos (sem payload completo)
- INSERT:
  - permitido somente via Edge Functions (webhook)
- UPDATE/DELETE:
  - proibido

### 12.3 notifications_outbox
- SELECT:
  - permitido somente para serviços internos (ou admin_platform)
  - opcional: permitir usuário ler suas notificações via view segura
- INSERT:
  - via RPC/Edge Functions
- UPDATE:
  - via worker interno (marcar enviado)
- DELETE:
  - proibido (manter histórico no MVP)

---

## 13. Regras especiais e “anti-patterns” proibidos
- Proibido:
  - policies com `USING (true)`
  - liberar SELECT amplo em tabelas com org_id
  - acessar teacher tables diretamente
  - fazer INSERT/UPDATE em licenças via client
  - confiar em “hidden UI” como segurança

---

## 14. Casos de teste de permissão (obrigatórios)
Casos que devem falhar:
1) Discípulo tenta SELECT em `question_answer_keys` e `lesson_teacher_notes`
2) Usuário de org A tenta ler `discipleships` da org B
3) Líder de grupo tenta ver ou alocar licença para usuário fora de seus grupos
4) Discípulo tenta inserir answer sem `question_release` liberado
5) Reutilizar token de invite aceito

Casos que devem funcionar:
1) Mentor lê conteúdo do professor via RPC
2) Mentor libera lição e questões para discipulado active
3) Discípulo envia resposta após liberação
4) Mentor cria review e discípulo lê feedback
5) Admin_org aloca licenças e ajusta quotas

---

## 15. Notas de implementação (para agents)
- Implementar predicados (is_member, is_admin_org, leads_group etc.) como SQL helpers reutilizáveis (funções STABLE) ou subqueries padronizadas.
- Preferir RPC para operações que alteram múltiplas tabelas em transação (convites, licenças, create/complete discipleship).
- Views para relatórios devem respeitar RLS ou ser “security invoker”.
- Se houver dúvida entre permitir e negar, negar.