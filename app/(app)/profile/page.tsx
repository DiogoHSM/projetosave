import { createClient } from '@/lib/supabase/server'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'

export default async function ProfilePage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return null
  }

  return (
    <div className="max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Perfil</h1>
      
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold">Informações Pessoais</h2>
        </CardHeader>
        <CardBody>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <p className="text-gray-900">{user.email}</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                ID do Usuário
              </label>
              <p className="text-sm text-gray-500 font-mono">{user.id}</p>
            </div>
          </div>
        </CardBody>
      </Card>
    </div>
  )
}

