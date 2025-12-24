'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardBody } from '@/components/ui/Card'
import { ButtonSecondary } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/StatusBadge'

interface Member {
  user_id: string
  email: string
  full_name: string | null
  status: string
  role_admin_org: boolean
  role_group_leader: boolean
  joined_at: string
}

interface MemberListProps {
  orgId: string
}

export function MemberList({ orgId }: MemberListProps) {
  const supabase = createClient()
  const [members, setMembers] = useState<Member[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadMembers = async () => {
    try {
      setIsLoading(true)
      setError(null)

      const { data, error: rpcError } = await supabase.rpc('get_org_members', {
        p_org_id: orgId,
      })

      if (rpcError) {
        setError(rpcError.message)
        setIsLoading(false)
        return
      }

      setMembers(data || [])
      setIsLoading(false)
    } catch (err) {
      setError('Erro ao carregar membros.')
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadMembers()
  }, [orgId])

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    })
  }

  const getRoles = (member: Member) => {
    const roles: string[] = []
    if (member.role_admin_org) roles.push('Administrador')
    if (member.role_group_leader) roles.push('Líder de Grupo')
    if (roles.length === 0) roles.push('Membro')
    return roles
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-gray-500">Carregando membros...</div>
      </div>
    )
  }

  if (error) {
    return (
      <Card>
        <CardBody>
          <div className="text-center py-6">
            <p className="text-red-600">{error}</p>
            <ButtonSecondary onClick={loadMembers} className="mt-4">
              Tentar novamente
            </ButtonSecondary>
          </div>
        </CardBody>
      </Card>
    )
  }

  if (members.length === 0) {
    return (
      <Card>
        <CardBody>
          <div className="text-center py-6">
            <p className="text-gray-600">Nenhum membro encontrado.</p>
          </div>
        </CardBody>
      </Card>
    )
  }

  return (
    <div className="space-y-3">
      {members.map((member) => (
        <Card key={member.user_id}>
          <CardBody>
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-1">
                  <span className="font-medium text-gray-900">
                    {member.full_name || member.email}
                  </span>
                  <StatusBadge status={member.status === 'active' ? 'active' : 'inactive'}>
                    {member.status === 'active' ? 'Ativo' : 'Inativo'}
                  </StatusBadge>
                </div>
                <div className="flex items-center gap-4 text-sm text-gray-500">
                  <span>{member.email}</span>
                  <span>•</span>
                  <span>Entrou em {formatDate(member.joined_at)}</span>
                </div>
                <div className="flex gap-2 mt-2">
                  {getRoles(member).map((role) => (
                    <span
                      key={role}
                      className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-700"
                    >
                      {role}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </CardBody>
        </Card>
      ))}
    </div>
  )
}

