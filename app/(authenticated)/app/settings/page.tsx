'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useOrganization } from '@/contexts/OrganizationContext'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { ButtonPrimary, ButtonSecondary, ButtonDanger } from '@/components/ui/Button'
import { TextInput } from '@/components/ui/Input'

export default function SettingsPage() {
  const router = useRouter()
  const supabase = createClient()
  const { refreshOrganizations, isLoading: orgLoading } = useOrganization()
  
  const [showCreateOrg, setShowCreateOrg] = useState(false)
  const [orgName, setOrgName] = useState('')
  const [contactEmail, setContactEmail] = useState('')
  const [isCreating, setIsCreating] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  const handleCreateOrg = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setSuccess(null)
    setIsCreating(true)

    try {
      const { data, error: rpcError } = await supabase.rpc('create_church_org', {
        p_org_name: orgName,
        p_contact_email: contactEmail || null,
      })

      if (rpcError) {
        let errorMessage = rpcError.message
        if (rpcError.message.includes('invalid_input')) {
          errorMessage = 'Nome da organização deve ter pelo menos 3 caracteres.'
        }
        setError(errorMessage)
        setIsCreating(false)
        return
      }

      setSuccess(`Organização "${orgName}" criada com sucesso!`)
      setOrgName('')
      setContactEmail('')
      setShowCreateOrg(false)
      
      // Recarregar organizações
      await refreshOrganizations()
      
      // Redirecionar para o perfil após 2 segundos
      setTimeout(() => {
        router.push('/app/profile')
      }, 2000)
    } catch (err) {
      setError('Erro ao criar organização. Tente novamente.')
    } finally {
      setIsCreating(false)
    }
  }

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold">Configurações</h1>

      {/* Mensagens */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}
      {success && (
        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
          {success}
        </div>
      )}

      {/* Criar Nova Organização */}
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold">Organizações</h2>
        </CardHeader>
        <CardBody>
          {!showCreateOrg ? (
            <div className="space-y-4">
              <p className="text-gray-600">
                Crie uma nova organização do tipo Igreja para gerenciar membros, grupos e discipulados.
              </p>
              <ButtonPrimary onClick={() => setShowCreateOrg(true)}>
                + Criar Nova Organização (Igreja)
              </ButtonPrimary>
            </div>
          ) : (
            <form onSubmit={handleCreateOrg} className="space-y-4">
              <TextInput
                label="Nome da Organização"
                value={orgName}
                onChange={(e) => setOrgName(e.target.value)}
                placeholder="Ex: Igreja Batista Central"
                required
                disabled={isCreating}
              />

              <TextInput
                label="Email de Contato (opcional)"
                type="email"
                value={contactEmail}
                onChange={(e) => setContactEmail(e.target.value)}
                placeholder="contato@igreja.com"
                disabled={isCreating}
              />

              <div className="flex gap-3">
                <ButtonSecondary
                  type="button"
                  onClick={() => {
                    setShowCreateOrg(false)
                    setOrgName('')
                    setContactEmail('')
                    setError(null)
                  }}
                  disabled={isCreating}
                >
                  Cancelar
                </ButtonSecondary>
                <ButtonPrimary type="submit" isLoading={isCreating}>
                  Criar Organização
                </ButtonPrimary>
              </div>
            </form>
          )}
        </CardBody>
      </Card>

      {/* Conta */}
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold">Conta</h2>
        </CardHeader>
        <CardBody>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
              <div>
                <span className="font-medium text-gray-900">Sair da conta</span>
                <p className="text-sm text-gray-500 mt-0.5">
                  Encerrar sua sessão neste dispositivo
                </p>
              </div>
              <ButtonDanger onClick={handleLogout}>
                Sair
              </ButtonDanger>
            </div>
          </div>
        </CardBody>
      </Card>
    </div>
  )
}

