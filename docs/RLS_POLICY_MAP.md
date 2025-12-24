# RLS_POLICY_MAP.md – Projeto SAVE

## 1. Objetivo
Mapear as policies RLS concretas por tabela, implementando `RLS_RULES.md`.

Regras:
- Deny-by-default em todas as tabelas listadas.
- `org_id` sempre validado em SELECT/INSERT/UPDATE.
- Para tabelas sensíveis, proibir DELETE e usar status/archived.

Observação:
- Predicados conceituais devem ser implementados como funções SQL (ver DATA_MODEL.md),
  por exemplo:
  - is_member(org_id)
  - is_admin_org(org_id)
  - leads_group(org_id, group_id)
  - shares_group_with_leader(org_id, leader_user_id, member_user_id)
  - has_active_mentor_subscription(org_id, user_id)

---

## 2. Convenções de policy

### 2.1 Padrão
- SELECT: permitir somente quando explicitamente definido
- INSERT: exigir WITH CHECK
- UPDATE: exigir USING e WITH CHECK
- DELETE: geralmente proibido

### 2.2 Helper predicates esperados
- `is_member(org_id)` usa `auth.uid()`
- `is_admin_org(org_id)` usa `organization_members.role_admin_org = true`
- `leads_group(org_id, group_id)` valida liderança do grupo
- `shares_group_with_leader(org_id, leader_user_id, member_user_id)` valida escopo do líder

---

## 3. Policies por tabela

## 3.1 organizations
RLS: ON

### SELECT
- Policy: org_select_member
  - USING: is_member(id)

### UPDATE/INSERT/DELETE
- nenhuma (bloqueado por padrão; admin_platform via service role / migrations)

---

## 3.2 user_profiles
RLS: ON

### SELECT
- profile_select_self
  - USING: id = auth.uid()

### UPDATE
- profile_update_self
  - USING: id = auth.uid()
  - WITH CHECK: id = auth.uid()

### INSERT
- profile_insert_self
  - WITH CHECK: id = auth.uid()

### DELETE
- none

---

## 3.3 organization_members
RLS: ON

### SELECT
- org_members_select_self
  - USING: user_id = auth.uid()

- org_members_select_admin
  - USING: is_admin_org(org_id)

### UPDATE
- org_members_update_admin
  - USING: is_admin_org(org_id)
  - WITH CHECK: is_admin_org(org_id)

Notas:
- Atualização de `role_admin_org` e `role_group_leader` apenas por admin_org.

### INSERT/DELETE
- none (inserção via RPC; delete proibido)

---

## 3.4 groups
RLS: ON

### SELECT
- groups_select_member
  - USING: is_member(org_id)

### INSERT/UPDATE
- groups_write_admin
  - USING: is_admin_org(org_id)
  - WITH CHECK: is_admin_org(org_id)

### DELETE
- none

---

## 3.5 group_memberships
RLS: ON

### SELECT
- group_memberships_select_member_or_leader_or_admin
  - USING:
    - is_admin_org(org_id)
    OR
    - leads_group(org_id, group_id)
    OR
    - user_id = auth.uid()
    OR
    - EXISTS (
        SELECT 1
        FROM group_memberships gm2
        WHERE gm2.group_id = group_memberships.group_id
          AND gm2.user_id = auth.uid()
      )

### INSERT
- group_memberships_insert_admin
  - WITH CHECK: is_admin_org(org_id)

- group_memberships_insert_group_leader_scoped
  - WITH CHECK:
    leads_group(org_id, group_id)

### DELETE
- none (preferir remover via status em versão futura; no MVP bloquear)

---

## 3.6 group_leaders
RLS: ON

### SELECT
- group_leaders_select_member_or_admin
  - USING:
    is_admin_org(org_id)
    OR
    EXISTS (
      SELECT 1
      FROM group_memberships gm
      WHERE gm.group_id = group_leaders.group_id
        AND gm.user_id = auth.uid()
    )
    OR
    user_id = auth.uid()

### INSERT/UPDATE/DELETE
- group_leaders_write_admin
  - USING: is_admin_org(org_id)
  - WITH CHECK: is_admin_org(org_id)

---

## 3.7 invites
RLS: ON

### SELECT
- invites_select_creator_or_admin
  - USING:
    is_admin_org(org_id)
    OR created_by_user_id = auth.uid()

### INSERT
- invites_insert_admin
  - WITH CHECK: is_admin_org(org_id)

- invites_insert_group_leader_scoped
  - WITH CHECK:
    role_to_grant IN ('member','disciple','mentor')  -- recomendação: limitar
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)

### UPDATE (revogar)
- invites_update_creator_or_admin
  - USING:
    is_admin_org(org_id)
    OR created_by_user_id = auth.uid()
  - WITH CHECK:
    is_admin_org(org_id)
    OR created_by_user_id = auth.uid()

### DELETE
- none

---

## 3.8 org_subscriptions
RLS: ON

### SELECT
- org_subscriptions_select_admin
  - USING: is_admin_org(org_id)

### INSERT/UPDATE
- none (somente webhook / service role)

### DELETE
- none

---

## 3.9 org_license_pool
RLS: ON

### SELECT
- license_pool_select_admin_or_group_leader
  - USING:
    is_admin_org(org_id)
    OR is_group_leader(org_id)

### UPDATE
- license_pool_update_admin
  - USING: is_admin_org(org_id)
  - WITH CHECK: is_admin_org(org_id)

### INSERT/DELETE
- none (webhook / service role)

---

## 3.10 org_license_allocations
RLS: ON

### SELECT
- license_allocations_select_self
  - USING: user_id = auth.uid()

- license_allocations_select_admin
  - USING: is_admin_org(org_id)

- license_allocations_select_group_leader_scoped
  - USING:
    is_group_leader(org_id)
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)

Notas:
- Líder de grupo vê apenas allocations escopadas a grupos que ele lidera (group_id != NULL).
- Allocations com group_id = NULL são consideradas globais da org e não entram no escopo do líder (a menos que ele seja admin_org).

### INSERT/UPDATE
- license_allocations_write_admin
  - USING: is_admin_org(org_id)
  - WITH CHECK: is_admin_org(org_id)

- license_allocations_write_group_leader_scoped
  - USING:
    is_group_leader(org_id)
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)
  - WITH CHECK:
    is_group_leader(org_id)
    AND group_id IS NOT NULL
    AND leads_group(org_id, group_id)

### DELETE
- none (revogar via status)

---

## 3.11 studies / modules / lessons / lesson_blocks / questions
RLS: ON (com leitura controlada)

### SELECT
- content_select_published_member
  - USING:
    (org_id IS NULL OR is_member(org_id))
    AND status = 'published'

Observação:
- Se `org_id IS NULL` significa conteúdo global, permitir a qualquer usuário autenticado
  (ou até público, se quiser no futuro; MVP: autenticado).

### INSERT/UPDATE/DELETE
- none (somente admin_platform via service role)

---

## 3.12 teacher_notes
RLS: ON

### SELECT
- none (bloqueado)

### INSERT/UPDATE/DELETE
- none (admin_platform via service role)

Acesso permitido:
- somente via RPC (ver API_CONTRACTS.md)

---

## 3.13 answer_keys
RLS: ON

### SELECT
- none (bloqueado)

### INSERT/UPDATE/DELETE
- none (admin_platform via service role)

Acesso permitido:
- somente via RPC (ver API_CONTRACTS.md)

---

## 3.14 discipleships
RLS: ON

### SELECT
- discipleships_select_participants
  - USING:
    mentor_user_id = auth.uid()
    OR disciple_user_id = auth.uid()

- discipleships_select_admin
  - USING: is_admin_org(org_id)

- discipleships_select_group_leader_scoped
  - USING:
    is_group_leader(org_id)
    AND shares_group_with_leader(org_id, auth.uid(), mentor_user_id)
    AND shares_group_with_leader(org_id, auth.uid(), disciple_user_id)

Notas:
- O líder só vê discipulados quando **ambos** (mentor e discípulo) estão no escopo dos grupos liderados por ele.
- Se preferir relaxar (ver se “mentor OU discípulo” no escopo), isso deve ser decisão explícita.

### INSERT
- discipleships_insert_mentor
  - WITH CHECK:
    org_id IS NOT NULL
    AND mentor_user_id = auth.uid()
    AND is_member(org_id)
    AND has_active_mentor_subscription(org_id, auth.uid())

### UPDATE
- discipleships_update_mentor
  - USING:
    mentor_user_id = auth.uid()
    AND org_id IS NOT NULL
  - WITH CHECK:
    mentor_user_id = auth.uid()
    AND org_id IS NOT NULL

- discipleships_update_admin
  - USING: is_admin_org(org_id)
  - WITH CHECK: is_admin_org(org_id)

### DELETE
- none

---

## 3.15 lesson_releases
RLS: ON

### SELECT
- lesson_releases_select_participants
  - USING:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = lesson_releases.discipleship_id
        AND (d.mentor_user_id = auth.uid() OR d.disciple_user_id = auth.uid())
    )

### INSERT
- lesson_releases_insert_mentor
  - WITH CHECK:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = lesson_releases.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )

### UPDATE/DELETE
- none

---

## 3.16 question_releases (release por lição)
RLS: ON

### SELECT
- question_releases_select_participants
  - USING:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = question_releases.discipleship_id
        AND (d.mentor_user_id = auth.uid() OR d.disciple_user_id = auth.uid())
    )

### INSERT
- question_releases_insert_mentor
  - WITH CHECK:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = question_releases.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )

### UPDATE/DELETE
- none

---

## 3.17 answers
RLS: ON

### SELECT
- answers_select_disciple
  - USING: disciple_user_id = auth.uid()

- answers_select_mentor
  - USING:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.mentor_user_id = auth.uid()
    )

- answers_select_admin
  - USING: is_admin_org(org_id)

### INSERT
- answers_insert_disciple_when_released
  - WITH CHECK:
    disciple_user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.disciple_user_id = auth.uid()
        AND d.status = 'active'
    )
    AND EXISTS (
      SELECT 1
      FROM question_releases qr
      WHERE qr.discipleship_id = answers.discipleship_id
        AND qr.lesson_id = answers.lesson_id
    )

### UPDATE
- answers_update_disciple_limited
  - USING:
    disciple_user_id = auth.uid()
    AND status IN ('draft','needs_changes')
  - WITH CHECK:
    disciple_user_id = auth.uid()

- answers_update_mentor_limited
  - USING:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )
    AND status IN ('submitted','in_review','needs_changes')
  - WITH CHECK:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = answers.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )

### DELETE
- none

---

## 3.18 reviews
RLS: ON

### SELECT
- reviews_select_mentor
  - USING:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = reviews.discipleship_id
        AND d.mentor_user_id = auth.uid()
    )
  OR is_admin_org(org_id)

### INSERT
- reviews_insert_mentor
  - WITH CHECK:
    EXISTS (
      SELECT 1
      FROM discipleships d
      WHERE d.id = reviews.discipleship_id
        AND d.mentor_user_id = auth.uid()
        AND d.status = 'active'
    )

### UPDATE/DELETE
- none

---

## 3.19 audit_events
RLS: ON

### SELECT
- audit_select_admin_org
  - USING:
    org_id IS NOT NULL
    AND is_admin_org(org_id)

- audit_select_admin_platform
  - USING: false  -- admin_platform via service role / separate path

### INSERT/UPDATE/DELETE
- none (somente sistema via RPC/service role)

---

## 3.20 webhook_logs
RLS: ON

### SELECT/INSERT/UPDATE/DELETE
- none (somente service role / edge)

---

## 4. Notas finais
- Policies acima descrevem o comportamento; a implementação final deve virar migrations SQL.
- Qualquer ajuste em RLS exige atualização de:
  - RLS_RULES.md
  - RLS_POLICY_MAP.md
  - TESTING_STRATEGY.md (novos casos)