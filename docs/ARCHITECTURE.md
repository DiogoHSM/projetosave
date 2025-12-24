# Projeto SAVE – Arquitetura do Sistema

## 0. Objetivo deste documento
Este arquivo define a arquitetura e regras do Projeto SAVE para orientar desenvolvimento com code agents, reduzindo risco de falhas de permissão, vazamentos e inconsistências.

Princípios operacionais:
- Segurança por padrão (deny by default).
- Menos código backend próprio.
- RLS como guardião definitivo.
- Operações sensíveis via RPC/Edge Functions.
- Auditoria obrigatória para ações administrativas.

---

## 1. Visão geral
### 1.1 Objetivo do produto
Projeto SAVE é um aplicativo SaaS de discipulado cristão para permitir que um discipulador acompanhe um discípulo em estudos estruturados, progressivos e relacionais, promovendo crescimento espiritual e multiplicação do discipulado.

O sistema controla a liberação manual de conteúdos, acompanha respostas, registra histórico e incentiva que discípulos formados iniciem novos discipulados.

### 1.2 Princípios do produto
- Conteúdo doutrinário único e padronizado.
- Liberação sempre manual, conduzida pelo discipulador.
- Ênfase em relacionamento e formação, não competição.
- Multiplicação orgânica do discipulado.
- Simplicidade operacional para indivíduos e igrejas.
- Segurança por padrão (isolamento multi-tenant, RLS).
- Evolução incremental (MVP com base sólida para crescer).

### 1.3 Não objetivos (por enquanto)
- Conteúdo customizado por igreja.
- Ranking público e competição entre usuários.
- Encontro online dentro do app como prioridade.
- App mobile nativo no MVP.

---

## 2. Modelo multi-tenant e tipos de acesso
O sistema é multi-tenant baseado em **organizações (orgs)**, que podem ser do tipo:
- `individual`
- `igreja`

Toda autenticação, autorização, licenciamento, convites, relatórios e auditoria são contextualizados por organização.

Regra crítica:
- Nenhum dado de uma organização deve ser acessível por usuários de outra organização.

---

## 3. Usuários, organizações e papéis
### 3.1 Papéis no contexto de uma organização
Papéis funcionais:
- discipulador
- discipulo

Papéis administrativos (apenas no modelo igreja):
- admin_org (administrador da igreja)
- group_leader (líder de grupo)

Papel global:
- admin_platform (admin interno da plataforma)

### 3.2 Regras gerais
- Um usuário pode ser discipulador e discípulo simultaneamente.
- Um usuário pode pertencer a múltiplas organizações.
- Papéis sempre são atribuídos no contexto de uma organização, exceto `admin_platform`, que é global.

### 3.3 Superset de permissões (igreja)
No modelo `igreja`:
- `admin_org` tem tudo que um discipulador tem + gestão completa (membros, grupos, licenças, billing, branding, relatórios globais).
- `group_leader` tem tudo que um discipulador tem + relatórios e gestão apenas dos grupos que lidera + distribuição limitada de licenças dentro desses grupos.
- Usuário normal não tem gestão administrativa.

---

## 4. Troca de contexto (org + modo)
O usuário pode alternar:
- organização ativa (ex: Igreja A, Igreja B, Individual do usuário)
- modo de atuação (discipulador ou discípulo) na org ativa

A UI deve refletir claramente o contexto atual.

Recomendação:
- Persistir contexto ativo no client (localStorage).
- Opcionalmente persistir no backend (ex: `user_preferences`).

---

## 5. Tipos de organização e provisionamento
### 5.1 Organização Individual (criação automática)
Criada automaticamente no momento da compra de uma licença de discipulador.

Fluxo:
1) pagamento confirmado (webhook)
2) criar org `type=individual` (se não existir para aquele comprador)
3) criar membership do comprador como discipulador
4) ativar assinatura de discipulador
5) provisionar automaticamente 1 licença de discípulo (seat)

### 5.2 Organização Igreja
- Criada e mantida por uma igreja.
- A igreja compra pacotes de licenças e distribui aos seus membros.
- Governança de distribuição por admin e líderes de grupo (seção 10).

---

## 6. Conteúdo e progressão
### 6.1 Conteúdo global
- Conteúdo único, global e controlado pela plataforma (admin_platform).
- Estrutura:
  - estudo
  - módulos
  - lições
  - blocos (partes) da lição
  - questões

Customização por igreja:
- apenas visual (logo, cores, contato)

### 6.2 Lição em múltiplas partes (blocos)
Uma lição possui 1..N blocos ordenáveis.

Exemplos:
- texto introdutório
- vídeo
- texto principal
- imagens e ilustrações
- anexos/recursos

Tipos de bloco recomendados:
- `rich_text` (markdown ou editor rich text)
- `image` (url + legenda)
- `video` (url/embed + título/descrição)
- `download` (arquivo no storage)
- `callout` (destaque/nota)

Requisitos:
- inserir imagens ao longo do texto (por link no markdown ou referências a storage).
- vídeo pode ser bloco separado ou referência associada à lição.
- drag and drop no admin (ideal).
- metadados por bloco (ex: “mostrar antes das perguntas”).

### 6.3 Tipos de questões
- Texto aberto
- Múltipla escolha
- Associação
- Verdadeiro ou falso

Regras de validação por tipo:
- múltipla escolha: 2..N opções, 1 correta
- verdadeiro/falso: alternativas fixas (true/false)
- associação: pares esquerda/direita, resposta em mapeamento
- texto aberto: sem gabarito rígido, mas pode ter referência ou pontos esperados

### 6.4 Livro do professor (camada professor)
Acesso:
- discipulador
- group_leader
- admin_org
- admin_platform

Conteúdo:
- gabaritos por questão
- orientações por lição (e opcionalmente por bloco)
- roteiro do encontro
- dicas e macetes
- erros comuns

Segurança obrigatória:
- tabelas de professor sem SELECT direto para usuários comuns
- acesso apenas por RPC que checa: papel e assinatura ativa na org

### 6.5 Fluxo de estudo (manual)
1) discipulador libera a lição  
2) encontro ocorre fora do app ou presencial  
3) discipulador libera as questões  
4) discípulo responde (rascunho opcional)  
5) discípulo envia respostas  
6) discipulador revisa  
7) discipulador libera próxima lição  

---

## 7. Respostas, estados e revisão
### 7.1 Estados do fluxo
- discipleship_status: active, completed, archived
- answer_status: draft, submitted, in_review, needs_changes, approved

### 7.2 Rascunhos
- rascunhos não entram em revisão
- envio muda status para submitted e registra submitted_at

### 7.3 Revisão
- revisões sempre registradas com:
  - reviewer
  - decisão
  - notas
  - timestamp

Regras:
- somente discipulador do vínculo pode revisar, exceto:
  - admin_org e group_leader podem revisar se tiverem permissão na org e escopo correto (seção 10 e 15)

---

## 8. Encerramento do discipulado e multiplicação
### 8.1 Encerramento
Ao concluir:
- vínculo encerra
- respostas e conteúdo ficam leitura
- interação bloqueada
- discipulador recebe 1 seat de discípulo reemitido

### 8.2 Multiplicação
Ao concluir:
- criar automaticamente org `individual` para o discípulo formado
- preservar histórico do usuário na org anterior

### 8.3 Incentivo
- aplicar desconto configurável na nova org individual para primeira compra

---

## 9. Gamificação
- Global por usuário
- Filtrável por organização
- Sem ranking público
- Medalhas por marcos
- Níveis temáticos

Recomendação:
- regras determinísticas e auditáveis
- atualização por eventos (não recalcular tudo sempre)

---

## 10. Licenças, convites e governança (igreja)
### 10.1 Tipos de licença
- discipulador: assinatura ativa para operar
- discípulo: seats reutilizáveis para discipulados ativos

### 10.2 Pool da igreja
A org igreja mantém:
- discipulador_seats_total e used
- disciple_seats_total e used

Recomendação:
- alocação por usuário (discipulador) separada do pool:
  - org_license_allocations (por user_id e tipo)
- quotas de distribuição do group_leader:
  - org_group_leader_quotas (por leader e opcionalmente por grupo)

### 10.3 Convites (igreja)
Convites por e-mail podem atribuir:
- membership na org
- associação a grupos
- papel administrativo (group_leader), se permitido pelo admin
- concessão de licença (opcional), consumindo do pool

Permissões:
- admin_org: pode convidar qualquer pessoa para qualquer grupo e atribuir papéis
- group_leader: pode convidar apenas para grupos que lidera, limitado por quota

Requisitos:
- tokens de convite armazenados como hash
- convites com expiração
- revogação e reenvio

### 10.4 Distribuição de licenças (igreja)
- admin_org:
  - concede licenças para qualquer membro
  - compra mais licenças
  - define quotas de group_leader
- group_leader:
  - distribui licenças apenas para membros dos grupos que lidera
  - respeita quota configurada
- discipulador:
  - utiliza seus seats alocados para convidar e manter discipulados ativos

---

## 11. Pagamentos, webhooks e provisionamento
### 11.1 Webhooks e idempotência
- webhooks devem ser idempotentes por event_id do provedor
- registrar log de webhook (payload, status, erro)

### 11.2 Fluxos automáticos
Compra individual:
- confirmar pagamento
- criar org individual + membership + assinatura + seat inicial

Compra igreja:
- confirmar pagamento
- atualizar pool de licenças da org igreja

---

## 12. Administração do software (Admin Platform)
### 12.1 Funções do admin_platform
- CRUD de estudos, módulos, lições, blocos e questões
- CRUD do livro do professor
- publicação e versionamento:
  - draft, published, archived
  - histórico de alterações
- configurar gamificação
- configurar políticas globais (desconto do formado, templates de convite)
- suporte (buscar usuário/org, auditoria, logs)

### 12.2 Telas mínimas do admin_platform
- lista de estudos/módulos/lições
- editor de lição:
  - metadados
  - blocos (adicionar/reordenar)
  - imagens (storage)
  - vídeo como bloco (url/embed)
- editor de questões:
  - tipo
  - enunciado
  - opções
  - gabarito
- publicação
- histórico de alterações

---

## 13. Relatórios
- discipulador: progresso, pendências, histórico
- group_leader: visão dos grupos que lidera
- admin_org: visão global + dados administrativos (membros, licenças, grupos)

Recomendação:
- views SQL para relatórios agregados, evitando lógica pesada no front
- filtros por período, status e grupo

---

## 14. Telas e navegação (mapa de UI)
### 14.1 Telas comuns
- login/cadastro
- onboarding
- seletor de contexto (org + modo)
- perfil do usuário

### 14.2 Discípulo
- home
- discipulados (ativos e concluídos)
- lição (conteúdo por blocos liberados)
- questões (rascunho e envio)
- histórico (leitura)
- medalhas e níveis

### 14.3 Discipulador (e também admin_org e group_leader)
- home operacional
- meus discipulados
- acompanhamento do discípulo com timeline
- fila de revisão (review queue)
- livro do professor
- centro de convites
- relatórios (conforme escopo)

### 14.4 Igreja – Gestão (admin_org e group_leader)
Telas obrigatórias:
- membros (lista, convite, detalhe)
- grupos (criar, atribuir líderes, membros)
- controle de licenças (pool, alocação, quotas)
- auditoria básica (quem fez o que)
- branding e configurações

Telas recomendadas:
- importação/convite em massa (V1)
- painel de “distribuição” do líder de grupo (quota e status)

### 14.5 Admin Platform
- gestão de conteúdo
- publicação/versionamento
- gamificação
- descontos
- auditoria
- pagamentos e webhooks

---

## 15. Segurança e modelo de autorização (essencial para minimizar risco)
### 15.1 Regras de ouro
- deny by default: toda tabela com RLS habilitado e policies mínimas.
- nunca usar service role no frontend.
- toda operação sensível via RPC/Edge Function.
- conteúdo do professor nunca pode ter SELECT direto para usuários comuns.
- toda ação administrativa gera audit_event.

### 15.2 Escopos e checagens obrigatórias
Operações sensíveis devem checar:
- auth.uid presente
- membership na org
- papel necessário (admin_org ou group_leader ou discipulador)
- escopo de grupo quando aplicável (group_leader só em grupos que lidera)
- assinatura ativa quando operação depender de discipulador

### 15.3 Auditoria obrigatória
- concessão de licenças
- mudança de papéis
- mudança de grupo/membros
- liberações (lição/questões)
- revisões
- encerramento
- publicação de conteúdo

---

## 16. Arquitetura técnica recomendada (baixo custo e baixo risco)
- Frontend: Next.js (ou Nuxt, se preferir Vue), hospedado em Vercel/Netlify
- Backend: Supabase (Auth, Postgres, RLS)
- Server-side mínimo: Edge Functions para:
  - webhooks de pagamento
  - aceitar convites
  - ler conteúdo do professor por RPC
  - operações administrativas críticas (licenças/quota) se necessário
- Storage: Supabase Storage para imagens/arquivos
- Pagamentos: Stripe ou provedor nacional (definir depois)

### 16.1 Estrutura de pastas Next.js App Router

O projeto usa Next.js App Router. **Importante:** Route groups com parênteses `()` são usados apenas para organização e **NÃO adicionam segmentos à URL**.

Estrutura correta:
```
app/
├── (auth)/                    ← Route group para rotas públicas de auth
│   ├── login/page.tsx         → /login
│   ├── register/page.tsx      → /register
│   └── invite/[token]/page.tsx → /invite/:token
│
├── (authenticated)/           ← Route group para rotas autenticadas
│   ├── layout.tsx             ← Layout compartilhado (com OrganizationProvider)
│   └── app/                   ← Pasta REAL que cria o prefixo /app na URL
│       ├── page.tsx           → /app
│       ├── profile/page.tsx   → /app/profile
│       ├── disciple/          → /app/disciple/*
│       ├── mentor/            → /app/mentor/*
│       ├── church/            → /app/church/*
│       └── admin/             → /app/admin/*
│
├── auth/callback/route.ts     → /auth/callback (OAuth callback)
├── layout.tsx                 ← Layout raiz
└── page.tsx                   → / (landing page)
```

**Regra crítica:** Para que as rotas autenticadas tenham o prefixo `/app`, é necessário criar uma pasta `app/` **dentro** do route group `(authenticated)`. O route group apenas organiza os arquivos e aplica o layout, mas não adiciona segmentos à URL.

---

## 17. Modelo de dados (alto nível)
- users
- organizations
- organization_members
- user_preferences
- groups
- group_memberships (muitos-para-muitos)
- group_leaders (um usuário pode liderar vários grupos)
- org_branding_settings
- org_subscriptions
- org_license_pool
- org_license_allocations
- org_group_leader_quotas
- invites
- studies
- modules
- lessons
- lesson_blocks
- lesson_teacher_notes
- questions
- question_answer_keys
- discipleships
- lesson_releases
- question_releases
- answers
- reviews
- achievements
- user_achievements
- discounts
- audit_events
- webhook_logs
- notifications_outbox

---

## 18. Roadmap
### MVP
- fluxo completo de discipulado
- multi-org + troca de contexto
- convites
- licenças e governança (igreja: admin + líder de grupo + usuário normal)
- gestão de membros e grupos
- controle de licenças e quotas
- conteúdo com blocos (texto/imagem/vídeo)
- admin_platform funcional (conteúdo + publicação)
- relatórios básicos
- auditoria essencial

### V1
- notificações (outbox)
- importação de membros
- relatórios avançados
- alertas de estagnação
- área de encontros no app

---

## 19. Decisões futuras
- app mobile
- conteúdo multimídia avançado (offline, legendas, etc.)
- automações e integrações externas