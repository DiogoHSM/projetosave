'use client'

import React from 'react'
import { useOrganization } from '@/contexts/OrganizationContext'
import { useRouter } from 'next/navigation'
import { LoadingSpinner } from './LoadingSpinner'
import { Card, CardBody, CardHeader } from './Card'
import { ButtonPrimary } from './Button'

interface OrganizationGuardProps {
  children: React.ReactNode
  requireOrg?: boolean
}

/**
 * Guard para garantir que o usuário tenha uma organização ativa
 * Se requireOrg=true, mostra tela de seleção ou erro se necessário
 */
export function OrganizationGuard({ children, requireOrg = true }: OrganizationGuardProps) {
  const { activeOrg, organizations, isLoading, error, setActiveOrg } = useOrganization()
  const router = useRouter()

  // Se não requer org, apenas mostrar loading
  if (!requireOrg) {
    if (isLoading) {
      return (
        <div className="flex items-center justify-center min-h-screen">
          <LoadingSpinner />
        </div>
      )
    }
    return <>{children}</>
  }

  // Loading state
  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner />
      </div>
    )
  }

  // Error state
  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Card className="w-full max-w-md">
          <CardHeader>
            <h2 className="text-xl font-bold text-red-600">Erro</h2>
          </CardHeader>
          <CardBody>
            <p className="text-gray-700 mb-4">{error}</p>
            <ButtonPrimary onClick={() => router.push('/login')}>
              Fazer logout
            </ButtonPrimary>
          </CardBody>
        </Card>
      </div>
    )
  }

  // Sem organizações
  if (organizations.length === 0) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Card className="w-full max-w-md">
          <CardHeader>
            <h2 className="text-xl font-bold">Nenhuma organização encontrada</h2>
          </CardHeader>
          <CardBody>
            <p className="text-gray-700 mb-4">
              Você não está associado a nenhuma organização. Entre em contato com o suporte.
            </p>
            <ButtonPrimary onClick={() => router.push('/login')}>
              Fazer logout
            </ButtonPrimary>
          </CardBody>
        </Card>
      </div>
    )
  }

  // Múltiplas organizações mas nenhuma selecionada (não deveria acontecer, mas por segurança)
  if (organizations.length > 0 && !activeOrg) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Card className="w-full max-w-md">
          <CardHeader>
            <h2 className="text-xl font-bold">Selecione uma organização</h2>
          </CardHeader>
          <CardBody>
            <p className="text-gray-700 mb-4">
              Você pertence a {organizations.length} organização(ões). Selecione uma para continuar:
            </p>
            <div className="space-y-2">
              {organizations.map((org) => (
                <button
                  key={org.id}
                  onClick={async () => {
                    try {
                      await setActiveOrg(org.id)
                    } catch (err) {
                      console.error('Error selecting organization:', err)
                      alert('Erro ao selecionar organização. Tente novamente.')
                    }
                  }}
                  className="w-full text-left px-4 py-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  <div className="font-medium">{org.name}</div>
                  {org.type === 'individual' && (
                    <div className="text-sm text-gray-500">Individual</div>
                  )}
                </button>
              ))}
            </div>
          </CardBody>
        </Card>
      </div>
    )
  }

  // Tudo ok, renderizar children
  return <>{children}</>
}

