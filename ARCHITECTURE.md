# Discipulado SaaS - Arquitetura do Sistema

## 1. Visão geral
### 1.1 Objetivo
Aplicativo SaaS de discipulado cristão com foco em acompanhamento estruturado, progressivo e relacional.
O sistema permite que um discipulador libere conteúdos gradualmente, acompanhe respostas e forme novos discipuladores ao final do processo.

### 1.2 Princípios do produto
- Conteúdo único e padronizado (doutrinário/pedagógico).
- Liberação sempre manual, conduzida pelo discipulador.
- Ênfase em relacionamento, não competição.
- Multiplicação orgânica do discipulado.
- Simplicidade operacional para igrejas e indivíduos.

---

## 2. Tipos de acesso e modelo multi-tenant
O sistema é multi-tenant baseado em **organizações**, que podem ser do tipo:

- `individual`
- `igreja`

Toda lógica de acesso, licença e relatórios parte da organização.

### 2.1 Individual
- Pessoa física compra:
  - 1 licença de discipulador (obrigatória)
  - N licenças de discípulo (iniciais ou adicionais)
- Ao comprar 1 licença de discipulador:
  - ganha automaticamente 1 licença de discípulo
- O discipulador convida discípulos por link/email.
- Discípulos não pagam.
- Licenças de discípulo são **fixas e atreladas ao discipulador**.
- Ao concluir um discipulado:
  - o vínculo é encerrado
  - respostas ficam disponíveis apenas para leitura
  - o discipulador recebe **uma nova licença de discípulo**
  - o discípulo “formado” é promovido automaticamente a **perfil de discipulador**
  - esse novo discipulador recebe um **desconto configurável** para adquirir sua primeira licença de discípulo

### 2.2 Igreja
- Igreja compra pacotes de licenças.
- Funciona como o modelo individual, com perfis adicionais:
  - Administrador
  - Líder de discipulado
  - Líder de célula
- Licenças são gerenciadas pela igreja.
- Usuários podem pertencer a múltiplas organizações simultaneamente.

---

## 3. Perfis e papéis
Um usuário pode acumular múltiplos papéis.

### 3.1 Papéis possíveis
- discipulador
- discipulo
- leader_celula
- leader_discipulado
- admin

### 3.2 Regras importantes
- Um usuário pode ser discipulador e discípulo ao mesmo tempo.
- Um usuário pode estar em múltiplas igrejas.
- Papéis são sempre atribuídos no contexto de uma organização.

---

## 4. Conteúdo e progressão
### 4.1 Conteúdo
- Conteúdo é único e global:
  - módulos
  - lições
  - questões
- Igrejas podem aplicar:
  - logotipo
  - cores
  - informações de contato
- Não há customização de conteúdo textual no MVP.

### 4.2 Tipos de questões
- Múltipla escolha
- Texto aberto
- Associação (coluna esquerda x coluna direita)

### 4.3 Fluxo de estudo
1) discipulador libera lição  
2) encontro (presencial ou externo ao app)  
3) discipulador libera questões  
4) discípulo responde (com opção de rascunho)  
5) discípulo envia respostas  
6) discipulador revisa  
7) discipulador libera próxima lição  

Todo avanço é **manual**.

---

## 5. Respostas e revisão
### 5.1 Rascunho
- Discípulo pode salvar respostas como rascunho.
- Apenas respostas enviadas entram em revisão.

### 5.2 Revisão
- Discipulador pode:
  - aprovar
  - solicitar ajustes
- Revisões ficam registradas para histórico.

---

## 6. Encerramento do discipulado
- Discipulado possui status:
  - active
  - completed
  - archived
- Ao concluir:
  - vínculo é encerrado
  - conteúdo fica apenas para leitura
  - interação é bloqueada
  - discípulo é promovido a discipulador
  - benefício/desconto é aplicado conforme regra administrativa

---

## 7. Gamificação
### 7.1 Escopo
- Global por usuário
- Filtrável por igreja
- Sem ranking público

### 7.2 Medalhas
Exemplos de critérios:
- Lições concluídas
- Módulos concluídos
- Discipulados concluídos
- Quantidade de discípulos acompanhados

### 7.3 Níveis (exemplo conceitual)
- Caminhante
- Semeador
- Edificador
- Cooperador
- Enviador

Níveis são progressivos e não competitivos.

---

## 8. Relatórios
### 8.1 Discipulador
- Progresso de seus discípulos
- Histórico de discipulados concluídos

### 8.2 Líder de célula
- Progresso dos membros do seu grupo

### 8.3 Líder de discipulado
- Visão geral da organização

### 8.4 Administrador
- Usuários
- Licenças
- Descontos
- Grupos
- Status das assinaturas

---

## 9. Pagamentos e licenças
### 9.1 Licença de discipulador
- Assinatura mensal ou anual
- Necessária para manter acesso ativo
- Sem licença ativa:
  - acesso bloqueado
  - dados preservados em modo leitura

### 9.2 Licenças de discípulo
- Não expiram
- Atreladas ao discipulador
- Consumidas durante um discipulado ativo
- Reemitidas automaticamente ao término

### 9.3 Descontos
- Descontos configuráveis no painel admin
- Aplicados automaticamente a discípulos promovidos a discipuladores

---

## 10. Arquitetura técnica
### 10.1 Stack
- Frontend: Next.js
- Backend: Supabase
  - Auth
  - Postgres
  - Storage (se necessário)
  - Edge Functions
- Pagamentos:
  - Stripe ou provedor nacional (a definir)
- Hosting:
  - Vercel
  - Supabase gerenciado

---

## 11. Modelo de dados (alto nível)
### Principais entidades
- users
- organizations
- organization_members
- groups
- studies
- modules
- lessons
- questions
- discipleships
- lesson_releases
- question_releases
- answers
- reviews
- achievements
- user_achievements
- subscriptions
- licenses
- discounts
- invites
- audit_events

---

## 12. Segurança e RLS
- Todas as tabelas multi-tenant possuem org_id
- RLS baseado em:
  - pertencimento à organização
  - papel do usuário
- Leaders têm acesso apenas aos seus escopos

---

## 13. Auditoria
Eventos auditáveis:
- convites
- liberações
- envios
- revisões
- conclusões
- promoções
- pagamentos
- aplicação de descontos

---

## 14. Roadmap técnico
### MVP
- Autenticação
- Organizações
- Conteúdo fixo
- Fluxo de discipulado
- Pagamentos
- Gamificação básica

### V1
- Notificações
- Melhor UX
- Exportação de relatórios
- Área de encontros

---

## 15. Decisões futuras
- Provedor de pagamento
- Mobile app
- Conteúdo multimídia
- Encontros dentro do app