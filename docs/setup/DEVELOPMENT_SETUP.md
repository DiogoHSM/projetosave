# Setup de Desenvolvimento

## Configurações do Supabase para Desenvolvimento

### 1. Desabilitar Confirmação de Email

Para desenvolvimento local, desabilite a confirmação de email:

1. Acesse: https://supabase.com/dashboard/project/cetmvxcjwvatcgdwzvar/auth/providers
2. Vá em **Authentication** → **Sign In / Providers** (ou diretamente em **Settings** → **Email Auth**)
3. Na seção **"User Signups"**, desmarque **"Confirm email"**
4. Clique em **"Save changes"**

Isso permite que usuários façam login imediatamente após criar conta, sem precisar confirmar email.

### 2. Configurar SMTP (Apenas para Produção)

Para produção, você precisará configurar SMTP:

1. Acesse: https://supabase.com/dashboard/project/cetmvxcjwvatcgdwzvar/auth/providers
2. Vá em **Settings** → **SMTP Settings**
3. Configure um provedor (SendGrid, AWS SES, etc.)
4. Habilite novamente **"Enable email confirmations"**

### 3. Variáveis de Ambiente

Certifique-se de que `.env.local` está configurado:

```env
NEXT_PUBLIC_SUPABASE_URL=https://cetmvxcjwvatcgdwzvar.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_7uqS78e9xxcdseHl9sct9A_2oo6QteG
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 4. Testar Cadastro

Após desabilitar confirmação de email:
1. Acesse http://localhost:3000/register
2. Crie uma conta
3. Você deve conseguir fazer login imediatamente

