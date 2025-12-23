# SECURITY.md

## Objetivo
Regras de segurança obrigatórias do Projeto SAVE. Este documento tem prioridade sobre conveniências de implementação.

## Princípios inegociáveis
- Deny by default.
- Todas as tabelas com RLS habilitado.
- Nunca usar service_role no frontend.
- Operações sensíveis somente via RPC/Edge Functions.
- Conteúdo do professor nunca pode ser acessado por SELECT direto.
- Logs de auditoria para ações administrativas e fluxo do discipulado.

## Ameaças e falhas que devem ser impossíveis
- Usuário de uma organização acessar dados de outra.
- Discípulo acessar livro do professor (gabarito/orientações).
- Líder de grupo atuar fora de grupos que lidera.
- Usuário executar operação administrativa sem permissão.
- Webhook duplicado provisionar licenças duas vezes (idempotência).

## Regras de tokens, convites e sessões
- Convites com token armazenado apenas como hash.
- Tokens com expiração e revogação.
- Rate limit em convites e endpoints sensíveis.

## Uso de Edge Functions
- Lista de Edge Functions permitidas.
- Regras de validação e assinatura de webhooks.

## Checklist de segurança antes de produção
- [ ] RLS habilitado em todas as tabelas
- [ ] Policies revisadas por tabela
- [ ] RPCs com security definer onde necessário e checagens explícitas
- [ ] Sem service_role em client
- [ ] Logs de webhook com idempotência
- [ ] Testes manuais de tentativa de acesso indevido

