# DESIGN_SYSTEM.md – Projeto SAVE

## 1. Objetivo
Definir o sistema visual oficial do Projeto SAVE para guiar:
- criação de layouts
- componentes de UI
- consistência visual entre telas
- decisões automáticas de agentes de código

Este documento define **regras**, não exemplos soltos.

---

## 2. Identidade Visual

### 2.1 Logos oficiais

O Projeto SAVE possui **três versões oficiais de logo**, todas já existentes em `assets/logo/`.

#### 2.1.1 Logo institucional (grande)
Arquivo:
- `assets/logo/logo-full.png`

Uso:
- landing page
- página inicial pública
- página de login
- materiais institucionais

Regras:
- usar em destaque
- não reduzir excessivamente
- manter proporção original
- não aplicar filtros, sombras ou gradientes adicionais

---

#### 2.1.2 Logo padrão (app)
Arquivo:
- `assets/logo/logo-horizontal.png`

Uso:
- header principal do app
- sidebar
- telas internas

Regras:
- altura controlada pelo layout (nunca esticar)
- manter proporção
- fundo transparente obrigatório
- não usar como favicon

---

#### 2.1.3 Logo quadrada (ícone)
Arquivo:
- `assets/logo/logo-square.png`

Uso:
- favicon
- PWA icon
- mobile app icon
- avatar automático do sistema

Regras:
- sempre proporção 1:1
- legível em tamanhos pequenos
- fundo transparente preferencial

---

## 3. Paleta de cores (semântica)

A identidade visual do Projeto SAVE se baseia nas quatro dimensões do discipulado.

### 3.1 Cores principais (conceituais)

- **Azul – Seguir**
  - significado: início, chamado, base, confiança
- **Laranja – Aprender**
  - significado: crescimento, conhecimento, atenção
- **Verde – Viver**
  - significado: prática, vida cristã, amadurecimento
- **Roxo – Ensinar**
  - significado: liderança, maturidade, multiplicação

Essas cores **não competem entre si**.

---

### 3.2 Cor primária do sistema
- O sistema deve escolher **uma cor primária dominante** para:
  - botões principais
  - links
  - ações primárias
- As demais cores entram como:
  - indicadores de progresso
  - badges
  - gamificação
  - estados contextuais

Regra:
- nunca usar as quatro cores saturadas juntas em um mesmo componente

---

### 3.3 Tons neutros
Usar tons neutros para:
- fundo
- texto
- bordas
- separadores

Diretrizes:
- fundo claro por padrão
- contraste adequado para leitura
- priorizar simplicidade

---

## 4. Tipografia

### 4.1 Estilo geral
- tipografia limpa
- moderna
- legível em textos longos
- sem aparência corporativa agressiva

Recomendações (não obrigatórias):
- fontes sem serifa
- boa leitura em mobile

---

### 4.2 Hierarquia
- Títulos claros
- Subtítulos visíveis
- Texto de leitura confortável
- Evitar excesso de pesos diferentes

---

## 5. Botões

### 5.1 Botão primário
Uso:
- ações principais
- avançar
- confirmar
- salvar

Características:
- fundo na cor primária do sistema
- texto branco
- cantos levemente arredondados
- tamanho confortável para toque

---

### 5.2 Botão secundário
Uso:
- ações alternativas
- cancelar
- voltar

Características:
- fundo neutro ou transparente
- borda sutil
- texto na cor primária

---

### 5.3 Botão de perigo
Uso:
- excluir
- revogar
- encerrar discipulado

Características:
- cor de alerta (vermelho)
- exigir confirmação adicional
- nunca usar como ação principal padrão

---

## 6. Componentes visuais

### 6.1 Cards
- principal unidade visual do sistema
- usados para:
  - lições
  - discipulados
  - grupos
  - relatórios

Características:
- fundo claro
- sombra sutil ou borda
- espaçamento interno generoso

---

### 6.2 Badges e status
Usados para:
- progresso
- estado de lições
- estado de discipulados
- níveis de gamificação

Características:
- cores semânticas
- texto curto
- não chamativo demais

---

### 6.3 Progresso
- barras
- passos
- checklists

Uso:
- mostrar avanço no discipulado
- módulos concluídos
- lições liberadas

Regra:
- progresso deve ser encorajador, não competitivo

---

## 7. Gamificação (visual)

A gamificação do Projeto SAVE é:
- pessoal
- progressiva
- não competitiva

Diretrizes visuais:
- usar ícones simples
- evitar rankings
- usar níveis com nomes amigáveis
- celebrar marcos com moderação

---

## 8. Acessibilidade e usabilidade

Diretrizes mínimas:
- contraste suficiente entre texto e fundo
- botões grandes o bastante para toque
- não depender apenas de cor para significado
- mensagens claras e humanas

---

## 9. O que NÃO fazer (regras importantes)

- não esticar logos
- não aplicar efeitos visuais arbitrários
- não usar fontes decorativas
- não sobrecarregar telas com muitas cores
- não usar linguagem visual agressiva ou corporativa

---

## 10. Princípio final
O visual do Projeto SAVE deve transmitir:
- clareza
- acolhimento
- propósito
- caminhada progressiva

Nunca:
- pressa
- competição
- frieza