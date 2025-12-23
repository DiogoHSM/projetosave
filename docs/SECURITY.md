# SECURITY.md – Projeto SAVE

## 1. Objetivo
Este documento define as **regras de segurança obrigatórias** do Projeto SAVE.

Ele existe para:
- reduzir risco de vazamentos de dados
- evitar falhas de permissão
- proteger conteúdo sensível (especialmente o livro do professor)
- permitir desenvolvimento com code agents de forma segura

Este documento tem **prioridade sobre conveniência, velocidade ou simplicidade de código**.

---

## 2. Princípios inegociáveis

### 2.1 Deny by default
- Toda tabela deve ter RLS habilitado.
- Se uma policy não existir explicitamente, o acesso deve falhar.
- Nunca usar `USING (true)` ou policies genéricas.

### 2.2 O banco é o guardião final
- O frontend **não é confiável**.
- Mesmo que a UI esconda botões, o banco deve bloquear ações indevidas.
- Toda regra crítica deve estar garantida por RLS ou RPC.

### 2.3 Nunca usar service_role no frontend
- `service_role` é **exclusivo** de:
  - Edge Functions
  - scripts administrativos controlados
- Qualquer uso de `service_role` no client é considerado falha crítica.

### 2.4 Operações sensíveis não são feitas por SQL direto
São consideradas operações sensíveis:
- criação e aceite de convites
- concessão e revogação de licenças
- leitura do livro do professor (gabarito/orientações)
- encerramento de discipulado
- publicação de conteúdo
- webhooks de pagamento

Essas operações devem ocorrer **somente via RPC (Postgres Function)** ou **Edge Function**.

### 2.5 Conteúdo do professor é altamente sensível
- Tabelas de gabarito e orientações **não podem ter SELECT direto** para usuários comuns.
- O acesso deve ocorrer apenas por RPC que valide:
  - usuário autenticado
  - membership na organização
  - papel permitido (discipulador, group_leader, admin_org)
  - assinatura ativa quando aplicável

---

## 3. Modelo de confiança (Trust Model)

### 3.1 Entidades não confiáveis
- navegador do usuário
- código frontend
- requisições HTTP externas
- dados manipulados no client

### 3.2 Entidades confiáveis
- Postgres com RLS
- RPCs com `SECURITY DEFINER`
- Edge Functions com validação explícita
- Supabase Auth (como identidade)

---

## 4. Regras obrigatórias por tipo de dado

### 4.1 Dados multi-tenant (org_id)
- Toda tabela relacionada a usuários, discipulados, grupos, licenças ou respostas deve:
  - conter `org_id`
  - validar que `org_id` pertence ao usuário autenticado
- Usuário **nunca** pode acessar dados de outra organização.

### 4.2 Dados globais
- Conteúdo (estudos, módulos, lições) é global.
- Escrita nesses dados é **exclusiva** do `admin_platform`.
- Leitura pode ser pública ou autenticada, conforme definido em RLS.

### 4.3 Dados pessoais
- Dados pessoais devem ser mínimos.
- Nunca expor e-mails ou IDs de outros usuários sem necessidade.
- Relatórios devem usar agregações quando possível.

---

## 5. Convites (Invites)

### 5.1 Tokens
- Tokens de convite:
  - devem ser aleatórios e imprevisíveis
  - devem ser armazenados apenas como **hash**
- Nunca armazenar token em texto puro.

### 5.2 Expiração e revogação
- Todo convite deve ter:
  - data de expiração
  - status (pending, accepted, revoked, expired)
- Convites revogados ou expirados não podem ser reutilizados.

### 5.3 Aceite de convite
- Aceite deve:
  - validar token
  - validar expiração
  - validar quota/licença disponível
  - criar membership de forma atômica
- O mesmo token não pode ser aceito duas vezes.

---

## 6. Licenças e quotas

### 6.1 Regras gerais
- Licenças nunca são inferidas pelo frontend.
- O banco é a única fonte de verdade para:
  - pool de licenças
  - alocações
  - quotas

### 6.2 Quotas de líder de grupo
- Líder de grupo só pode:
  - convidar usuários para grupos que lidera
  - conceder licenças dentro da sua quota
- Essas regras devem ser verificadas no backend (RPC ou RLS).

### 6.3 Falha segura
- Se houver qualquer inconsistência:
  - negar a operação
  - registrar audit_event
- Nunca “corrigir automaticamente” sem validação explícita.

---

## 7. Fluxo de discipulado

### 7.1 Liberação de conteúdo
- Lição ou questão só pode ser acessada se:
  - existir um release válido
  - o usuário fizer parte daquele discipulado
- O banco deve impedir acesso antecipado.

### 7.2 Revisão
- Apenas o discipulador responsável pode revisar respostas.
- Exceção:
  - admin_org ou group_leader pode revisar se:
    - estiver na mesma organização
    - tiver escopo correto
- Toda revisão deve ser registrada.

### 7.3 Encerramento
- Encerrar discipulado:
  - bloqueia novas interações
  - mantém leitura
  - reemite seat de discípulo
- Deve ser transacional (tudo ou nada).

---

## 8. Pagamentos e webhooks

### 8.1 Webhooks
- Webhooks devem ser:
  - autenticados (assinatura do provedor)
  - idempotentes (event_id)
- Um mesmo evento não pode provisionar recursos duas vezes.

### 8.2 Logs
- Todo webhook deve gerar registro em `webhook_logs`:
  - payload
  - status
  - erro (se houver)

---

## 9. Auditoria (obrigatória)

### 9.1 O que deve gerar audit_event
- concessão/revogação de licenças
- criação/aceite/revogação de convites
- mudança de papéis
- liberação de lições e questões
- revisões
- encerramento de discipulados
- publicação/edição de conteúdo
- falhas de autorização relevantes

### 9.2 Conteúdo do audit_event
- actor_user_id
- org_id (quando aplicável)
- ação
- entidade afetada
- metadata (json)
- timestamp

---

## 10. Proteções adicionais recomendadas

### 10.1 Rate limiting
- Convites
- Aceite de convite
- Revisões
- Publicação de conteúdo
- Webhooks

### 10.2 Falhar fechado
- Em caso de erro inesperado:
  - negar ação
  - não retornar dados sensíveis
  - registrar log

---

## 11. Testes manuais obrigatórios (pré-produção)

### 11.1 Casos que DEVEM falhar
- Discípulo tentando acessar gabarito
- Usuário de outra org acessando dados
- Líder de grupo tentando atuar fora do grupo
- Usuário sem assinatura ativa liberando lição
- Reutilização de convite aceito
- Webhook duplicado provisionando duas vezes

### 11.2 Casos que DEVEM funcionar
- Discipulador acessando livro do professor via RPC
- Admin concedendo licença
- Líder de grupo concedendo licença dentro da quota
- Encerramento de discipulado com reemissão de seat
- Leitura de histórico após encerramento

---

## 12. Regra final para agents

Se uma implementação:
- violar qualquer item deste documento
- exigir enfraquecer RLS
- depender de segredo no frontend

**ela não deve ser implementada**.

Em caso de dúvida:
- parar
- registrar TODO
- pedir decisão explícita