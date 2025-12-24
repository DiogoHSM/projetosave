import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

export default async function AppPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Por enquanto, redireciona para perfil
  // Futuramente, redirecionará para último modo ativo ou modo padrão
  redirect('/app/profile')
}

