'use client'

import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { ButtonPrimary } from '@/components/ui/Button'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'

export default function InvitePage() {
  const router = useRouter()
  const params = useParams()
  const supabase = createClient()
  const token = params.token as string

  const [isLoading, setIsLoading] = useState(true)
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  useEffect(() => {
    // Verificar se usuário está autenticado
    const checkAuth = async () => {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        // Redirecionar para login com token
        router.push(`/login?invite_token=${token}`)
      } else {
        setIsLoading(false)
      }
    }
    checkAuth()
  }, [router, token, supabase])

  const handleAcceptInvite = async () => {
    setIsProcessing(true)
    setError(null)

    try {
      const { data, error: rpcError } = await supabase.rpc('accept_invite', {
        p_token: token,
      })

      if (rpcError) {
        setError(rpcError.message || 'Erro ao aceitar convite')
        setIsProcessing(false)
        return
      }

      setSuccess(true)
      setTimeout(() => {
        router.push('/app')
      }, 2000)
    } catch (err) {
      setError('Erro ao processar convite. Tente novamente.')
      setIsProcessing(false)
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <h1 className="text-2xl font-bold text-center">Aceitar Convite</h1>
        </CardHeader>
        <CardBody>
          {success ? (
            <div className="text-center">
              <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded mb-4">
                Convite aceito com sucesso! Redirecionando...
              </div>
            </div>
          ) : (
            <>
              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
                  {error}
                </div>
              )}

              <p className="text-gray-600 mb-6 text-center">
                Você foi convidado para participar de uma organização no Projeto SAVE.
                Clique no botão abaixo para aceitar o convite.
              </p>

              <ButtonPrimary
                onClick={handleAcceptInvite}
                isLoading={isProcessing}
                className="w-full"
              >
                Aceitar Convite
              </ButtonPrimary>
            </>
          )}
        </CardBody>
      </Card>
    </div>
  )
}

