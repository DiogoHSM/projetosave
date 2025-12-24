# PAGES_AND_ROUTES.md – Projeto SAVE

## 1. Objetivo
Definir todas as páginas e rotas oficiais do Projeto SAVE, incluindo:
- rotas públicas e autenticadas
- páginas por modo (discípulo / discipulador)
- páginas administrativas (igreja e plataforma)
- responsabilidades de cada tela

Se uma página não estiver aqui, **ela não deve ser criada** sem atualização deste documento.

---

## 2. Convenções

### 2.1 Padrão de rotas
- Rotas públicas: `/`
- Rotas autenticadas: `/app`
- Subcontextos:
  - `/app/disciple`
  - `/app/mentor`
  - `/app/church`
  - `/app/admin` (plataforma)

### 2.2 Controle de acesso
- Toda rota autenticada exige usuário logado
- Permissões são verificadas:
  - no backend (RLS/RPC)
  - no frontend (guardas de rota)

### 2.3 Estrutura de pastas Next.js

O projeto usa Next.js App Router com route groups. **Atenção:** route groups `(nome)` são apenas para organização e NÃO adicionam segmentos à URL.

Estrutura de pastas:
```
app/
├── (auth)/                    ← Rotas públicas de autenticação
│   ├── login/page.tsx         → /login
│   └── register/page.tsx      → /register
│
├── (authenticated)/           ← Rotas que requerem autenticação
│   ├── layout.tsx             ← Layout com OrganizationProvider
│   └── app/                   ← Prefixo /app na URL
│       ├── page.tsx           → /app
│       ├── profile/           → /app/profile
│       ├── disciple/          → /app/disciple/*
│       ├── mentor/            → /app/mentor/*
│       ├── church/            → /app/church/*
│       └── admin/             → /app/admin/*
```

**Importante:** Para rotas `/app/*`, a pasta `app/` dentro de `(authenticated)` é obrigatória.

---

## 3. Rotas públicas (não autenticadas)

### `/`
**Página:** Landing Page  
Responsabilidade:
- apresentar o Projeto SAVE
- explicar o método SAVE
- CTA para cadastro ou login

Componentes:
- logo-full
- seções institucionais
- botões de ação

---

### `/login`
**Página:** Login  
Responsabilidade:
- autenticação do usuário

---

### `/register`
**Página:** Cadastro  
Responsabilidade:
- criação de conta
- redirecionamento pós-cadastro

Notas:
- cadastro individual pode ser disparado após compra

---

### `/pricing`
**Página:** Planos  
Responsabilidade:
- explicar planos individual e igreja

---

### `/invite/:token`
**Página:** Aceitar Convite  
Responsabilidade:
- aceitar convite por token
- associar usuário à organização

Fluxo:
- valida token
- executa RPC `accept_invite`
- redireciona para `/app`

---

## 4. Rotas base autenticadas

### `/app`
**Página:** App Home  
Responsabilidade:
- redirecionar para:
  - último modo ativo
  - ou modo padrão disponível

---

### `/app/profile`
**Página:** Perfil  
Responsabilidade:
- dados do usuário
- preferências
- troca de contexto

---

## 5. Modo Discípulo

Prefixo: `/app/disciple`

### `/app/disciple`
**Página:** Dashboard do Discípulo  
Responsabilidade:
- visão geral do discipulado ativo
- próximo passo

---

### `/app/disciple/discipleship/:id`
**Página:** Meu Discipulado  
Responsabilidade:
- visão geral
- lições liberadas
- progresso

---

### `/app/disciple/discipleship/:id/lesson/:lessonId`
**Página:** Lição  
Responsabilidade:
- renderizar conteúdo da lição
- exibir blocos (texto, vídeo, imagem)

Componentes:
- LessonBlockRenderer

---

### `/app/disciple/discipleship/:id/questions/:lessonId`
**Página:** Perguntas da Lição  
Responsabilidade:
- responder perguntas
- salvar rascunho
- enviar respostas

Componentes:
- QuestionRenderer
- AnswerEditor

---

### `/app/disciple/progress`
**Página:** Progresso  
Responsabilidade:
- histórico de módulos e lições
- conquistas pessoais

---

### `/app/disciple/achievements`
**Página:** Conquistas  
Responsabilidade:
- medalhas
- níveis

---

## 6. Modo Discipulador

Prefixo: `/app/mentor`

### `/app/mentor`
**Página:** Dashboard do Discipulador  
Responsabilidade:
- discipulados ativos
- alertas de revisão
- próximos passos

---

### `/app/mentor/discipleships`
**Página:** Meus Discipulados  
Responsabilidade:
- listar discipulados
- status
- acesso ao detalhe

---

### `/app/mentor/discipleships/:id`
**Página:** Detalhe do Discipulado  
Responsabilidade:
- progresso do discípulo
- lições liberadas
- ações:
  - liberar lição
  - liberar perguntas
  - encerrar discipulado

---

### `/app/mentor/discipleships/:id/review/:lessonId`
**Página:** Revisão de Respostas  
Responsabilidade:
- revisar respostas
- acessar gabarito (via RPC)
- feedback

Componentes:
- ReviewPanel

---

### `/app/mentor/studies`
**Página:** Estudos  
Responsabilidade:
- visualizar currículo
- acessar lições
- acessar conteúdo do professor (se permitido)

---

### `/app/mentor/achievements`
**Página:** Conquistas do Discipulador  
Responsabilidade:
- progresso como discipulador

---

## 7. Contexto Igreja

Prefixo: `/app/church`

### `/app/church`
**Página:** Visão Geral da Igreja  
Responsabilidade:
- métricas resumidas
- uso de licenças

---

### `/app/church/members`
**Página:** Membros  
Responsabilidade:
- listar membros
- enviar convites
- gerenciar permissões

Componentes:
- MemberList
- InviteForm

---

### `/app/church/groups`
**Página:** Grupos  
Responsabilidade:
- criar e editar grupos
- líderes e membros

---

### `/app/church/licenses`
**Página:** Licenças  
Responsabilidade:
- visualizar pool
- alocar seats
- histórico

---

### `/app/church/reports`
**Página:** Relatórios  
Responsabilidade:
- progresso agregado
- discipulados ativos/concluídos

---

### `/app/church/group`
**Página:** Meu Grupo (Líder de Grupo)  
Responsabilidade:
- visão do grupo
- discipulados do grupo
- convites dentro do limite

---

## 8. Administração da Plataforma

Prefixo: `/app/admin`

### `/app/admin`
**Página:** Admin Platform Dashboard  
Responsabilidade:
- visão global do sistema

---

### `/app/admin/content`
**Página:** Gerenciamento de Conteúdo  
Responsabilidade:
- criar e editar:
  - estudos
  - módulos
  - lições
  - blocos
  - perguntas
  - gabaritos
  - notas do professor

---

### `/app/admin/organizations`
**Página:** Organizações  
Responsabilidade:
- listar igrejas e contas individuais

---

### `/app/admin/audit`
**Página:** Auditoria  
Responsabilidade:
- visualizar audit_events
- rastrear ações críticas

---

## 9. Estados globais de erro

Rotas especiais:
- `/403` acesso negado
- `/404` página não encontrada
- `/500` erro inesperado

---

## 10. Regras finais

- Não criar rotas fora deste documento
- Não misturar modos em uma mesma rota
- Sempre respeitar prefixos
- Usar guards de rota no frontend
- Backend sempre valida novamente

---

## 11. Princípio final
Cada rota do Projeto SAVE deve:
- ter propósito claro
- servir a caminhada do usuário
- respeitar contexto e permissão

Nunca:
- confundir
- sobrepor responsabilidades