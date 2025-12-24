# API_CONTRACTS.md – Projeto SAVE

## 1. Objetivo
Definir os contratos oficiais de RPCs e Edge Functions do Projeto SAVE.

Regras:
- Nenhuma operação sensível deve ser feita via SQL direto do frontend.
- Toda operação que altera estado, permissão, licença ou fluxo de discipulado deve passar por RPC ou Edge Function.
- RLS continua ativo durante a execução das RPCs (exceto quando explicitamente usando service role).

---

## 2. Convenções gerais

### 2.1 Nomenclatura
- Funções: snake_case, inglês
- Parâmetros: snake_case
- Retornos: JSON com chaves claras

### 2.2 Autorização
- `auth.uid()` é a identidade canônica
- RPCs devem validar explicitamente permissões, mesmo com RLS ativo
- Nunca confiar apenas no frontend

### 2.3 Auditoria
Toda RPC sensível deve:
- registrar evento em `audit_events`
- incluir `actor_user_id`, `org_id`, `entity_type`, `entity_id`

---

## 3. Convites e onboarding

### 3.1 create_invite
Cria convite para entrar em uma organização.

**Assinatura**
```sql
create_invite(
  p_org_id uuid,
  p_email text,
  p_role_to_grant text,
  p_group_id uuid default null,
  p_license_grants_json jsonb default null
) returns uuid

Permissões
	•	admin_org
	•	group_leader (somente para seus grupos)

Validações
	•	usuário chamador é membro ativo da org
	•	se group_leader:
	•	leads_group(p_org_id, p_group_id) = true
	•	não pode conceder admin_org
	•	e-mail válido
	•	não criar convite duplicado ativo para mesmo email/org

Efeitos
	•	cria registro em invites
	•	gera token único (apenas o hash é persistido)
	•	registra audit_events: invite_created

⸻

3.2 accept_invite

Aceita convite por token.

Assinatura

accept_invite(
  p_token text
) returns jsonb

Permissões
	•	usuário autenticado

Validações
	•	token existe (via hash)
	•	status = pending
	•	não expirado
	•	token não reutilizado

Efeitos
	•	cria organization_members se não existir
	•	concede papéis (role_admin_org, role_group_leader) conforme convite
	•	adiciona a group_memberships se group_id presente
	•	concede licenças conforme license_grants_json
	•	marca convite como accepted
	•	registra audit_events: invite_accepted

⸻

4. Licenças e assinaturas

Nota geral
	•	Licenças podem ser:
	•	globais da organização (group_id = NULL)
	•	escopadas a um grupo específico (group_id != NULL)
	•	Apenas admin_org pode gerenciar licenças globais.
	•	group_leader só pode gerenciar licenças escopadas a grupos que lidera.

⸻

4.1 allocate_license

Aloca licença para usuário.

Assinatura

allocate_license(
  p_org_id uuid,
  p_user_id uuid,
  p_license_type text,
  p_group_id uuid default null
) returns void

Permissões
	•	admin_org
	•	group_leader (escopo limitado)

Validações
	•	p_license_type ∈ (‘disciple’,‘mentor’)
	•	seats disponíveis (derivados de org_license_pool_usage)
	•	se p_group_id IS NULL:
	•	somente admin_org
	•	se p_group_id IS NOT NULL:
	•	leads_group(p_org_id, p_group_id) = true para group_leader
	•	não criar allocation duplicada ativa para:
	•	(org_id, user_id, license_type, group_id)

Efeitos
	•	cria registro em org_license_allocations com status = active
	•	registra audit_events: license_allocated

⸻

4.2 revoke_license

Revoga licença de usuário.

Assinatura

revoke_license(
  p_org_id uuid,
  p_user_id uuid,
  p_license_type text,
  p_group_id uuid default null
) returns void

Permissões
	•	admin_org
	•	group_leader (escopo limitado)

Validações
	•	allocation ativa existente para a combinação:
	•	(org_id, user_id, license_type, group_id)
	•	se p_group_id IS NULL:
	•	somente admin_org
	•	se p_group_id IS NOT NULL:
	•	leads_group(p_org_id, p_group_id) = true
	•	não permitir revogar se:
	•	licença está em uso por discipulado ativo (ex.: mentor ativo)

Efeitos
	•	atualiza allocation para status = revoked
	•	registra audit_events: license_revoked

⸻

5. Discipulados

5.1 create_discipleship

Cria discipulado entre mentor e discípulo.

Assinatura

create_discipleship(
  p_org_id uuid,
  p_disciple_user_id uuid
) returns uuid

Permissões
	•	mentor (usuário chamador)

Validações
	•	has_active_mentor_subscription(p_org_id, auth.uid()) = true
	•	mentor possui licença ativa de mentor (se igreja)
	•	disciple possui licença ativa de disciple
	•	ambos são membros ativos da org
	•	não existe discipulado ativo duplicado (mentor + disciple)

Efeitos
	•	cria registro em discipleships com status = active
	•	registra audit_events: discipleship_created

⸻

5.2 complete_discipleship

Encerra discipulado.

Assinatura

complete_discipleship(
  p_discipleship_id uuid
) returns void

Permissões
	•	mentor do discipulado
	•	admin_org

Validações
	•	discipulado status = active

Efeitos
	•	status → completed
	•	define completed_at
	•	libera nova licença de disciple para o mentor (quando aplicável)
	•	registra audit_events: discipleship_completed

⸻

6. Liberação de conteúdo

6.1 release_lesson

Libera lição para discipulado.

Assinatura

release_lesson(
  p_discipleship_id uuid,
  p_lesson_id uuid
) returns void

Permissões
	•	mentor do discipulado

Validações
	•	discipulado status = active
	•	lição pertence ao currículo publicado
	•	idempotente (unique constraint)

Efeitos
	•	cria lesson_releases
	•	registra audit_events: lesson_released

⸻

6.2 release_questions

Libera o conjunto de perguntas da lição.

Assinatura

release_questions(
  p_discipleship_id uuid,
  p_lesson_id uuid
) returns void

Permissões
	•	mentor do discipulado

Validações
	•	discipulado status = active
	•	lição já liberada
	•	idempotente (unique(discipleship_id, lesson_id))

Efeitos
	•	cria question_releases
	•	registra audit_events: questions_released

⸻

7. Conteúdo do professor (sensível)

7.1 get_teacher_lesson

Retorna notas do professor para uma lição.

Assinatura

get_teacher_lesson(
  p_lesson_id uuid
) returns jsonb

Permissões
	•	mentor com assinatura ativa
	•	admin_org
	•	admin_platform

Validações
	•	lição publicada
	•	usuário autorizado

Efeitos
	•	SELECT em teacher_notes
	•	registra audit_events: teacher_lesson_viewed

⸻

7.2 get_answer_key

Retorna gabarito de uma pergunta.

Assinatura

get_answer_key(
  p_question_id uuid
) returns jsonb

Permissões
	•	mentor do discipulado relacionado
	•	admin_org
	•	admin_platform

Validações
	•	pergunta pertence a lição liberada ao discipulado
	•	usuário autorizado

Efeitos
	•	SELECT em answer_keys
	•	registra audit_events: answer_key_viewed

⸻

8. Webhooks (Edge Functions)

8.1 payments_webhook

Processa eventos de pagamento.

Responsabilidades
	•	validar assinatura do provedor
	•	garantir idempotência (provider + event_id)
	•	atualizar:
	•	org_subscriptions
	•	org_license_pool
	•	nunca confiar no frontend

Efeitos
	•	cria/atualiza registros conforme tipo de evento
	•	registra webhook_logs
	•	registra audit_events relevantes

⸻

9. Regras finais
	•	Nenhuma RPC deve ignorar RLS sem justificativa explícita.
	•	Toda regra de permissão aqui deve existir também em:
	•	RLS_RULES.md
	•	RLS_POLICY_MAP.md
	•	Em caso de conflito, a implementação mais restritiva vence.