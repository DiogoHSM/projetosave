# COMPONENT_LIBRARY.md – Projeto SAVE

## 1. Objetivo
Definir a biblioteca oficial de componentes do Projeto SAVE para:
- garantir consistência visual e funcional
- evitar duplicação de componentes
- orientar agents na criação de UI
- facilitar manutenção e evolução do front-end

Este documento define **quais componentes existem**, **para que servem** e **como devem ser usados**.

---

## 2. Princípios gerais

- Preferir componentes simples e reutilizáveis
- Um componente = uma responsabilidade clara
- Componentes não devem conter regras de negócio
- Estados devem ser explícitos (loading, disabled, error)
- Nomes devem ser semânticos, não técnicos

---

## 3. Componentes de layout

### 3.1 AppLayout
Responsabilidade:
- estrutura base do app autenticado

Inclui:
- Header
- Sidebar
- MainContent

Regras:
- usado em todas as páginas autenticadas
- não contém lógica de permissão

---

### 3.2 Header
Responsabilidade:
- exibir contexto global

Inclui:
- logo padrão
- organização ativa
- modo ativo (discípulo / discipulador)
- menu do usuário

---

### 3.3 Sidebar
Responsabilidade:
- navegação principal

Inclui:
- itens definidos em NAVIGATION.md

Regras:
- renderizar apenas itens permitidos
- colapsável no desktop
- ocultável no mobile

---

### 3.4 PageContainer
Responsabilidade:
- delimitar conteúdo da página

Características:
- largura confortável
- padding consistente
- scroll vertical

---

## 4. Componentes de navegação

### 4.1 NavItem
Responsabilidade:
- item individual de menu

Estados:
- ativo
- inativo
- desabilitado

---

### 4.2 Breadcrumbs
Responsabilidade:
- indicar hierarquia e localização

Uso:
- telas profundas
- fluxos administrativos

---

### 4.3 ContextSwitcher
Responsabilidade:
- trocar organização ativa
- trocar modo (discípulo / discipulador)

Local:
- menu do usuário (Header)

---

## 5. Componentes de ação

### 5.1 ButtonPrimary
Uso:
- ação principal da tela

Estados:
- default
- hover
- loading
- disabled

---

### 5.2 ButtonSecondary
Uso:
- ação alternativa

---

### 5.3 ButtonDanger
Uso:
- ações destrutivas

Regras:
- sempre exigir confirmação

---

### 5.4 IconButton
Uso:
- ações compactas
- menus contextuais

---

## 6. Componentes de formulário

### 6.1 TextInput
Uso:
- textos curtos

Estados:
- normal
- erro
- disabled

---

### 6.2 TextArea
Uso:
- respostas abertas
- comentários
- feedback

---

### 6.3 SelectInput
Uso:
- seleção única

---

### 6.4 Checkbox
Uso:
- múltipla escolha
- flags

---

### 6.5 RadioGroup
Uso:
- verdadeiro/falso
- múltipla escolha exclusiva

---

### 6.6 FormSection
Responsabilidade:
- agrupar campos logicamente

---

### 6.7 FormActions
Responsabilidade:
- agrupar botões de ação do formulário

---

## 7. Componentes de conteúdo

### 7.1 Card
Responsabilidade:
- exibir conteúdo agrupado

Uso:
- listas
- resumos
- dashboards

---

### 7.2 CardHeader
Uso:
- título
- ações do card

---

### 7.3 CardBody
Uso:
- conteúdo principal

---

### 7.4 CardFooter
Uso:
- ações secundárias

---

### 7.5 EmptyState
Responsabilidade:
- orientar quando não há dados

Inclui:
- mensagem clara
- ação sugerida

---

## 8. Componentes de status e feedback

### 8.1 StatusBadge
Uso:
- status de discipulado
- status de lição
- status de resposta

---

### 8.2 ProgressBar
Uso:
- progresso do discipulado
- progresso de módulos

---

### 8.3 StepIndicator
Uso:
- fluxo de etapas
- avanço sequencial

---

### 8.4 LoadingSpinner
Uso:
- carregamento

---

### 8.5 Toast
Uso:
- feedback rápido

Tipos:
- sucesso
- erro
- aviso
- informativo

---

### 8.6 AlertBox
Uso:
- mensagens importantes
- avisos persistentes

---

## 9. Componentes de listas e dados

### 9.1 List
Responsabilidade:
- lista simples de itens

---

### 9.2 ListItem
Responsabilidade:
- item individual

---

### 9.3 DataTable
Uso:
- relatórios
- administração

Regras:
- evitar no mobile
- usar paginação

---

### 9.4 FilterBar
Uso:
- filtros de listagem

---

## 10. Componentes do fluxo de discipulado

### 10.1 DiscipleshipCard
Uso:
- resumo de discipulado

Inclui:
- nomes
- status
- progresso
- ação principal

---

### 10.2 LessonCard
Uso:
- exibição de lições

---

### 10.3 LessonBlockRenderer
Responsabilidade:
- renderizar blocos da lição
  - texto
  - imagem
  - vídeo

---

### 10.4 QuestionRenderer
Responsabilidade:
- renderizar perguntas conforme tipo:
  - texto aberto
  - múltipla escolha
  - associação
  - verdadeiro/falso

---

### 10.5 AnswerEditor
Responsabilidade:
- edição de respostas
- suporte a rascunho

---

### 10.6 ReviewPanel
Responsabilidade:
- revisão de respostas pelo discipulador

---

## 11. Componentes de gamificação

### 11.1 AchievementBadge
Uso:
- medalhas
- conquistas

---

### 11.2 LevelIndicator
Uso:
- nível atual do usuário

---

### 11.3 AchievementList
Uso:
- lista de conquistas

---

## 12. Componentes administrativos

### 12.1 MemberList
Uso:
- gestão de membros

---

### 12.2 GroupList
Uso:
- gestão de grupos

---

### 12.3 LicenseUsageCard
Uso:
- visão de licenças

---

### 12.4 InviteForm
Uso:
- envio de convites

---

## 13. O que NÃO fazer

- não criar novos componentes sem necessidade
- não duplicar componentes com pequenas variações
- não embutir regras de permissão no componente
- não misturar lógica de dados com UI

---

## 14. Princípio final
Todo componente do Projeto SAVE deve:
- servir à caminhada
- ser claro
- ser reutilizável

Nunca:
- confundir
- competir por atenção