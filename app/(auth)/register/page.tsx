'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { ButtonPrimary } from '@/components/ui/Button'
import { TextInput } from '@/components/ui/Input'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import Image from 'next/image'

export default function RegisterPage() {
  const router = useRouter()
  const supabase = createClient()
  
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fullName, setFullName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      // Criar usuário
      const { data, error: signUpError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
          },
        },
      })

      // Se houver erro e não for relacionado a email, mostrar erro
      if (signUpError) {
        // Ignorar erros de envio de email se o usuário foi criado
        if (signUpError.message.includes('email') && data?.user) {
          // Usuário criado, mas email não enviado - continuar
        } else {
          // Traduzir mensagens de erro comuns
          let errorMessage = signUpError.message
          if (signUpError.message.includes('already registered') || signUpError.message.includes('already exists') || signUpError.message.includes('User already registered')) {
            errorMessage = 'Este email já está cadastrado. Faça login ou use outro email.'
          } else if (signUpError.message.includes('Password')) {
            errorMessage = 'A senha deve ter pelo menos 6 caracteres.'
          } else if (signUpError.message.includes('Invalid email')) {
            errorMessage = 'Email inválido. Verifique o endereço de email.'
          } else {
            errorMessage = 'Erro ao criar conta. Tente novamente.'
          }
          setError(errorMessage)
          setIsLoading(false)
          return
        }
      }

      if (data?.user) {
        // Criar perfil
        const { error: profileError } = await supabase
          .from('user_profiles')
          .insert({
            id: data.user.id,
            full_name: fullName,
          })

        if (profileError) {
          console.error('Error creating profile:', profileError)
          // Não falhar o cadastro se o perfil não for criado
          // O perfil pode ser criado depois
        }

        // Criar organização individual automaticamente
        const { data: orgData, error: orgError } = await supabase.rpc('create_individual_org', {
          p_user_id: data.user.id,
          p_org_name: fullName ? `${fullName}'s Organization` : null,
        })

        if (orgError) {
          console.error('Error creating organization:', orgError)
          // Não falhar o cadastro, mas logar o erro
          // A organização pode ser criada depois
        }

        // Redirecionar para página de confirmação ou login
        // Se email não foi confirmado, mostrar mensagem
        if (data.user.email_confirmed_at) {
          router.push('/app')
        } else {
          router.push('/login?registered=true&check_email=true')
        }
      } else {
        setError('Erro ao criar conta. Tente novamente.')
        setIsLoading(false)
      }
    } catch (err) {
      setError('Erro ao criar conta. Tente novamente.')
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
          <h1 className="text-2xl font-bold text-center">Criar Conta</h1>
        </CardHeader>
        <CardBody>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                {error}
              </div>
            )}

            <TextInput
              label="Nome completo"
              type="text"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              required
              disabled={isLoading}
            />

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
              minLength={6}
              disabled={isLoading}
            />

            <ButtonPrimary
              type="submit"
              isLoading={isLoading}
              className="w-full"
            >
              Criar Conta
            </ButtonPrimary>
          </form>

          <div className="mt-4 text-center text-sm">
            <a
              href="/login"
              className="text-primary hover:underline"
            >
              Já tem uma conta? Faça login
            </a>
          </div>
        </CardBody>
      </Card>
    </div>
  )
}

