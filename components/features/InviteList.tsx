'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardBody } from '@/components/ui/Card'
import { ButtonSecondary, ButtonDanger } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/StatusBadge'

interface Invite {
  id: string
  email: string
  role_to_grant: string
  status: string
  created_at: string
  expires_at: string
  created_by_email: string
}

interface InviteListProps {
  orgId: string
  onRefresh?: () => void
}

export function InviteList({ orgId, onRefresh }: InviteListProps) {
  const supabase = createClient()
  const [invites, setInvites] = useState<Invite[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [revokingId, setRevokingId] = useState<string | null>(null)

  const loadInvites = async () => {
    try {
      setIsLoading(true)
      setError(null)

      const { data, error: rpcError } = await supabase.rpc('get_org_invites', {
        p_org_id: orgId,
      })

      if (rpcError) {
        setError(rpcError.message)
        setIsLoading(false)
        return
      }

      setInvites(data || [])
      setIsLoading(false)
    } catch (err) {
      setError('Erro ao carregar convites.')
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadInvites()
  }, [orgId])

  const handleRevoke = async (inviteId: string) => {
    if (!confirm('Tem certeza que deseja revogar este convite?')) return

    setRevokingId(inviteId)
    try {
      const { error: rpcError } = await supabase.rpc('revoke_invite', {
        p_invite_id: inviteId,
      })

      if (rpcError) {
        alert('Erro ao revogar convite: ' + rpcError.message)
        setRevokingId(null)
        return
      }

      await loadInvites()
      onRefresh?.()
    } catch (err) {
      alert('Erro ao revogar convite.')
    } finally {
      setRevokingId(null)
    }
  }

  const getRoleLabel = (role: string) => {
    switch (role) {
      case 'member': return 'Membro'
      case 'mentor': return 'Discipulador'
      case 'admin_org': return 'Administrador'
      case 'group_leader': return 'Líder de Grupo'
      default: return role
    }
  }

  const getStatusBadge = (status: string, expiresAt: string) => {
    const isExpired = new Date(expiresAt) < new Date()
    
    if (status === 'accepted') {
      return <StatusBadge status="active">Aceito</StatusBadge>
    }
    if (status === 'revoked') {
      return <StatusBadge status="inactive">Revogado</StatusBadge>
    }
    if (isExpired) {
      return <StatusBadge status="inactive">Expirado</StatusBadge>
    }
    return <StatusBadge status="pending">Pendente</StatusBadge>
  }

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    })
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-gray-500">Carregando convites...</div>
      </div>
    )
  }

  if (error) {
    return (
      <Card>
        <CardBody>
          <div className="text-center py-6">
            <p className="text-red-600">{error}</p>
            <ButtonSecondary onClick={loadInvites} className="mt-4">
              Tentar novamente
            </ButtonSecondary>
          </div>
        </CardBody>
      </Card>
    )
  }

  if (invites.length === 0) {
    return (
      <Card>
        <CardBody>
          <div className="text-center py-6">
            <p className="text-gray-600">Nenhum convite encontrado.</p>
            <p className="text-sm text-gray-500 mt-1">
              Clique em "Convidar Membro" para enviar um convite.
            </p>
          </div>
        </CardBody>
      </Card>
    )
  }

  return (
    <div className="space-y-3">
      {invites.map((invite) => (
        <Card key={invite.id}>
          <CardBody>
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-1">
                  <span className="font-medium text-gray-900">{invite.email}</span>
                  {getStatusBadge(invite.status, invite.expires_at)}
                </div>
                <div className="flex items-center gap-4 text-sm text-gray-500">
                  <span>Papel: {getRoleLabel(invite.role_to_grant)}</span>
                  <span>•</span>
                  <span>Criado em {formatDate(invite.created_at)}</span>
                  {invite.status === 'pending' && (
                    <>
                      <span>•</span>
                      <span>Expira em {formatDate(invite.expires_at)}</span>
                    </>
                  )}
                </div>
              </div>
              {invite.status === 'pending' && (
                <ButtonDanger
                  onClick={() => handleRevoke(invite.id)}
                  isLoading={revokingId === invite.id}
                  disabled={revokingId !== null}
                >
                  Revogar
                </ButtonDanger>
              )}
            </div>
          </CardBody>
        </Card>
      ))}
    </div>
  )
}

