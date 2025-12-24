# Próximos Passos - Projeto SAVE

## ✅ O que já está funcionando

1. **Setup básico**
   - ✅ Next.js 14+ com TypeScript
   - ✅ Tailwind CSS configurado
   - ✅ Supabase integrado (client/server)
   - ✅ Autenticação funcionando (login/register)
   - ✅ Rotas protegidas (`/app/*`)

2. **Database**
   - ✅ Schema completo criado
   - ✅ RLS helpers e policies implementadas
   - ✅ RPCs essenciais criadas

3. **UI Base**
   - ✅ Componentes base (Button, Card, Input, etc)
   - ✅ Layout principal (Header, Sidebar)
   - ✅ Página de perfil básica

## 🔧 Limpeza necessária

Execute a migration adicional:
- `005_create_individual_org_rpc.sql` - RPC para criar organização individual no cadastro

## 📋 Próximos passos recomendados

### 1. Executar migration adicional
Execute `005_create_individual_org_rpc.sql` no Supabase Dashboard para habilitar criação automática de organização no cadastro.

### 2. Implementar contexto de organização
- Criar hook/context para gerenciar `active_org_id`
- Atualizar Header para mostrar organização ativa
- Implementar seletor de organização no perfil

### 3. Implementar fluxo de discipulado
- Criar interface para criar discipulado
- Listar discipulados ativos
- Visualizar progresso do discípulo

### 4. Implementar gestão de conteúdo
- Interface para criar estudos/módulos/lições
- Editor de conteúdo
- Sistema de publicação

### 5. Implementar sistema de convites
- Interface para criar convites
- Página de aceitar convite (já existe, precisa melhorar)
- Gestão de membros

## 🎯 Prioridade sugerida

1. **Alta**: Contexto de organização (usuário precisa ver qual org está ativa)
2. **Alta**: Fluxo básico de discipulado (criar, visualizar)
3. **Média**: Sistema de convites completo
4. **Média**: Gestão de conteúdo básica
5. **Baixa**: Gamificação e conquistas

## 📝 Notas

- Todas as operações sensíveis devem usar RPCs (não SQL direto)
- RLS está ativo e protegendo todas as tabelas
- Seguir sempre `AGENT_RULES.md` e `SECURITY.md`

