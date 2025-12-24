# AUTH_AND_ONBOARDING.md – Projeto SAVE

## 1. Objetivo
Definir de forma explícita os fluxos de:
- autenticação
- criação de conta
- primeiro acesso
- convites
- múltiplas organizações
- troca de contexto (individual / igreja)

Este documento é a fonte de verdade para:
- frontend (guards e redirecionamentos)
- backend (RPCs e validações)
- agents (não inventar fluxos alternativos)

---

## 2. Princípios gerais

1. Autenticação é responsabilidade do Supabase Auth.
2. Associação a organizações é responsabilidade do backend (RPC).
3. Nenhum usuário “existe” no app sem estar ligado a pelo menos uma org.
4. Convites são o único meio de entrada em uma org existente.
5. Um usuário pode pertencer a múltiplas organizações.
6. O usuário sempre opera em **um contexto ativo de organização**.

---

## 3. Entidades envolvidas

- `auth.users` (Supabase)
- `user_profiles`
- `organizations`
- `organization_members`
- `invites`
- `org_subscriptions`
- `org_license_pool`
- `org_license_allocations`

---

## 4. Fluxos de entrada no sistema

## 4.1 Cadastro individual (sem convite)

### Cenário
Usuário acessa `/register` sem token de convite.

### Passos
1. Usuário cria conta via Supabase Auth.
2. Backend cria automaticamente:
   - uma `organization` do tipo `individual`
   - o usuário como membro ativo dessa org
3. O usuário recebe:
   - papel base de membro
   - nenhuma licença de mentor ativa inicialmente
4. Após cadastro:
   - redirecionar para `/app`
   - contexto ativo = org individual recém-criada

### Observações
- Licenças só são concedidas após pagamento.
- Nenhum convite é criado nesse fluxo.

---

## 4.2 Cadastro individual via compra (checkout)

### Cenário
Usuário inicia fluxo por `/pricing` → pagamento → cadastro.

### Passos
1. Usuário finaliza pagamento (sandbox ou real).
2. Webhook cria:
   - org individual
   - subscription ativa
   - licença inicial de disciple
3. Usuário cria conta ou faz login.
4. Backend associa usuário à org criada no webhook.
5. Redirecionar para `/app`.

### Regras
- A associação ao usuário só ocorre após autenticação.
- Webhook deve lidar com atraso entre pagamento e cadastro.

---

## 4.3 Aceite de convite (usuário novo)

### Cenário
Usuário recebe e-mail com `/invite/:token` e não tem conta.

### Passos
1. Usuário acessa link de convite.
2. Frontend detecta:
   - não autenticado
3. Redireciona para `/register`, preservando `token`.
4. Após cadastro:
   - chamar `accept_invite(token)`
5. Backend:
   - cria `organization_members`
   - concede papéis e licenças
6. Redirecionar para `/app`.

### Regra
- O token nunca deve ser exposto após aceite.
- Aceite é transacional e idempotente.

---

## 4.4 Aceite de convite (usuário existente)

### Cenário
Usuário já autenticado recebe convite.

### Passos
1. Usuário acessa `/invite/:token`.
2. Frontend detecta usuário autenticado.
3. Chama `accept_invite(token)` diretamente.
4. Backend associa usuário à nova org.
5. Redirecionar para `/app`.

---

## 4.5 Usuário com múltiplas organizações

### Exemplo
- Org individual
- Org igreja A
- Org igreja B

### Regras
- O usuário pode alternar orgs manualmente.
- Cada org mantém:
  - seus papéis
  - suas licenças
  - seus discipulados

### Implementação
- Frontend mantém `active_org_id` no estado.
- Backend valida tudo sempre via `org_id`.

---

## 5. Contexto ativo de organização

### 5.1 Definição
O contexto ativo define:
- permissões
- menus
- dados visíveis
- ações permitidas

### 5.2 Seleção inicial
Ao entrar em `/app`:
1. Se o usuário pertence a apenas 1 org:
   - definir automaticamente
2. Se pertence a mais de 1:
   - solicitar escolha (modal ou tela dedicada)

### 5.3 Troca de contexto
- Tela de perfil permite trocar org ativa.
- Troca limpa estados locais sensíveis.
- Nunca persistir contexto apenas no frontend sem validação backend.

---

## 6. Guards e redirecionamentos

### 6.1 Usuário não autenticado
- Qualquer rota `/app/*` redireciona para `/login`.

### 6.2 Usuário autenticado sem org
- Estado inválido.
- Redirecionar para fluxo de criação de org individual ou erro assistido.

### 6.3 Usuário autenticado com org, mas sem licença
- Permitir acesso de leitura.
- Bloquear ações de criação (ex.: criar discipulado).

---

## 7. Estados iniciais da UI

### Usuário recém-criado
- Empty states claros:
  - “Você ainda não iniciou nenhum discipulado”
  - “Convide alguém para caminhar com você”

### Usuário recém-convidado
- Destaque visual da nova org.
- Contexto ativo ajustado automaticamente.

---

## 8. Segurança e validações

- Nunca confiar em `active_org_id` vindo do frontend.
- Sempre validar membership e papel no backend.
- Convites não devem revelar:
  - estrutura interna
  - dados sensíveis da org
- Tokens devem ser:
  - hashados no banco
  - expirados automaticamente

---

## 9. Auditoria

Eventos mínimos:
- `user_registered`
- `organization_created`
- `invite_accepted`
- `org_context_changed`

Todos com:
- user_id
- org_id (quando aplicável)
- timestamp

---

## 10. Regras finais

- Não criar fluxos alternativos sem atualizar este documento.
- Se um cenário não estiver aqui, é considerado inválido.
- Em caso de dúvida:
  - bloquear ação
  - registrar evento
  - pedir decisão explícita