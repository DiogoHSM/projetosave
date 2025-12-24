'use client'

import React from 'react'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export function Header() {
  const router = useRouter()
  const supabase = createClient()

  const handleSignOut = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6">
      <div className="flex items-center gap-4">
        <Image
          src="/assets/logo/logo-horizontal.png"
          alt="Projeto SAVE"
          width={120}
          height={40}
          className="h-8 w-auto"
          priority
        />
        <div className="h-6 w-px bg-gray-300" />
        <div className="text-sm text-gray-600">
          {/* Contexto ativo será adicionado aqui */}
          <span className="font-medium">Organização</span>
        </div>
      </div>

      <div className="flex items-center gap-4">
        <button
          onClick={handleSignOut}
          className="text-sm text-gray-600 hover:text-gray-900"
        >
          Sair
        </button>
      </div>
    </header>
  )
}

