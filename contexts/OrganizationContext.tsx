'use client'

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

interface Organization {
  id: string
  name: string
  type: 'individual' | 'church'
  contact_email: string | null
  slug: string | null
}

interface OrganizationMember {
  org_id: string
  user_id: string
  status: 'active' | 'inactive' | 'pending'
  role_admin_org: boolean
  role_group_leader: boolean
}

interface OrganizationContextType {
  activeOrg: Organization | null
  activeMembership: OrganizationMember | null
  organizations: Organization[]
  isLoading: boolean
  error: string | null
  setActiveOrg: (orgId: string) => Promise<void>
  refreshOrganizations: () => Promise<void>
}

const OrganizationContext = createContext<OrganizationContextType | undefined>(undefined)

const STORAGE_KEY = 'projetosave_active_org_id'

export function OrganizationProvider({ children }: { children: React.ReactNode }) {
  const [activeOrg, setActiveOrgState] = useState<Organization | null>(null)
  const [activeMembership, setActiveMembership] = useState<OrganizationMember | null>(null)
  const [organizations, setOrganizations] = useState<Organization[]>([])
  const [isLoading, setIsLoading] = useState(false) // Não bloquear renderização inicial
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()
  const supabase = createClient()

  // Buscar organizações do usuário
  const fetchOrganizations = useCallback(async () => {
    try {
      setIsLoading(true)
      setError(null)

      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        setOrganizations([])
        setActiveOrgState(null)
        setIsLoading(false)
        return
      }

      // Buscar memberships ativas
      const { data: memberships, error: membershipsError } = await supabase
        .from('organization_members')
        .select('org_id, user_id, status, role_admin_org, role_group_leader')
        .eq('user_id', user.id)
        .eq('status', 'active')

      if (membershipsError) {
        throw membershipsError
      }

      if (!memberships || memberships.length === 0) {
        setOrganizations([])
        setActiveOrgState(null)
        setActiveMembership(null)
        setIsLoading(false)
        return
      }

      // Buscar detalhes das organizações
      const orgIds = memberships.map(m => m.org_id)
      const { data: orgs, error: orgsError } = await supabase
        .from('organizations')
        .select('id, name, type, contact_email, slug')
        .in('id', orgIds)

      if (orgsError) {
        throw orgsError
      }

      setOrganizations(orgs || [])

      // Selecionar org ativa
      const storedOrgId = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null
      let orgToActivate: Organization | null = null

      if (storedOrgId && orgs?.some(o => o.id === storedOrgId)) {
        // Usar org armazenada se ainda for válida
        orgToActivate = orgs.find(o => o.id === storedOrgId) || null
      } else if (orgs && orgs.length === 1) {
        // Se tiver apenas uma, usar ela
        orgToActivate = orgs[0]
      } else if (orgs && orgs.length > 1) {
        // Se tiver múltiplas, usar a primeira (ou a individual se existir)
        orgToActivate = orgs.find(o => o.type === 'individual') || orgs[0]
      }

      if (orgToActivate) {
        setActiveOrgState(orgToActivate)
        // Buscar membership da org ativa
        const membership = memberships.find(m => m.org_id === orgToActivate!.id)
        if (membership) {
          setActiveMembership(membership as OrganizationMember)
        } else {
          setActiveMembership(null)
        }
        if (typeof window !== 'undefined') {
          localStorage.setItem(STORAGE_KEY, orgToActivate.id)
        }
      } else {
        setActiveOrgState(null)
        setActiveMembership(null)
        if (typeof window !== 'undefined') {
          localStorage.removeItem(STORAGE_KEY)
        }
      }

      setIsLoading(false)
    } catch (err) {
      console.error('Error fetching organizations:', err)
      setError(err instanceof Error ? err.message : 'Erro ao carregar organizações')
      setIsLoading(false)
    }
  }, [supabase])

  // Definir org ativa
  const setActiveOrg = useCallback(async (orgId: string) => {
    const org = organizations.find(o => o.id === orgId)
    if (!org) {
      throw new Error('Organização não encontrada')
    }

    // Validar que o usuário pertence à org
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      throw new Error('Usuário não autenticado')
    }

    const { data: membership, error } = await supabase
      .from('organization_members')
      .select('org_id, user_id, status, role_admin_org, role_group_leader')
      .eq('org_id', orgId)
      .eq('user_id', user.id)
      .eq('status', 'active')
      .single()

    if (error || !membership) {
      throw new Error('Você não tem acesso a esta organização')
    }

    setActiveOrgState(org)
    setActiveMembership(membership as OrganizationMember)
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, orgId)
    }

    // Registrar auditoria (opcional, pode ser feito via RPC depois)
    // Por enquanto, apenas atualizar estado
  }, [organizations, supabase])

  // Refresh organizações
  const refreshOrganizations = useCallback(async () => {
    await fetchOrganizations()
  }, [fetchOrganizations])

  // Carregar organizações ao montar (sem bloquear renderização)
  useEffect(() => {
    // Buscar em background sem bloquear
    fetchOrganizations().catch(console.error)
  }, [fetchOrganizations])

  // Limpar estado ao deslogar
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_OUT') {
        setOrganizations([])
        setActiveOrgState(null)
        setActiveMembership(null)
        if (typeof window !== 'undefined') {
          localStorage.removeItem(STORAGE_KEY)
        }
      } else if (event === 'SIGNED_IN') {
        fetchOrganizations()
      }
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [supabase, fetchOrganizations])

  return (
    <OrganizationContext.Provider
      value={{
        activeOrg,
        activeMembership,
        organizations,
        isLoading,
        error,
        setActiveOrg,
        refreshOrganizations,
      }}
    >
      {children}
    </OrganizationContext.Provider>
  )
}

export function useOrganization() {
  const context = useContext(OrganizationContext)
  if (context === undefined) {
    throw new Error('useOrganization must be used within an OrganizationProvider')
  }
  return context
}

