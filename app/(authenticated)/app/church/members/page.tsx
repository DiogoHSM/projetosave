'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useOrganization } from '@/contexts/OrganizationContext'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { ButtonPrimary, ButtonSecondary } from '@/components/ui/Button'
import { InviteForm } from '@/components/features/InviteForm'
import { InviteList } from '@/components/features/InviteList'
import { MemberList } from '@/components/features/MemberList'

export default function MembersPage() {
  const router = useRouter()
  const supabase = createClient()
  const { activeOrg, activeMembership, isLoading: orgLoading } = useOrganization()
  const [activeTab, setActiveTab] = useState<'members' | 'invites'>('members')
  const [showInviteForm, setShowInviteForm] = useState(false)
  const [refreshKey, setRefreshKey] = useState(0)

  // Verificar se o usuário é admin
  const isAdmin = activeMembership?.role_admin_org || false

  // Redirecionar se não for admin
  useEffect(() => {
    if (!orgLoading && !isAdmin) {
      router.push('/app/profile')
    }
  }, [isAdmin, orgLoading, router])

  const handleInviteCreated = () => {
    setShowInviteForm(false)
    setActiveTab('invites')
    setRefreshKey(prev => prev + 1) // Força refresh das listas
  }

  if (orgLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-gray-500">Carregando...</div>
      </div>
    )
  }

  if (!activeOrg) {
    return (
      <div className="max-w-4xl mx-auto">
        <Card>
          <CardBody>
            <p className="text-gray-600 text-center py-6">
              Selecione uma organização para gerenciar membros.
            </p>
          </CardBody>
        </Card>
      </div>
    )
  }

  if (!isAdmin) {
    return (
      <div className="max-w-4xl mx-auto">
        <Card>
          <CardBody>
            <p className="text-gray-600 text-center py-6">
              Você não tem permissão para acessar esta página.
            </p>
          </CardBody>
        </Card>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Membros</h1>
          <p className="text-gray-600 mt-1">
            Gerencie os membros e convites de {activeOrg.name}
          </p>
        </div>
        <ButtonPrimary onClick={() => setShowInviteForm(true)}>
          + Convidar Membro
        </ButtonPrimary>
      </div>

      {/* Modal de Convite */}
      {showInviteForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <Card className="w-full max-w-md">
            <CardHeader>
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold">Convidar Membro</h2>
                <button
                  onClick={() => setShowInviteForm(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </CardHeader>
            <CardBody>
              <InviteForm
                orgId={activeOrg.id}
                onSuccess={handleInviteCreated}
                onCancel={() => setShowInviteForm(false)}
              />
            </CardBody>
          </Card>
        </div>
      )}

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab('members')}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'members'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Membros
          </button>
          <button
            onClick={() => setActiveTab('invites')}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'invites'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Convites
          </button>
        </nav>
      </div>

      {/* Content */}
      {activeTab === 'members' ? (
        <MemberList orgId={activeOrg.id} key={`members-${refreshKey}`} />
      ) : (
        <InviteList orgId={activeOrg.id} key={`invites-${refreshKey}`} onRefresh={() => setRefreshKey(prev => prev + 1)} />
      )}
    </div>
  )
}

