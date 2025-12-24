# AGENT_RULES.md

## Objetivo
Regras para agentes (Cursor/antigravity) ao gerar código para o Projeto SAVE.

Este repositório é guiado por documentação. Se houver conflito entre código e documentação, a documentação vence até ser atualizada.

---

## Ordem de leitura obrigatória
1) ARCHITECTURE.md
2) SECURITY.md
3) DATA_MODEL.md
4) STATE_MACHINE.md
5) RLS_RULES.md
6) RLS_POLICY_MAP.md
7) API_CONTRACTS.md
8) DEPLOYMENT.md
9) TESTING_STRATEGY.md
10) DESIGN_SYSTEM.md
11) LAYOUT_GUIDELINES.md
12) NAVIGATION.md
13) COMPONENT_LIBRARY.md
14) PAGES_AND_ROUTES.md
15) UX_COPY.md
16) CHECKLISTS.md

Se algum arquivo listado não existir no repositório, o agent deve:
- parar a implementação do trecho afetado
- criar um TODO explícito
- propor a alteração mais segura por padrão

---

## Padrões de nomenclatura (obrigatório)
- Banco de dados (tabelas, colunas, funções SQL, RPC): inglês, snake_case
  - exemplos: mentor, disciple, org_id, has_active_mentor_subscription
- Interface (menus, textos, labels, rotas exibidas ao usuário): português
  - exemplos: Discipulador, Discípulo, Discipulado, Grupos, Conquistas

O agent não pode misturar português e inglês em nomes de colunas/tabelas.
A UI sempre usa português, mas internamente (código/DB) os identificadores permanecem em inglês.

---

## Regras inegociáveis de segurança
- Nunca criar atalho de segurança “temporário”.
- RLS é obrigatório em todas as tabelas com dados de usuário/organização.
- O frontend jamais usa service role.
- Conteúdo do professor (gabarito e orientações) só pode ser acessado via RPC/Edge Function conforme API_CONTRACTS.md.
- Toda operação sensível deve gerar audit_event conforme definido.

---

## Regras de implementação
- Preferir soluções simples e auditáveis.
- Evitar dependências desnecessárias.
- Criar migrations incrementais, versionadas e reprodutíveis.
- Qualquer mudança em RLS ou estados exige:
  - atualização do documento correspondente
  - testes conforme TESTING_STRATEGY.md

---

## Como proceder quando faltar informação
- Não inventar.
- Registrar TODO no código e na documentação (no arquivo correto).
- Propor 2 opções e implementar a mais segura por padrão.
- Se a decisão impactar segurança, bloquear a feature até decisão explícita.