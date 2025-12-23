# AGENT_RULES.md

## Objetivo
Regras para agentes (Cursor/antigravity) ao gerar código para o Projeto SAVE.

## Ordem de leitura obrigatória
1) ARCHITECTURE.md
2) SECURITY.md
3) RLS_RULES.md
4) DATA_MODEL.md
5) API_CONTRACTS.md
6) PAGES_AND_ROUTES.md
7) UX_RULES.md

## Regras inegociáveis
- Nunca criar atalho de segurança "temporário".
- Nunca usar service_role no frontend.
- Toda tabela multi-tenant deve ter RLS habilitado.
- Deny by default: se a policy não existir, acesso deve falhar.
- Conteúdo do professor somente via RPC/Edge Functions.
- Toda operação sensível deve gerar audit_event.

## Estilo de implementação
- Preferir soluções simples e auditáveis.
- Evitar "mágica" e dependências desnecessárias.
- Criar migrations incrementais e reversíveis.
- Validar permissões com casos de teste descritos.

## Como proceder quando faltar informação
- Não inventar.
- Registrar TODO como comentário no código e como nota no PR.
- Propor 2 opções e implementar a mais segura por padrão.

## Definition of Done (por entrega)
- [ ] Compila/roda
- [ ] RLS aplicado
- [ ] Rotas protegidas
- [ ] Logs de auditoria gerados
- [ ] Sem secrets no client
- [ ] Teste manual de acesso indevido falha

