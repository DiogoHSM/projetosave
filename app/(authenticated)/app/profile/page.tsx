'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useOrganization } from '@/contexts/OrganizationContext'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { ButtonSecondary } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/StatusBadge'

export default function ProfilePage() {
  const router = useRouter()
  const supabase = createClient()
  const { activeOrg, activeMembership, organizations, setActiveOrg, isLoading } = useOrganization()
  const [user, setUser] = useState<any>(null)
  const [isChangingOrg, setIsChangingOrg] = useState(false)

  useEffect(() => {
    const loadUser = async () => {
      const { data: { user: currentUser } } = await supabase.auth.getUser()
      if (!currentUser) {
        router.push('/login')
        return
      }
      setUser(currentUser)
    }
    loadUser()
  }, [router, supabase])

  const handleOrgChange = async (orgId: string) => {
    if (orgId === activeOrg?.id) return
    
    setIsChangingOrg(true)
    try {
      await setActiveOrg(orgId)
      // Recarregar a página para atualizar contexto
      window.location.reload()
    } catch (error) {
      console.error('Error changing organization:', error)
      alert('Erro ao trocar organização. Tente novamente.')
    } finally {
      setIsChangingOrg(false)
    }
  }

  if (!user || isLoading) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-center py-12">
          <div className="text-gray-500">Carregando...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold">Perfil</h1>
      
      {/* Informações Pessoais */}
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold">Informações Pessoais</h2>
        </CardHeader>
        <CardBody>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Nome Completo
              </label>
              <p className="text-gray-900">{user.user_metadata?.full_name || 'Não informado'}</p>
            </div>
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

      {/* Organização Ativa */}
      {activeOrg && (
        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold">Organização Ativa</h2>
          </CardHeader>
          <CardBody>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Nome da Organização
                </label>
                <p className="text-gray-900">{activeOrg.name}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Tipo
                </label>
                <div className="flex items-center gap-2">
                  <StatusBadge 
                    status={activeOrg.type === 'individual' ? 'pending' : 'active'}
                  >
                    {activeOrg.type === 'individual' ? 'Individual' : 'Igreja'}
                  </StatusBadge>
                </div>
              </div>
              {activeMembership && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Papéis na Organização
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {activeMembership.role_admin_org && (
                      <StatusBadge status="pending">Administrador</StatusBadge>
                    )}
                    {activeMembership.role_group_leader && (
                      <StatusBadge status="pending">Líder de Grupo</StatusBadge>
                    )}
                    {!activeMembership.role_admin_org && !activeMembership.role_group_leader && (
                      <span className="text-sm text-gray-500">Membro</span>
                    )}
                  </div>
                </div>
              )}
              {activeOrg.contact_email && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Email de Contato
                  </label>
                  <p className="text-gray-900">{activeOrg.contact_email}</p>
                </div>
              )}
            </div>
          </CardBody>
        </Card>
      )}

      {/* Lista de Organizações */}
      {organizations.length > 1 && (
        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold">Trocar Organização</h2>
          </CardHeader>
          <CardBody>
            <div className="space-y-2">
              <p className="text-sm text-gray-600 mb-4">
                Você pertence a {organizations.length} organizações. Selecione qual deseja usar:
              </p>
              {organizations.map((org) => (
                <div
                  key={org.id}
                  className={`p-4 border rounded-lg transition-colors ${
                    org.id === activeOrg?.id
                      ? 'border-primary bg-primary/5'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-medium text-gray-900">{org.name}</span>
                        <StatusBadge
                          status={org.type === 'individual' ? 'pending' : 'active'}
                        >
                          {org.type === 'individual' ? 'Individual' : 'Igreja'}
                        </StatusBadge>
                      </div>
                      {org.id === activeOrg?.id && (
                        <p className="text-sm text-primary font-medium">Organização ativa</p>
                      )}
                    </div>
                    {org.id !== activeOrg?.id && (
                      <ButtonSecondary
                        onClick={() => handleOrgChange(org.id)}
                        disabled={isChangingOrg}
                        isLoading={isChangingOrg}
                        className="ml-4"
                      >
                        Selecionar
                      </ButtonSecondary>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </CardBody>
        </Card>
      )}

      {/* Administração (apenas para admins) */}
      {activeMembership?.role_admin_org && (
        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold">Administração</h2>
          </CardHeader>
          <CardBody>
            <div className="space-y-3">
              <a
                href="/app/church/members"
                className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:border-gray-300 hover:bg-gray-50 transition-colors"
              >
                <div>
                  <span className="font-medium text-gray-900">Membros e Convites</span>
                  <p className="text-sm text-gray-500 mt-0.5">
                    Gerencie os membros da organização e envie convites
                  </p>
                </div>
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </a>
            </div>
          </CardBody>
        </Card>
      )}

      {/* Sem Organização */}
      {!isLoading && organizations.length === 0 && (
        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold">Organização</h2>
          </CardHeader>
          <CardBody>
            <div className="text-center py-6">
              <p className="text-gray-600 mb-4">
                Você não pertence a nenhuma organização ainda.
              </p>
              <p className="text-sm text-gray-500">
                Entre em contato com um administrador ou aceite um convite para participar de uma organização.
              </p>
            </div>
          </CardBody>
        </Card>
      )}

      {/* Configurações */}
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold">Configurações</h2>
        </CardHeader>
        <CardBody>
          <a
            href="/app/settings"
            className="flex items-center justify-between p-4 border border-gray-200 rounded-lg hover:border-gray-300 hover:bg-gray-50 transition-colors"
          >
            <div>
              <span className="font-medium text-gray-900">Configurações da Conta</span>
              <p className="text-sm text-gray-500 mt-0.5">
                Criar nova organização, gerenciar conta
              </p>
            </div>
            <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </a>
        </CardBody>
      </Card>
    </div>
  )
}
