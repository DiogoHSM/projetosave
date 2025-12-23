# RLS_POLICY_MAP.md – Projeto SAVE

## Objetivo
Mapa explícito das policies de Row Level Security (RLS) do Projeto SAVE.

Este documento é a **referência direta** para geração de SQL de policies.
Se uma operação não estiver listada aqui, ela **é proibida**.

---

## Convenções

- `uid()` = `auth.uid()`
- Funções auxiliares (conceituais) vêm de `RLS_RULES.md`:
  - `is_member(org_id)`
  - `is_admin_org(org_id)`
  - `is_group_leader(org_id)`
  - `leads_group(org_id, group_id)`
  - `has_active_mentor_subscription(org_id)`
  - `is_disciple_in_discipleship(discipleship_id)`
  - `is_mentor_in_discipleship(discipleship_id)`
  - `is_admin_platform()`

Regras:
- Policies devem ser **nominais e específicas**.
- Nunca usar `USING (true)`.
- Preferir `USING` para leitura e `WITH CHECK` para escrita.
- Tabelas sensíveis devem ter RLS habilitado antes das policies.

---

## organizations

### SELECT
**Policy:** organizations_select_member  
**USING:**
- is_member(id)
- OR is_admin_platform()

### INSERT
- ❌ Proibido (via client)

### UPDATE
**Policy:** organizations_update_admin  
**USING:**
- is_admin_platform()
- OR is_admin_org(id)

**WITH CHECK:**
- is_admin_platform()
- OR is_admin_org(id)

### DELETE
- ❌ Proibido

---

## organization_members

### SELECT
**Policy:** org_members_select_scoped  
**USING:**
- is_member(org_id)

*(Observação: colunas sensíveis devem ser limitadas via view quando necessário.)*

### INSERT
- ❌ Proibido (usar RPC `accept_invite`)

### UPDATE
**Policy:** org_members_update_admin  
**USING:**
- is_admin_org(org_id)

**WITH CHECK:**
- is_admin_org(org_id)

### DELETE
- ❌ Proibido (preferir status)

---

## user_preferences

### SELECT
**Policy:** user_prefs_select_self  
**USING:**
- user_id = uid()

### INSERT
**Policy:** user_prefs_insert_self  
**WITH CHECK:**
- user_id = uid()

### UPDATE
**Policy:** user_prefs_update_self  
**USING:**
- user_id = uid()

**WITH CHECK:**
- user_id = uid()

### DELETE
**Policy:** user_prefs_delete_self  
**USING:**
- user_id = uid()

---

## groups

### SELECT
**Policy:** groups_select_members  
**USING:**
- is_member(org_id)

### INSERT
**Policy:** groups_insert_admin  
**WITH CHECK:**
- is_admin_org(org_id)

### UPDATE
**Policy:** groups_update_admin_or_leader  
**USING:**
- is_admin_org(org_id)
- OR leads_group(org_id, id)

**WITH CHECK:**
- is_admin_org(org_id)
- OR leads_group(org_id, id)

### DELETE
- ❌ Proibido (soft delete recomendado)

---

## group_memberships

### SELECT
**Policy:** group_memberships_select_scoped  
**USING:**
- is_member(org_id)
- AND (
    user_id = uid()
    OR is_admin_org(org_id)
    OR leads_group(org_id, group_id)
  )

### INSERT
**Policy:** group_memberships_insert_admin_or_leader  
**WITH CHECK:**
- is_admin_org(org_id)
- OR leads_group(org_id, group_id)

### UPDATE
**Policy:** group_memberships_update_admin_or_leader  
**USING:**
- is_admin_org(org_id)
- OR leads_group(org_id, group_id)

**WITH CHECK:**
- is_admin_org(org_id)
- OR leads_group(org_id, group_id)

### DELETE
**Policy:** group_memberships_delete_admin_or_leader  
**USING:**
- is_admin_org(org_id)
- OR leads_group(org_id, group_id)

---

## group_leaders

### SELECT
**Policy:** group_leaders_select_members  
**USING:**
- is_member(org_id)

### INSERT
**Policy:** group_leaders_insert_admin  
**WITH CHECK:**
- is_admin_org(org_id)

### DELETE
**Policy:** group_leaders_delete_admin  
**USING:**
- is_admin_org(org_id)

---

## org_group_leader_quotas

### SELECT
**Policy:** group_leader_quotas_select  
**USING:**
- is_admin_org(org_id)
- OR (is_group_leader(org_id) AND leader_user_id = uid())

### INSERT / UPDATE / DELETE
**Policy:** group_leader_quotas_admin_only  
**USING:**
- is_admin_org(org_id)

**WITH CHECK:**
- is_admin_org(org_id)

---

## invites

### SELECT
**Policy:** invites_select_admin_or_scoped_leader  
**USING:**
- is_admin_org(org_id)
- OR (is_group_leader(org_id) AND leads_group(org_id, group_id))

### INSERT
- ❌ Proibido (usar RPC `create_invite`)

### UPDATE
- ❌ Proibido (usar RPC)

### DELETE
- ❌ Proibido

---

## org_subscriptions

### SELECT
**Policy:** subscriptions_select_admin  
**USING:**
- is_admin_platform()
- OR is_admin_org(org_id)

### INSERT / UPDATE / DELETE
- ❌ Proibido (Edge Function / admin only)

---

## org_license_pool

### SELECT
**Policy:** license_pool_select_admin  
**USING:**
- is_admin_org(org_id)

### INSERT / UPDATE / DELETE
- ❌ Proibido (RPC / webhook)

---

## org_license_allocations

### SELECT
**Policy:** license_allocations_select_scoped  
**USING:**
- is_admin_org(org_id)
- OR user_id = uid()
- OR (is_group_leader(org_id) AND leads_group(org_id, group_id))

### INSERT / UPDATE / DELETE
- ❌ Proibido (RPC only)

---

## studies / modules / lessons / lesson_blocks / questions

### SELECT
**Policy:** content_select_authenticated  
**USING:**
- auth.uid() IS NOT NULL
- OR is_admin_platform()

### INSERT / UPDATE / DELETE
**Policy:** content_admin_platform_only  
**USING:**
- is_admin_platform()

**WITH CHECK:**
- is_admin_platform()

---

## lesson_teacher_notes

### SELECT
- ❌ Nenhuma policy (bloqueado)

### INSERT / UPDATE / DELETE
**Policy:** teacher_notes_admin_only  
**USING:**
- is_admin_platform()

**WITH CHECK:**
- is_admin_platform()

---

## question_answer_keys

### SELECT
- ❌ Nenhuma policy (bloqueado)

### INSERT / UPDATE / DELETE
**Policy:** answer_keys_admin_only  
**USING:**
- is_admin_platform()

**WITH CHECK:**
- is_admin_platform()

---

## discipleships

### SELECT
**Policy:** discipleships_select_scoped  
**USING:**
- is_member(org_id)
- AND (
    mentor_user_id = uid()
    OR disciple_user_id = uid()
    OR is_admin_org(org_id)
  )

### INSERT
**Policy:** discipleships_insert_mentor  
**WITH CHECK:**
- mentor_user_id = uid()
- AND is_member(org_id)
- AND has_active_mentor_subscription(org_id)

### UPDATE
**Policy:** discipleships_update_mentor_or_admin  
**USING:**
- mentor_user_id = uid()
- OR is_admin_org(org_id)

**WITH CHECK:**
- mentor_user_id = uid()
- OR is_admin_org(org_id)

### DELETE
- ❌ Proibido

---

## lesson_releases

### SELECT
**Policy:** lesson_releases_select_participants  
**USING:**
- is_disciple_in_discipleship(discipleship_id)
- OR is_mentor_in_discipleship(discipleship_id)
- OR is_admin_org(org_id)

### INSERT
**Policy:** lesson_releases_insert_mentor  
**WITH CHECK:**
- is_mentor_in_discipleship(discipleship_id)

### UPDATE / DELETE
- ❌ Proibido

---

## question_releases

### SELECT
**Policy:** question_releases_select_participants  
**USING:**
- is_disciple_in_discipleship(discipleship_id)
- OR is_mentor_in_discipleship(discipleship_id)
- OR is_admin_org(org_id)

### INSERT
**Policy:** question_releases_insert_mentor  
**WITH CHECK:**
- is_mentor_in_discipleship(discipleship_id)

### UPDATE / DELETE
- ❌ Proibido

---

## answers

### SELECT
**Policy:** answers_select_scoped  
**USING:**
- is_disciple_in_discipleship(discipleship_id)
- OR is_mentor_in_discipleship(discipleship_id)
- OR is_admin_org(org_id)

### INSERT
**Policy:** answers_insert_disciple  
**WITH CHECK:**
- is_disciple_in_discipleship(discipleship_id)

### UPDATE
**Policy:** answers_update_disciple_draft  
**USING:**
- is_disciple_in_discipleship(discipleship_id)
- AND status IN ('draft', 'needs_changes')

**WITH CHECK:**
- is_disciple_in_discipleship(discipleship_id)

### DELETE
- ❌ Proibido

---

## reviews

### SELECT
**Policy:** reviews_select_scoped  
**USING:**
- is_disciple_in_discipleship(discipleship_id)
- OR is_mentor_in_discipleship(discipleship_id)
- OR is_admin_org(org_id)

### INSERT
**Policy:** reviews_insert_reviewer  
**WITH CHECK:**
- is_mentor_in_discipleship(discipleship_id)
- OR is_admin_org(org_id)

### UPDATE / DELETE
- ❌ Proibido

---

## user_achievements

### SELECT
**Policy:** user_achievements_select_self  
**USING:**
- user_id = uid()

### INSERT / UPDATE
- ❌ Proibido (server-side job)

### DELETE
- ❌ Proibido

---

## audit_events

### SELECT
**Policy:** audit_events_select_admin  
**USING:**
- is_admin_platform()
- OR is_admin_org(org_id)

### INSERT
- ❌ Proibido (RPC / Edge only)

### UPDATE / DELETE
- ❌ Proibido

---

## webhook_logs

### SELECT
**Policy:** webhook_logs_select_platform  
**USING:**
- is_admin_platform()

### INSERT
- ❌ Proibido (Edge only)

### UPDATE / DELETE
- ❌ Proibido

---

## Regra final
Qualquer policy:
- não listada aqui
- ou mais permissiva do que este mapa

**não deve ser criada**.