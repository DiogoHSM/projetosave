'use client'

import React, { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { ButtonPrimary } from '@/components/ui/Button'
import { TextInput } from '@/components/ui/Input'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import Image from 'next/image'

function LoginForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const supabase = createClient()
  
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  // Verificar se há mensagem de sucesso na URL
  React.useEffect(() => {
    if (searchParams.get('registered') === 'true') {
      if (searchParams.get('check_email') === 'true') {
        setSuccessMessage('Conta criada! Verifique seu email para confirmar (ou faça login se já confirmou).')
      } else {
        setSuccessMessage('Conta criada com sucesso! Faça login para continuar.')
      }
    }
  }, [searchParams])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      const { data, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (signInError) {
        // Traduzir mensagens de erro comuns
        let errorMessage = signInError.message
        if (signInError.message.includes('Invalid login credentials') || signInError.message.includes('Invalid credentials')) {
          errorMessage = 'Email ou senha incorretos. Verifique suas credenciais.'
        } else if (signInError.message.includes('Email not confirmed')) {
          errorMessage = 'Email não confirmado. Verifique sua caixa de entrada.'
        } else if (signInError.message.includes('User not found')) {
          errorMessage = 'Usuário não encontrado. Verifique o email ou cadastre-se.'
        } else {
          errorMessage = 'Erro ao fazer login. Tente novamente.'
        }
        setError(errorMessage)
        setIsLoading(false)
        return
      }

      if (data.user) {
        const redirect = searchParams.get('redirect') || '/app'
        router.push(redirect)
        router.refresh()
      }
    } catch (err) {
      setError('Erro ao fazer login. Tente novamente.')
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex justify-center mb-4">
            <Image
              src="/assets/logo/logo-horizontal.png"
              alt="Projeto SAVE"
              width={150}
              height={50}
              className="h-12 w-auto"
            />
          </div>
          <h1 className="text-2xl font-bold text-center">Entrar</h1>
        </CardHeader>
        <CardBody>
          <form onSubmit={handleSubmit} className="space-y-4">
            {successMessage && (
              <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
                {successMessage}
              </div>
            )}
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
              required
              disabled={isLoading}
            />

            <TextInput
              label="Senha"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={isLoading}
            />

            <ButtonPrimary
              type="submit"
              isLoading={isLoading}
              className="w-full"
            >
              Entrar
            </ButtonPrimary>
          </form>

          <div className="mt-4 text-center text-sm">
            <a
              href="/register"
              className="text-primary hover:underline"
            >
              Não tem uma conta? Cadastre-se
            </a>
          </div>
        </CardBody>
      </Card>
    </div>
  )
}

export default function LoginPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-gray-500">Carregando...</div>
      </div>
    }>
      <LoginForm />
    </Suspense>
  )
}

