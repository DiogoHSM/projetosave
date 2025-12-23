# Discipulado SaaS – Arquitetura do Sistema

## 1. Visão geral
### 1.1 Objetivo
Aplicativo SaaS de discipulado cristão cujo objetivo é permitir que um discipulador acompanhe um discípulo em estudos estruturados, progressivos e relacionais, promovendo crescimento espiritual e multiplicação do discipulado.

O sistema controla a liberação manual de conteúdos, acompanha respostas, registra histórico e incentiva que discípulos formados iniciem novos discipulados.

### 1.2 Princípios do produto
- Conteúdo doutrinário único e padronizado.
- Liberação sempre manual, conduzida pelo discipulador.
- Ênfase em relacionamento e formação, não competição.
- Multiplicação orgânica do discipulado.
- Simplicidade operacional para indivíduos e igrejas.

---

## 2. Modelo multi-tenant e tipos de acesso
O sistema é multi-tenant baseado em **organizações (orgs)**, que podem ser do tipo:

- `individual`
- `igreja`

Toda autenticação, autorização, licenciamento e relatórios são sempre contextualizados por organização.

---

## 3. Tipos de organização
### 3.1 Organização Individual
- Criada quando uma pessoa física compra uma licença de discipulador.
- Ao adquirir uma licença de discipulador:
  - o usuário ganha automaticamente 1 licença de discípulo
- O discipulador pode adquirir licenças adicionais de discípulo.
- Discípulos entram por convite e não pagam.
- Licenças de discípulo:
  - são fixas
  - ficam atreladas ao discipulador
  - são consumidas enquanto um discipulado está ativo
- Ao término de um discipulado:
  - o vínculo é encerrado
  - o discipulador recebe automaticamente uma nova licença de discípulo

### 3.2 Organização Igreja
- Criada e mantida por uma igreja.
- A igreja compra pacotes de licenças.
- As regras de discipulado são as mesmas do modelo individual.
- Possui perfis adicionais para gestão e relatórios.

---

## 4. Usuários e papéis
### 4.1 Papéis possíveis
- discipulador
- discipulo
- leader_celula
- leader_discipulado
- admin

### 4.2 Regras gerais
- Um usuário pode ter múltiplos papéis.
- Um usuário pode ser discipulador e discípulo simultaneamente.
- Um usuário pode pertencer a múltiplas organizações.
- Papéis sempre são atribuídos no contexto de uma organização.

---

## 5. Conteúdo e progressão
### 5.1 Conteúdo
- O conteúdo é único, global e controlado pela plataforma.
- Estrutura:
  - módulos
  - lições
  - questões
- Igrejas podem aplicar customizações visuais:
  - logotipo
  - cores
  - informações de contato
- O conteúdo textual não é customizável no MVP.

### 5.2 Tipos de questões
- Múltipla escolha
- Texto aberto
- Associação (coluna esquerda x coluna direita)

### 5.3 Visões de conteúdo (aluno x professor)
O conteúdo possui duas camadas:

**Camada do aluno**
- Texto base da lição
- Questões sem respostas
- Materiais comuns

**Camada do professor**
- Gabarito das questões
- Orientações pedagógicas
- Dicas e macetes de condução
- Roteiro sugerido do encontro

A camada do professor é acessível apenas a discipuladores e perfis autorizados.

### 5.4 Fluxo de estudo
1) discipulador libera a lição  
2) encontro ocorre (fora do app ou presencial)  
3) discipulador libera as questões  
4) discípulo responde (com opção de rascunho)  
5) discípulo envia respostas  
6) discipulador revisa  
7) discipulador libera a próxima lição  

Todo avanço é manual.

---

## 6. Respostas e revisão
### 6.1 Rascunhos
- Discípulo pode salvar respostas como rascunho.
- Rascunhos não entram em revisão.

### 6.2 Revisão
- Discipulador pode:
  - aprovar
  - solicitar ajustes
- Toda revisão fica registrada para histórico.

---

## 7. Encerramento do discipulado e multiplicação
### 7.1 Status do discipulado
- active
- completed
- archived

### 7.2 Encerramento
Ao concluir um discipulado:
- o vínculo discipulador–discípulo é encerrado
- conteúdo e respostas ficam apenas para leitura
- novas interações são bloqueadas
- o discipulador recebe uma nova licença de discípulo

### 7.3 Criação de nova organização (multiplicação)
- Ao concluir o discipulado, o sistema cria automaticamente uma nova organização do tipo `individual` para o discípulo formado.
- Essa nova org permite que ele inicie seus próprios discipulados.
- O histórico do usuário na organização anterior permanece preservado.

### 7.4 Benefícios para o novo discipulador
- Na criação da nova org individual:
  - é aplicado automaticamente um desconto configurável
  - o desconto é válido para a primeira compra de licenças de discípulo
- Regras de desconto são administráveis via painel.

---

## 8. Gamificação
### 8.1 Escopo
- Global por usuário
- Filtrável por organização
- Sem ranking público

### 8.2 Medalhas
Critérios possíveis:
- Lições concluídas
- Módulos concluídos
- Discipulados concluídos
- Quantidade de discípulos acompanhados

### 8.3 Níveis (exemplo conceitual)
- Caminhante
- Semeador
- Edificador
- Cooperador
- Enviador

---

## 9. Relatórios
### 9.1 Discipulador
- Progresso dos seus discípulos
- Histórico de discipulados concluídos

### 9.2 Líder de célula
- Progresso do seu grupo

### 9.3 Líder de discipulado
- Visão geral da organização

### 9.4 Administrador
- Usuários
- Licenças
- Descontos
- Grupos
- Assinaturas

---

## 10. Pagamentos e licenças
### 10.1 Licença de discipulador
- Assinatura mensal ou anual
- Obrigatória para manter acesso ativo
- Sem licença ativa:
  - acesso bloqueado
  - dados preservados em modo leitura

### 10.2 Licenças de discípulo
- Não expiram
- Atreladas ao discipulador
- Consumidas durante discipulados ativos
- Reemitidas automaticamente ao término

### 10.3 Integração de pagamentos
- Pagamento confirmado via webhook
- Assinatura ativada automaticamente
- Licenças provisionadas sem ação manual

---

## 11. Arquitetura técnica
### 11.1 Stack
- Frontend: Next.js
- Backend: Supabase
  - Auth
  - Postgres
  - Storage (se necessário)
  - Edge Functions
- Pagamentos:
  - Stripe ou provedor nacional
- Hosting:
  - Vercel
  - Supabase gerenciado

---

## 12. Modelo de dados (alto nível)
Principais entidades:
- users
- organizations
- organization_members
- groups
- studies
- modules
- lessons
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
- subscriptions
- licenses
- discounts
- invites
- audit_events

---

## 13. Segurança e RLS
- Todas as tabelas multi-tenant possuem org_id.
- RLS baseado em:
  - pertencimento à organização
  - papel do usuário
- Conteúdo do professor é acessível apenas a discipuladores e líderes autorizados.

---

## 14. Auditoria
Eventos auditáveis:
- convites
- liberações de lições e questões
- envios de respostas
- revisões
- encerramento de discipulados
- criação automática de organizações
- aplicação de descontos
- pagamentos e assinaturas

---

## 15. Roadmap técnico
### MVP
- Autenticação e organizações
- Conteúdo fixo
- Fluxo completo de discipulado
- Pagamentos e licenças
- Gamificação básica

### V1
- Notificações
- Exportação de relatórios
- Melhorias de UX
- Área de encontros no app

---

## 16. Decisões futuras
- Provedor de pagamento final
- App mobile
- Conteúdo multimídia
- Relatórios avançados