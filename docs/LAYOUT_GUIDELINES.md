# LAYOUT_GUIDELINES.md – Projeto SAVE

## 1. Objetivo
Definir a estrutura de layout do Projeto SAVE para garantir:
- consistência entre telas
- previsibilidade para o usuário
- facilidade de implementação por agentes de código
- boa experiência em desktop e mobile

Este documento define **estrutura e organização**, não cores nem estilo visual fino (ver DESIGN_SYSTEM.md).

---

## 2. Princípios de layout

### 2.1 Simplicidade
- telas devem ter foco claro
- evitar excesso de informações simultâneas
- uma ação principal por tela sempre que possível

### 2.2 Clareza de contexto
O usuário deve sempre saber:
- em qual organização está
- em qual modo está (discipulador ou discípulo)
- onde está no fluxo (menu ativo, etapa, progresso)

---

## 3. Estrutura base do app (autenticado)

### 3.1 Layout padrão (desktop)

O layout principal do app autenticado é composto por:

+———————————————————————————————+
| Header                        |
+––––––———–+————————————————————+
| Sidebar  | Main Content       |
|          |                    |
|          |                    |
+–––––––———+————————————————————+

---

### 3.2 Header (topo)

Conteúdo do header:
- logo padrão (`logo-horizontal.png`)
- nome da organização ativa
- indicador de modo ativo:
  - discipulador
  - discípulo
- menu de usuário (avatar / nome)

Regras:
- altura fixa
- sempre visível
- não deve conter menus complexos
- não usar para navegação principal

---

### 3.3 Sidebar (navegação principal)

Função:
- navegação principal do sistema

Características:
- fixa à esquerda no desktop
- colapsável
- itens de menu claros e curtos

Conteúdo típico:
- Dashboard
- Discipulados
- Estudos
- Grupos (se aplicável)
- Relatórios (se aplicável)
- Administração (se aplicável)

Regras:
- mostrar apenas itens permitidos pelo perfil
- destacar item ativo
- ícones simples e consistentes

---

### 3.4 Área de conteúdo principal

Função:
- exibir o conteúdo da tela atual

Características:
- scroll vertical
- largura confortável para leitura
- uso intensivo de cards

Regras:
- evitar textos longos em largura total
- separar seções claramente
- manter hierarquia visual

---

## 4. Layout por tipo de usuário

### 4.1 Usuário discípulo

Prioridades:
- clareza do próximo passo
- progresso visível
- poucas ações disponíveis

Layout típico:
- destaque para lição atual
- progresso do discipulado
- acesso às respostas enviadas
- histórico somente leitura após conclusão

---

### 4.2 Usuário discipulador

Prioridades:
- visão dos discípulos
- acompanhamento de progresso
- liberação de conteúdo

Layout típico:
- lista de discipulados ativos
- status de cada discípulo
- ações claras:
  - liberar lição
  - liberar perguntas
  - revisar respostas

---

### 4.3 Usuário igreja (admin ou líder de grupo)

Prioridades:
- visão agregada
- gestão de pessoas e licenças

Layout típico:
- dashboards com cards-resumo
- listas filtráveis
- acesso a relatórios

---

## 5. Layout de telas comuns

### 5.1 Dashboards

Características:
- cards de resumo no topo
- dados mais importantes primeiro
- sem excesso de gráficos no MVP

Regra:
- dashboards devem responder “o que precisa da minha atenção agora?”

---

### 5.2 Listagens (discipulados, grupos, membros)

Características:
- lista ou tabela simples
- filtros no topo
- ações por item (menu contextual)

Regras:
- evitar tabelas muito densas
- preferir cards em mobile

---

### 5.3 Detalhe (ex: discipulado específico)

Estrutura:
- cabeçalho com contexto (nome, status)
- abas ou seções:
  - visão geral
  - lições
  - respostas
  - histórico

Regra:
- não sobrecarregar uma única tela

---

### 5.4 Formulários

Características:
- campos agrupados logicamente
- labels claros
- validação visível

Regras:
- evitar formulários longos
- usar etapas quando necessário
- sempre indicar ação principal

---

## 6. Layout mobile

### 6.1 Estratégia
- mobile-first onde possível
- sidebar vira menu colapsado (hamburger)
- header permanece

### 6.2 Regras
- uma coluna
- botões grandes
- cards empilhados
- evitar tabelas largas

---

## 7. Estados de tela

Cada tela deve prever:
- loading
- vazio (sem dados)
- erro
- sucesso

Regras:
- estados vazios devem orientar o usuário
- mensagens humanas e claras
- evitar telas “mortas”

---

## 8. Troca de contexto (organização / modo)

O layout deve permitir:
- troca de organização (se o usuário tiver mais de uma)
- troca de modo:
  - discipulador
  - discípulo

Regras:
- troca visível
- não esconder o contexto atual
- confirmação quando necessário

---

## 9. O que NÃO fazer

- não misturar navegação no header e sidebar
- não esconder ações importantes
- não criar layouts diferentes sem justificativa
- não quebrar padrão entre telas semelhantes

---

## 10. Princípio final
O layout do Projeto SAVE deve:
- orientar
- acompanhar
- facilitar a caminhada

Nunca:
- confundir
- pressionar
- competir pela atenção