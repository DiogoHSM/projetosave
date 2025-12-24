# NAVIGATION.md – Projeto SAVE

## 1. Objetivo
Definir a navegação oficial do Projeto SAVE, incluindo:
- estrutura de menus
- nomes padronizados
- hierarquia
- visibilidade por perfil de usuário

Este documento garante consistência e previsibilidade para usuários e agentes de código.

---

## 2. Princípios de navegação

### 2.1 Clareza
- nomes simples
- termos conhecidos do meio cristão/igreja
- evitar jargão técnico

### 2.2 Contexto
O menu deve refletir:
- organização ativa
- modo ativo (discípulo ou discipulador)
- permissões do usuário

---

## 3. Modos de navegação

O Projeto SAVE possui **dois modos funcionais principais** para o usuário:

- **Modo Discípulo**
- **Modo Discipulador**

Usuários de igreja (admin ou líder de grupo) têm **funcionalidades adicionais**, mas continuam usando um desses modos.

---

## 4. Menu – Modo Discípulo

### Itens principais
1. **Início**
   - resumo do discipulado atual
   - progresso
   - próximo passo

2. **Meu Discipulado**
   - lições liberadas
   - perguntas
   - respostas enviadas
   - histórico

3. **Progresso**
   - módulos concluídos
   - lições concluídas
   - conquistas pessoais

4. **Conquistas**
   - medalhas
   - níveis
   - histórico de marcos

5. **Perfil**
   - dados pessoais
   - preferências
   - histórico de discipulados (somente leitura)

Regras:
- menus curtos
- foco em acompanhamento pessoal
- nenhuma funcionalidade administrativa visível

---

## 5. Menu – Modo Discipulador (individual ou igreja)

### Itens principais
1. **Início**
   - visão geral
   - discipulados ativos
   - alertas (respostas pendentes, lições a liberar)

2. **Discipulados**
   - lista de discipulados ativos
   - status de cada discípulo
   - acesso ao detalhe

3. **Estudos**
   - currículo
   - módulos e lições
   - acesso ao conteúdo do professor (quando permitido)

4. **Conquistas**
   - progresso pessoal como discipulador
   - número de discipulados concluídos

5. **Perfil**
   - dados pessoais
   - preferências
   - plano/licença (quando individual)

---

## 6. Navegação adicional – Contexto Igreja

Disponível apenas para usuários em organizações do tipo **igreja**.

### 6.1 Menu: Administração (somente Admin da Igreja)

Itens:
1. **Visão Geral**
   - resumo da igreja
   - uso de licenças
   - métricas gerais

2. **Membros**
   - lista de membros
   - convites
   - permissões

3. **Grupos**
   - criação e edição de grupos
   - líderes de grupo
   - membros por grupo

4. **Licenças**
   - seats disponíveis
   - alocações
   - histórico

5. **Relatórios**
   - discipulados ativos
   - discipulados concluídos
   - progresso agregado

---

### 6.2 Menu: Gestão de Grupo (Líder de Grupo)

Itens:
1. **Meu Grupo**
   - membros do grupo
   - discipulados em andamento

2. **Convites**
   - convidar membros
   - conceder licenças dentro do limite

3. **Relatórios do Grupo**
   - progresso do grupo
   - visão agregada

Regras:
- líder de grupo só vê dados do seu grupo
- não pode acessar administração global da igreja

---

## 7. Troca de contexto

### 7.1 Troca de modo (Discípulo ↔ Discipulador)
Disponível quando o usuário:
- tem discipulados ativos como discípulo
- e possui licença ou permissão como discipulador

Local:
- menu do usuário (header)

Regras:
- troca explícita
- não automática
- manter estado da sessão

---

### 7.2 Troca de organização
Disponível quando o usuário pertence a mais de uma organização.

Local:
- menu do usuário (header)

Regras:
- mostrar nome da organização ativa
- confirmar troca
- recarregar contexto e permissões

---

## 8. Navegação pública (não autenticado)

Itens:
1. **Início**
2. **Sobre o Projeto**
3. **Como Funciona**
4. **Planos**
5. **Entrar**
6. **Criar Conta**

Regras:
- visual institucional
- foco explicativo
- sem acesso a dados internos

---

## 9. Nomes e termos padronizados

Usar sempre:
- “Discipulado”
- “Discipulador”
- “Discípulo”
- “Grupo”
- “Estudo”
- “Lição”
- “Conquistas”

Evitar:
- termos técnicos (ex: dashboard, pipeline, workflow)
- termos corporativos (ex: performance, KPI)

---

## 10. O que NÃO fazer

- não duplicar menus entre modos
- não mudar nomes entre telas
- não expor menus sem permissão
- não criar atalhos escondidos

---

## 11. Princípio final
A navegação do Projeto SAVE deve:
- orientar
- simplificar
- acompanhar a caminhada do usuário

Nunca:
- confundir
- sobrecarregar
- esconder o essencial