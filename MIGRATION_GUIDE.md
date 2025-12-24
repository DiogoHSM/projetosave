# Guia de Migrations - Projeto SAVE

## Ordem de Execução

Execute as migrations **na ordem abaixo** no SQL Editor do Supabase Dashboard:

1. ✅ `001_initial_schema.sql` - Schema inicial (tabelas, índices, triggers)
2. ✅ `002_rls_helpers.sql` - Funções auxiliares para RLS
3. ✅ `003_rls_policies.sql` - Policies de Row Level Security
4. ✅ `004_rpcs.sql` - Funções RPC (create_invite, accept_invite, etc.)

## Passo a Passo

### 1. Acessar SQL Editor
- Vá para: https://supabase.com/dashboard/project/cetmvxcjwvatcgdwzvar/sql/new
- Ou: Dashboard → SQL Editor → New Query

### 2. Executar cada migration
- Copie o conteúdo completo de cada arquivo
- Cole no SQL Editor
- Clique em **Run** (ou pressione Cmd/Ctrl + Enter)
- Aguarde a confirmação de sucesso

### 3. Verificar execução
Após cada migration, verifique:
- ✅ Sem erros no console
- ✅ Tabelas criadas (Database → Tables)
- ✅ Funções criadas (Database → Functions)

## Importante

⚠️ **Execute na ordem exata** - as migrations dependem umas das outras:
- `002` depende de tabelas criadas em `001`
- `003` depende de funções criadas em `002`
- `004` depende de tabelas e funções das anteriores

## Verificação Final

Após executar todas as migrations, verifique se existem:

### Tabelas principais:
- ✅ `organizations`
- ✅ `user_profiles`
- ✅ `organization_members`
- ✅ `groups`
- ✅ `discipleships`
- ✅ `studies`, `modules`, `lessons`
- ✅ `answers`, `reviews`
- ✅ `audit_events`

### Funções RLS:
- ✅ `is_member()`
- ✅ `is_admin_org()`
- ✅ `has_active_mentor_subscription()`

### RPCs:
- ✅ `create_invite()`
- ✅ `accept_invite()`
- ✅ `create_discipleship()`

## Troubleshooting

Se encontrar erros:
1. Verifique se executou na ordem correta
2. Verifique se não há duplicatas (DROP IF EXISTS pode ajudar)
3. Consulte os logs de erro no SQL Editor

