# API_CONTRACTS.md – Projeto SAVE

## 1. Objetivo
Definir os contratos das operações sensíveis do Projeto SAVE.

Regras:
- Operações sensíveis NÃO podem ser feitas por SQL direto no client.
- Todas as operações aqui devem falhar fechado.
- Toda operação crítica deve registrar `audit_events`.
- Nenhuma operação pode permitir acesso entre organizações.

---

## 2. Convenções

### 2.1 Identidade
- Usuário autenticado = `auth.uid()` (uid)
- Toda função deve validar `uid` não nulo.

### 2.2 Escopo
- Toda função que recebe `org_id` deve validar:
  - usuário é membro ativo da org
  - papel necessário
- Funções nunca retornam dados de outra org.

### 2.3 Erros padrão (payload sugerido)
Retornar erros padronizados como:
- `not_authenticated`
- `not_member`
- `not_allowed`
- `not_found`
- `invalid_input`
- `invalid_token`
- `expired_token`
- `revoked_token`
- `quota_exceeded`
- `no_seats_available`
- `subscription_inactive`
- `conflict`
- `internal_error`

---

## 3. Funções RPC (Postgres)

### 3.1 Conteúdo do professor (somente via RPC)
#### 3.1.1 get_teacher_lesson(org_id, lesson_id)
Objetivo:
- Retornar orientações e dicas do livro do professor para uma lição.

Quem pode chamar:
- discipulador (na org) com assinatura ativa
- group_leader (na org) (assinatura ativa se exigido)
- admin_org (na org)
- admin_platform

Validações obrigatórias:
- uid autenticado
- `is_member(org_id)`
- papel permitido:
  - is_admin_org(org_id) OR is_group_leader(org_id) OR (has_active_mentor_subscription(org_id))
- `lesson_id` existe e está published (ou permitir draft apenas para admin_platform)
- nunca retornar para usuário comum

Retorno:
- lesson_id
- notes_markdown
- tips (jsonb)
- common_mistakes (jsonb)

Auditoria:
- action: `teacher_lesson_viewed`
- entity_type: `lesson`
- entity_id: lesson_id
- metadata: { org_id }

---

#### 3.1.2 get_answer_key(org_id, question_id)
Objetivo:
- Retornar gabarito de uma questão.

Quem pode chamar:
- mesmo conjunto do get_teacher_lesson

Validações:
- uid autenticado
- `is_member(org_id)`
- papel permitido
- question_id existe

Retorno:
- question_id
- answer_key (jsonb)

Auditoria:
- action: `answer_key_viewed`
- entity_type: `question`
- entity_id: question_id
- metadata: { org_id }

---

### 3.2 Convites
#### 3.2.1 create_invite(org_id, email, group_id?, invited_flags, grant_seats)
Objetivo:
- Criar convite para entrar na org (igreja) como membro, opcionalmente:
  - adicionar a um grupo
  - atribuir role_group_leader
  - conceder seats (disciple/mentor)
  - marcar convidado como mentor (discipulador) e/ou disciple (discípulo)

Quem pode chamar:
- admin_org (na org)
- group_leader (na org) com restrições de escopo e quota

Validações obrigatórias:
- uid autenticado
- `is_member(org_id)`
- permissões:
  - admin_org: pode tudo
  - group_leader:
    - group_id deve estar preenchido
    - `leads_group(org_id, group_id)` deve ser true
    - não pode setar invited_role_admin_org = true
    - se invited_role_group_leader = true, só se admin permitir (opcional; padrão: proibido)
- validar email
- validar quotas e seats:
  - se grant_disciple_seats > 0:
    - verificar quota do leader (se for leader)
    - verificar pool disponível
  - se grant_mentor_seats > 0:
    - mesmo
- gerar token aleatório e salvar apenas hash
- inserir em `invites` status `pending` e expires_at (ex: 7 dias)

Retorno:
- invite_id
- status
- expires_at

Auditoria:
- action: `invite_created`
- entity_type: `invite`
- entity_id: invite_id
- metadata: { org_id, email, group_id, grants }

---

#### 3.2.2 revoke_invite(org_id, invite_id)
Quem pode chamar:
- admin_org
- group_leader somente se:
  - o invite for do group_id que ele lidera

Validações:
- uid autenticado
- `is_member(org_id)`
- invite pertence ao org_id
- status pending
- escopo para group_leader: `leads_group(org_id, invite.group_id)`

Efeito:
- set status = revoked

Retorno:
- ok boolean

Auditoria:
- action: `invite_revoked`
- entity_type: `invite`
- entity_id: invite_id

---

#### 3.2.3 accept_invite(token)
Objetivo:
- Aceitar convite usando token (somente token, sem SELECT do invite).

Quem pode chamar:
- qualquer usuário autenticado

Validações:
- uid autenticado
- localizar invite por token_hash
- status pending
- não expirado
- se invite concede seats:
  - verificar pool disponível
  - aplicar alocação (via allocate dentro da transação)
- criar/ativar membership em organization_members
- se group_id no convite: adicionar em group_memberships
- aplicar papéis administrativos permitidos
- marcar accepted_by_user_id, accepted_at e status accepted
- tudo transacional e idempotente contra replay:
  - uma vez aceito, não aceitar novamente

Retorno:
- org_id
- membership_id
- roles atribuídos
- group_id (se houve)

Auditoria:
- action: `invite_accepted`
- entity_type: `invite`
- entity_id: invite_id

---

### 3.3 Licenças
#### 3.3.1 allocate_license(org_id, target_user_id, license_type, qty, group_id?)
Objetivo:
- Alocar seats do pool para um usuário.

license_type:
- `disciple`
- `mentor`

Quem pode chamar:
- admin_org
- group_leader (restrito)

Validações:
- uid autenticado
- `is_member(org_id)`
- permissões:
  - admin_org: pode alocar para qualquer membro
  - group_leader:
    - group_id obrigatório
    - `leads_group(org_id, group_id)`
    - target_user_id deve estar em `group_memberships` desse group_id
    - respeitar quota
- verificar `org_license_pool` disponível
- atualizar `org_license_allocations` (create or upsert)
- atualizar contadores used no pool (ou derivar via soma; definir depois)

Retorno:
- allocation_id
- totals (allocated seats)

Auditoria:
- action: `license_allocated`
- entity_type: `license_allocation`
- entity_id: allocation_id
- metadata: { org_id, target_user_id, license_type, qty, group_id }

---

#### 3.3.2 revoke_license(org_id, target_user_id, license_type, qty, group_id?)
Objetivo:
- Revogar seats (devolver ao pool).

Quem pode chamar:
- admin_org
- group_leader (apenas no seu escopo, se permitido)

Validações:
- mesma lógica do allocate
- não permitir revogar abaixo de 0
- não revogar se seats estiverem em uso por discipulados ativos (regra a decidir; padrão: bloquear)

Retorno:
- allocation_id
- totals

Auditoria:
- action: `license_revoked`
- entity_type: `license_allocation`
- entity_id: allocation_id

---

### 3.4 Discipulado (criação e encerramento)
#### 3.4.1 create_discipleship(org_id, disciple_user_id)
Objetivo:
- Criar vínculo discipulador-discípulo dentro de uma org.

Quem pode chamar:
- discipulador (mentor) com assinatura ativa na org
- admin_org (opcional)
- group_leader (opcional e restrito; padrão: não)

Validações:
- uid autenticado
- `is_member(org_id)`
- `has_active_mentor_subscription(org_id)` (para uid)
- disciple_user_id é membro ativo da org
- verificar seats:
  - mentor tem disciple_seats_allocated suficiente ou a org individual tem seat disponível
- impedir duplicidade de discipulado ativo entre mesmas pessoas (opcional no MVP)
- inserir em discipleships status active
- consumir 1 seat de disciple (marcar used/consumo)
- registrar audit

Retorno:
- discipleship_id

Auditoria:
- action: `discipleship_created`
- entity_type: `discipleship`
- entity_id: discipleship_id

---

#### 3.4.2 complete_discipleship(org_id, discipleship_id)
Objetivo:
- Encerrar discipulado, bloquear interação e reemitir seat para o mentor.

Quem pode chamar:
- mentor do vínculo
- admin_org (casos administrativos)

Validações:
- uid autenticado
- `is_member(org_id)`
- discipulado pertence à org
- uid é mentor do vínculo OR admin_org
- status active

Efeitos (transacionais):
- discipleships.status = completed
- completed_at = now()
- reemitir seat de disciple para o mentor (devolver ao allocation/pool)
- criar desconto para o discípulo (desconto para iniciar org individual) se aplicável
- (futuro) notificação para ambos

Retorno:
- ok boolean

Auditoria:
- action: `discipleship_completed`
- entity_type: `discipleship`
- entity_id: discipleship_id

---

### 3.5 Liberação de conteúdo
#### 3.5.1 release_lesson(org_id, discipleship_id, lesson_id)
Quem pode chamar:
- mentor do vínculo (com assinatura ativa)

Validações:
- uid autenticado
- `is_mentor_in_discipleship(discipleship_id)`
- discipulado active
- assinatura ativa
- lição existe e está published
- inserir lesson_releases (idempotente via unique)

Retorno:
- release_id

Auditoria:
- action: `lesson_released`
- entity_type: `lesson_release`
- entity_id: release_id

---

#### 3.5.2 release_questions(org_id, discipleship_id, lesson_id)
Quem pode chamar:
- mentor do vínculo

Validações:
- uid autenticado
- mentor do vínculo
- lição já liberada (lesson_releases existe)
- inserir question_releases (idempotente)

Retorno:
- question_release_id

Auditoria:
- action: `questions_released`
- entity_type: `question_release`
- entity_id: question_release_id

---

## 4. Edge Functions

### 4.1 payments_webhook()
Objetivo:
- Processar confirmação de pagamentos e provisionar acesso.

Regras:
- validar assinatura do provedor
- idempotente por event_id
- registrar webhook_logs

Fluxos:
- compra individual:
  - criar org individual (se não existir)
  - criar membership do comprador
  - ativar assinatura
  - provisionar 1 seat de disciple inicial
- compra igreja:
  - atualizar org_license_pool (seats_total)
  - manter histórico

Auditoria:
- registrar `audit_events` de provisionamento (resumo)

---

### 4.2 internal_admin_ops()
Objetivo:
- Operações internas do admin_platform quando não couber RPC.

Regras:
- acesso restrito (admin_platform)
- registrar auditoria

---

## 5. Regras finais
- Se uma operação sensível não estiver aqui, ela deve ser considerada proibida até definição.
- Se houver dúvida entre permitir e negar, negar.
- Nenhuma função pode vazar dados de outra org.
- Teacher content somente via RPC.