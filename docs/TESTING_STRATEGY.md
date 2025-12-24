# TESTING_STRATEGY.md – Projeto SAVE

## 1. Objetivo
Definir a estratégia mínima e obrigatória de testes do Projeto SAVE para reduzir:
- bugs em fluxos críticos (liberação, respostas, revisão, encerramento)
- brechas de segurança (RLS/RPC)
- regressões em UI e regras de permissão

Este documento foca em testes de alto impacto e baixo custo, adequados para um time pequeno e desenvolvimento com code agents.

---

## 2. Princípios

- Testar primeiro o que é **irreversível**: permissões, licenças, pagamentos, auditoria.
- Preferir testes automatizados que validem **RLS/RPC** diretamente no banco.
- Se uma regra estiver em `RLS_POLICY_MAP.md` ou `STATE_MACHINE.md`, deve existir teste.
- Falhar fechado: se o teste não for criado ainda, a feature deve ficar bloqueada por default.

---

## 3. Pirâmide de testes (mínimo viável)

### 3.1 Nível 1: Testes de banco (obrigatórios)
Foco:
- RLS
- constraints
- RPCs (transações e validações)

Ferramentas (sugestão):
- `pgTAP` ou testes via script `psql`/Node/Python com assertions
- execução em CI

### 3.2 Nível 2: Testes de integração (obrigatórios)
Foco:
- fluxos end-to-end sem UI
- chamando Supabase client + RPC + verificando resultados

Ferramentas (sugestão):
- Vitest/Jest (Node)
- Supabase JS client (service role no CI com cuidado)

### 3.3 Nível 3: Testes de UI (recomendado, mas seletivo)
Foco:
- rotas e guards
- renderização de estados (loading/empty/error)
- formulários de perguntas e rascunho

Ferramentas (sugestão):
- Playwright (2-3 fluxos críticos)
- Testing Library (componentes críticos)

---

## 4. Ambientes de teste

### 4.1 Local
- Supabase local (docker) com seed de dados
- executar migrations e policies

### 4.2 CI
- pipeline que roda:
  - lint
  - migrations
  - testes de banco
  - testes de integração
  - (opcional) testes UI em PRs

### 4.3 Staging
- ambiente espelho do prod
- usado para validação manual de pagamento/webhooks

Regras:
- nunca usar produção para testes
- sempre mascarar dados e segredos

---

## 5. Seeds e fixtures (obrigatório)

Criar dataset padrão de teste com:
- 2 organizações:
  - `org_church_A`
  - `org_individual_B`
- usuários:
  - admin_platform
  - admin_org_A
  - group_leader_A1
  - member_A1
  - member_A2
  - mentor_B
  - disciple_B1
- grupos:
  - group_A1
  - group_A2
- memberships:
  - member_A1 em group_A1
  - member_A2 em group_A2
- 1 discipulado ativo em org A e 1 em org B

Fixtures devem cobrir:
- convite pending, accepted e revoked
- pelo menos uma lição com perguntas de cada tipo

---

## 6. Matriz de testes obrigatórios

## 6.1 RLS – testes por tabela (mínimo)

Para cada tabela listada em `RLS_POLICY_MAP.md`, criar testes de:
- SELECT permitido
- SELECT negado
- INSERT/UPDATE/DELETE negados quando proibidos
- WITH CHECK aplicado (não permitir escrever em outra org)

Lista mínima de tabelas críticas:
- `organizations`
- `organization_members`
- `groups`
- `group_memberships`
- `group_leaders`
- `invites`
- `org_license_pool`
- `org_license_allocations`
- `discipleships`
- `lesson_releases`
- `question_releases`
- `answers`
- `reviews`
- `audit_events`
- `webhook_logs`

Regras extras:
- garantir que `lesson_teacher_notes` e `question_answer_keys` **não tenham SELECT direto**.

---

## 6.2 RPC – testes por função (obrigatório)

### 6.2.1 `accept_invite(token)`
Casos:
- token válido aceita e cria membership
- token expirado falha
- token revogado falha
- token aceito novamente falha (idempotência)
- convite com group_id adiciona membership ao grupo
- convite concede seats atualiza allocations/pool corretamente
- usuário de outra org não ganha acesso a nada fora do escopo

---

### 6.2.2 `create_invite(...)`
Casos:
- admin_org cria convite sem group_id
- group_leader cria convite com group_id do seu grupo (ok)
- group_leader tenta criar convite com group_id de outro grupo (falha)
- group_leader tenta convidar como admin_org (falha)
- valida email inválido (falha)
- valida quota excedida (falha)
- registra audit_event

---

### 6.2.3 `allocate_license(...)` e `revoke_license(...)`
Casos:
- admin_org aloca seats para membro (ok)
- group_leader aloca seats para membro do seu grupo (ok)
- group_leader tenta alocar para membro fora do seu grupo (falha)
- não permitir alocar acima do pool (falha)
- não permitir revogar abaixo de 0 (falha)
- (se aplicável) bloquear revogação se seat em uso por discipulado ativo (falha)
- registra audit_event

---

### 6.2.4 `create_discipleship(org_id, disciple_user_id)`
Casos:
- mentor com assinatura ativa cria discipulado (ok)
- mentor sem assinatura ativa falha
- mentor sem seat disponível falha
- disciple fora da org falha
- duplicidade de discipulado ativo (se implementado) falha
- registra audit_event

---

### 6.2.5 `release_lesson` e `release_questions`
Casos:
- mentor libera lição (ok)
- mentor libera perguntas sem lição liberada (falha)
- idempotência (repetir chamada não duplica)
- não permitir se discipulado completed/archived
- registra audit_event

---

### 6.2.6 Conteúdo do professor: `get_teacher_lesson` e `get_answer_key`
Casos:
- mentor com permissão acessa (ok)
- usuário comum falha
- usuário de outra org falha
- admin_platform acessa (ok)
- registrar audit_event
- garantir que dados sensíveis não são retornados fora do contrato

---

## 6.3 STATE_MACHINE – testes de transição (obrigatório)

### 6.3.1 Discipleship
- active -> completed permitido apenas para mentor ou admin_org
- completed -> active proibido
- archived -> active proibido
- active -> archived apenas admin_org/admin_platform

### 6.3.2 Answers
- null -> draft apenas discípulo e com question_release existente
- draft -> submitted apenas discípulo
- submitted -> in_review apenas mentor/admin_org
- submitted -> needs_changes apenas mentor/admin_org
- needs_changes -> submitted apenas discípulo
- submitted/in_review/needs_changes -> approved apenas mentor/admin_org
- qualquer mudança se discipulado != active deve falhar

---

## 6.4 Integração – fluxos críticos (obrigatório)

### Fluxo 1: Discipulado completo (happy path)
- criar discipulado
- liberar lição 1
- liberar perguntas 1
- discípulo responde (draft -> submitted)
- mentor revisa e aprova
- mentor libera lição 2
- encerrar discipulado
Verificações:
- respostas bloqueadas após complete
- histórico somente leitura

---

### Fluxo 2: Ajustes (needs_changes)
- mentor pede mudanças
- discípulo edita e reenviar
- mentor aprova
Verificações:
- status correto
- reviews registrados e imutáveis

---

### Fluxo 3: Igreja com líder de grupo
- group_leader convida membro para group_A1
- group_leader aloca seats dentro da quota
- tenta alocar fora do grupo (falha)
Verificações:
- escopo de visibilidade correto
- RLS impede vazamento

---

## 6.5 Pagamentos / Webhooks (recomendado, mas importante)

### 6.5.1 Idempotência
- enviar o mesmo webhook duas vezes não duplica provisionamento

### 6.5.2 Provisionamento individual
- cria org individual
- ativa subscription
- provisiona 1 disciple seat inicial

### 6.5.3 Provisionamento igreja
- incrementa pool de seats
- registra audit_event

Observação:
- testes de webhook podem ser executados em staging ou em ambiente de CI com mocks.

---

## 7. Testes manuais (checklist mínimo)

Antes de cada release:
- login/cadastro
- aceitar convite
- criar discipulado
- liberar lição e perguntas
- responder e enviar
- revisar e aprovar
- encerrar discipulado
- verificar bloqueio pós-encerramento
- verificar menus por perfil (discípulo vs discipulador vs admin)

---

## 8. Critérios de aceite (gate de qualidade)

Uma PR só pode ser considerada pronta se:
- não reduz cobertura dos testes críticos
- não altera RLS sem atualizar `RLS_POLICY_MAP.md` e testes
- não altera estados sem atualizar `STATE_MACHINE.md` e testes
- fluxos 1 e 2 (integração) passam

---

## 9. Arquivos esperados no repositório (futuro)
Sugestão de organização:
- `tests/db/` (RLS + RPC)
- `tests/integration/` (fluxos)
- `tests/ui/` (Playwright)
- `scripts/seed/` (fixtures)
- `scripts/test/` (runner)

---

## 10. Princípio final
No Projeto SAVE:
- permissão errada é bug crítico
- vazamento de dados é bug crítico
- transição inválida é bug crítico

Testes existem para garantir que o sistema falhe fechado.