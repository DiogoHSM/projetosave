# STATE_MACHINE.md – Projeto SAVE

## 1. Objetivo
Definir as máquinas de estados oficiais do Projeto SAVE para:
- disciplinar transições (quem pode mudar o quê)
- evitar inconsistências entre frontend e backend
- orientar RPCs, RLS e validações
- reduzir bugs em fluxos de liberação/revisão

Regras:
- Se uma transição não estiver definida aqui, ela é proibida.
- Backend sempre valida transições (RPC/DB), frontend apenas reflete.
- Transições importantes devem gerar `audit_events`.

---

## 2. Entidades com máquina de estados

- Discipulado: `discipleships.status`
- Respostas: `answers.status`
- Convites: `invites.status`
- Conteúdo: `studies/modules/lessons.status` (controle editorial)
- Webhooks: `webhook_logs.status`
- Notificações: `notifications_outbox.status`

---

## 3. Discipulado (`discipleships.status`)

### 3.1 Estados
- `active` – discipulado em andamento (interação permitida)
- `completed` – encerrado (somente leitura, sem novas liberações/respostas)
- `archived` – oculto/encerrado administrativamente (somente leitura)

### 3.2 Transições permitidas

#### A) Criar discipulado
- `null -> active`
Quem pode:
- mentor (discipulador) com assinatura ativa
- admin da igreja (opcional, quando existir permissão)

Pré-condições:
- `has_active_mentor_subscription(org_id)` para o mentor (quando aplicável)
- mentor e discípulo são membros ativos da org
- seats/licenças disponíveis conforme política de licenças
Efeitos:
- criar registro em `discipleships`
- `audit_events`: `discipleship_created`

---

#### B) Encerrar discipulado
- `active -> completed`
Quem pode:
- mentor do vínculo
- admin_org da org

Pré-condições:
- discipulado existe e pertence à org
- status atual = active
Efeitos:
- set `completed_at = now()`
- bloquear novas liberações e novas respostas
- reemitir seat/licença de discípulo para o mentor (via RPC)
- (opcional) gerar desconto para o discípulo iniciar uma org individual
- `audit_events`: `discipleship_completed`

---

#### C) Arquivar discipulado
- `completed -> archived`
- `active -> archived` (somente para casos administrativos)
Quem pode:
- admin_org
- admin_platform

Pré-condições:
- discipulado pertence à org
Efeitos:
- set `archived_at = now()`
- `audit_events`: `discipleship_archived`

---

### 3.3 Transições proibidas (exemplos)
- `completed -> active` (não reabrir no MVP)
- `archived -> active`
- deletar discipulado (usar archive)

---

## 4. Liberação de conteúdo (controle de acesso)

### 4.1 Lição liberada (`lesson_releases`)
Não é status, mas funciona como “marco”:
- se não existe release: lição não pode ser acessada pelo discípulo
- se existe: lição pode ser lida (conforme RLS)

Regras:
- liberar lição é idempotente (unique)
- só mentor do discipulado pode liberar
- só liberar se discipulado `active`

Eventos:
- `lesson_released`

### 4.2 Perguntas liberadas (`question_releases`)
Mesma lógica:
- sem release: perguntas não aparecem
- com release: perguntas e respostas habilitadas

Regras:
- só mentor pode liberar
- só liberar se lição já foi liberada
- só liberar se discipulado `active`

Evento:
- `questions_released`

---

## 5. Respostas (`answers.status`)

### 5.1 Estados
- `draft` – rascunho (editável pelo discípulo)
- `submitted` – enviado pelo discípulo (não editável por padrão)
- `in_review` – em revisão (mentor assumiu análise)
- `needs_changes` – mentor pediu ajustes (editável pelo discípulo)
- `approved` – aprovado (somente leitura)

Observação:
- `draft` pode existir antes de liberar perguntas? Não. Só após `question_releases`.

### 5.2 Transições permitidas

#### A) Criar/editar rascunho
- `null -> draft`
- `draft -> draft` (editar)
Quem pode:
- discípulo do discipulado

Pré-condições:
- discipulado `active`
- perguntas liberadas para aquela lição (existe question_release)
- question_id pertence à lesson_id
Regras:
- salvar frequentemente
Efeitos:
- atualizar `answer_payload`
- `submitted_at` permanece null

Evento (opcional):
- `answer_drafted` (pode ser ruidoso; opcional)

---

#### B) Enviar resposta
- `draft -> submitted`
Quem pode:
- discípulo do discipulado

Pré-condições:
- discipulado `active`
- perguntas liberadas
- validação mínima do payload conforme tipo da pergunta
Efeitos:
- set `submitted_at = now()`
- `audit_events`: `answer_submitted`

---

#### C) Iniciar revisão
- `submitted -> in_review`
Quem pode:
- mentor do discipulado
- admin_org (se necessário para suporte)

Pré-condições:
- discipulado `active`
Efeitos:
- `audit_events`: `answer_review_started`

---

#### D) Pedir ajustes
- `submitted -> needs_changes`
- `in_review -> needs_changes`
Quem pode:
- mentor do discipulado
- admin_org

Pré-condições:
- discipulado `active`
Efeitos:
- inserir `reviews` com decision `needs_changes`
- `audit_events`: `answer_needs_changes`

---

#### E) Ajustar e reenviar
- `needs_changes -> draft` (ao editar) OU manter `needs_changes` enquanto edita
- `needs_changes -> submitted` (reenviar)
Quem pode:
- discípulo do discipulado

Pré-condições:
- discipulado `active`
Efeitos:
- atualizar `answer_payload`
- update `submitted_at` quando reenviar (ou manter e criar `resubmitted_at` no futuro; MVP pode atualizar submitted_at)
- `audit_events`: `answer_resubmitted`

---

#### F) Aprovar
- `submitted -> approved`
- `in_review -> approved`
- `needs_changes -> approved` (permitido se mentor decidir aprovar mesmo assim)
Quem pode:
- mentor do discipulado
- admin_org

Pré-condições:
- discipulado `active`
Efeitos:
- inserir `reviews` com decision `approved`
- `audit_events`: `answer_approved`

---

### 5.3 Regras de bloqueio após término do discipulado
Se `discipleships.status != active` então:
- não permitir:
  - criar releases
  - criar/editar/reenviar answers
  - criar reviews
- permitir somente leitura para participantes e admin conforme RLS

---

## 6. Convites (`invites.status`)

### 6.1 Estados
- `pending`
- `accepted`
- `revoked`
- `expired`

### 6.2 Transições
- `null -> pending` (create_invite)
- `pending -> accepted` (accept_invite)
- `pending -> revoked` (revoke_invite)
- `pending -> expired` (job/trigger por tempo)

Regras:
- após `accepted/revoked/expired`, token não pode ser reutilizado
- aceitar convite é transacional e idempotente contra replay

---

## 7. Conteúdo editorial (currículo)

Aplica a:
- `studies.status`
- `modules.status`
- `lessons.status`

### 7.1 Estados
- `draft`
- `published`
- `archived`

### 7.2 Transições
- `draft -> published`
- `published -> archived`
- `archived -> published` (opcional; recomendado bloquear no MVP)

Quem pode:
- admin_platform (somente)

Regras:
- conteúdos `archived` não devem ser usados para novos discipulados
- conteúdos `draft` não devem aparecer para usuários comuns

---

## 8. Webhook logs (`webhook_logs.status`)

### Estados
- `received`
- `processed`
- `failed`

Transições:
- `received -> processed`
- `received -> failed`
- `failed -> processed` (retry manual/automático)

Regras:
- idempotência por (provider, event_id)

---

## 9. Notificações (`notifications_outbox.status`)

### Estados
- `pending`
- `sent`
- `failed`

Transições:
- `pending -> sent`
- `pending -> failed`
- `failed -> sent` (retry)

Regras:
- `attempts` incrementa em cada tentativa
- backoff simples para retry

---

## 10. Eventos e auditoria (mínimo recomendado)

Registrar `audit_events` para:
- `discipleship_created`
- `discipleship_completed`
- `discipleship_archived`
- `lesson_released`
- `questions_released`
- `answer_submitted`
- `answer_review_started`
- `answer_needs_changes`
- `answer_resubmitted`
- `answer_approved`
- `invite_created`
- `invite_accepted`
- `invite_revoked`
- `license_allocated`
- `license_revoked`
- `teacher_lesson_viewed`
- `answer_key_viewed`

---

## 11. Regras finais
- O frontend não pode “inventar” status.
- O backend não pode permitir transições fora deste documento.
- Quando houver dúvida, negar transição e registrar evento de segurança.