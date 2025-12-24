'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { ButtonPrimary, ButtonSecondary } from '@/components/ui/Button'
import { TextInput } from '@/components/ui/Input'

interface InviteFormProps {
  orgId: string
  onSuccess: () => void
  onCancel: () => void
}

interface InviteResult {
  invite_id: string
  token: string
  email: string
  role: string
  org_name: string
  expires_at: string
}

export function InviteForm({ orgId, onSuccess, onCancel }: InviteFormProps) {
  const supabase = createClient()
  const [email, setEmail] = useState('')
  const [role, setRole] = useState('member')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [inviteResult, setInviteResult] = useState<InviteResult | null>(null)
  const [copied, setCopied] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      const { data, error: rpcError } = await supabase.rpc('create_invite_with_token', {
        p_org_id: orgId,
        p_email: email,
        p_role_to_grant: role,
      })

      if (rpcError) {
        let errorMessage = rpcError.message
        if (rpcError.message.includes('duplicate_invite')) {
          errorMessage = 'Já existe um convite pendente para este email.'
        } else if (rpcError.message.includes('invalid email')) {
          errorMessage = 'Email inválido.'
        } else if (rpcError.message.includes('not_allowed')) {
          errorMessage = 'Você não tem permissão para criar convites.'
        }
        setError(errorMessage)
        setIsLoading(false)
        return
      }

      setInviteResult(data as InviteResult)
      setIsLoading(false)
    } catch (err) {
      setError('Erro ao criar convite. Tente novamente.')
      setIsLoading(false)
    }
  }

  const getInviteLink = () => {
    if (!inviteResult) return ''
    const baseUrl = typeof window !== 'undefined' ? window.location.origin : ''
    return `${baseUrl}/invite/${inviteResult.token}`
  }

  const handleCopy = async () => {
    const link = getInviteLink()
    try {
      await navigator.clipboard.writeText(link)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  // Se o convite foi criado, mostrar o link
  if (inviteResult) {
    return (
      <div className="space-y-4">
        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
          Convite criado com sucesso!
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Email convidado
          </label>
          <p className="text-gray-900">{inviteResult.email}</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Papel
          </label>
          <p className="text-gray-900">
            {inviteResult.role === 'member' && 'Membro'}
            {inviteResult.role === 'mentor' && 'Discipulador'}
            {inviteResult.role === 'admin_org' && 'Administrador'}
            {inviteResult.role === 'group_leader' && 'Líder de Grupo'}
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Link de convite
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              readOnly
              value={getInviteLink()}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg bg-gray-50 text-sm font-mono"
            />
            <ButtonSecondary onClick={handleCopy} type="button">
              {copied ? 'Copiado!' : 'Copiar'}
            </ButtonSecondary>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Este link expira em 7 dias.
          </p>
        </div>

        <div className="flex gap-3 pt-4">
          <ButtonPrimary onClick={onSuccess} className="flex-1">
            Concluir
          </ButtonPrimary>
        </div>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <TextInput
        label="Email"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="email@exemplo.com"
        required
        disabled={isLoading}
      />

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Papel
        </label>
        <select
          value={role}
          onChange={(e) => setRole(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
          disabled={isLoading}
        >
          <option value="member">Membro</option>
          <option value="mentor">Discipulador</option>
          <option value="group_leader">Líder de Grupo</option>
          <option value="admin_org">Administrador</option>
        </select>
        <p className="text-xs text-gray-500 mt-1">
          {role === 'member' && 'Pode participar de discipulados como discípulo.'}
          {role === 'mentor' && 'Pode criar e conduzir discipulados.'}
          {role === 'group_leader' && 'Pode gerenciar grupos e convidar membros.'}
          {role === 'admin_org' && 'Acesso total à administração da organização.'}
        </p>
      </div>

      <div className="flex gap-3 pt-4">
        <ButtonSecondary onClick={onCancel} type="button" className="flex-1" disabled={isLoading}>
          Cancelar
        </ButtonSecondary>
        <ButtonPrimary type="submit" isLoading={isLoading} className="flex-1">
          Criar Convite
        </ButtonPrimary>
      </div>
    </form>
  )
}

