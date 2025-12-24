'use client'

import { useEffect, useState, Suspense, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useOrganization } from '@/contexts/OrganizationContext'
import { OrganizationSelectionModal } from '@/components/ui/OrganizationSelectionModal'

function AppPageContent() {
  const router = useRouter()
  const supabase = createClient()
  const { organizations, activeOrg, setActiveOrg, isLoading, refreshOrganizations } = useOrganization()
  const [showModal, setShowModal] = useState(false)
  const [isCreatingOrg, setIsCreatingOrg] = useState(false)
  const hasTriedCreateOrg = useRef(false)

  useEffect(() => {
    // Aguardar carregamento das organizações
    if (isLoading) return

    // Se já está criando org, aguardar
    if (isCreatingOrg) return

    // Se não tem organizações, tentar criar org individual (apenas uma vez)
    if (organizations.length === 0 && !hasTriedCreateOrg.current) {
      hasTriedCreateOrg.current = true
      setIsCreatingOrg(true)
      
      const createOrg = async () => {
        try {
          const { data: { user } } = await supabase.auth.getUser()
          if (!user) {
            router.replace('/login')
            return
          }

          const { error: orgError } = await supabase.rpc('create_individual_org', {
            p_user_id: user.id,
            p_org_name: null,
          })

          if (orgError) {
            console.error('Error creating organization:', orgError)
            // Se falhar, ir para perfil mesmo assim
            router.replace('/app/profile')
            return
          }

          // Recarregar organizações após criar
          await refreshOrganizations()
        } catch (err) {
          console.error('Error in create_individual_org:', err)
          router.replace('/app/profile')
        } finally {
          setIsCreatingOrg(false)
        }
      }

      createOrg()
      return
    }

    // Se tem apenas uma organização, redirecionar direto
    // (o OrganizationContext já define automaticamente como ativa)
    if (organizations.length === 1) {
      router.replace('/app/profile')
      return
    }

    // Se tem múltiplas organizações e nenhuma está selecionada, mostrar modal
    if (organizations.length > 1 && !activeOrg) {
      setShowModal(true)
      return
    }

    // Se tem organização ativa, redirecionar para perfil
    if (activeOrg) {
      router.replace('/app/profile')
      return
    }
  }, [isLoading, organizations, activeOrg, isCreatingOrg, router, supabase, refreshOrganizations])

  const handleSelectOrg = async (orgId: string) => {
    try {
      await setActiveOrg(orgId)
      setShowModal(false)
      router.replace('/app/profile')
    } catch (error) {
      console.error('Error selecting organization:', error)
      alert('Erro ao selecionar organização. Tente novamente.')
    }
  }

  // Mostrar loading enquanto carrega ou cria org
  if (isLoading || isCreatingOrg) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-gray-500">Carregando...</div>
      </div>
    )
  }

  // Mostrar modal de seleção se necessário
  if (showModal) {
    return (
      <OrganizationSelectionModal
        isOpen={showModal}
        onClose={() => {
          setShowModal(false)
          // Se fechar sem selecionar, usar a primeira organização
          if (organizations.length > 0) {
            handleSelectOrg(organizations[0].id)
          }
        }}
        onSelect={handleSelectOrg}
      />
    )
  }

  // Estado de redirecionamento (breve, antes do router.replace)
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-gray-500">Redirecionando...</div>
    </div>
  )
}

export default function AppPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-gray-500">Carregando...</div>
      </div>
    }>
      <AppPageContent />
    </Suspense>
  )
}
