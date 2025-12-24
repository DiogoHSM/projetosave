'use client'

import React, { useState } from 'react'
import { useOrganization } from '@/contexts/OrganizationContext'
import { createClient } from '@/lib/supabase/client'

export function OrganizationSelector() {
  const { activeOrg, organizations, setActiveOrg, isLoading } = useOrganization()
  const [isOpen, setIsOpen] = useState(false)
  const [isChanging, setIsChanging] = useState(false)

  // Durante carregamento inicial, mostrar placeholder discreto
  if (isLoading && organizations.length === 0) {
    return (
      <div className="text-sm text-gray-400">
        <span className="font-medium">Carregando...</span>
      </div>
    )
  }

  if (organizations.length === 0 && !isLoading) {
    return (
      <div className="text-sm text-gray-500">
        <span className="font-medium">Sem organização</span>
      </div>
    )
  }

  if (organizations.length === 1) {
    return (
      <div className="text-sm text-gray-600">
        <span className="font-medium">{activeOrg?.name || 'Organização'}</span>
      </div>
    )
  }

  const handleSelect = async (orgId: string) => {
    if (orgId === activeOrg?.id) {
      setIsOpen(false)
      return
    }

    setIsChanging(true)
    try {
      await setActiveOrg(orgId)
      setIsOpen(false)
    } catch (error) {
      console.error('Error changing organization:', error)
      alert('Erro ao trocar organização. Tente novamente.')
    } finally {
      setIsChanging(false)
    }
  }

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        disabled={isChanging}
        className="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 disabled:opacity-50"
      >
        <span className="font-medium">{activeOrg?.name || 'Selecionar organização'}</span>
        <svg
          className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <>
          {/* Overlay para fechar ao clicar fora */}
          <div
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />
          
          {/* Dropdown */}
          <div className="absolute top-full left-0 mt-2 w-64 bg-white border border-gray-200 rounded-lg shadow-lg z-20">
            <div className="p-2">
              <div className="text-xs font-semibold text-gray-500 uppercase px-2 py-1 mb-1">
                Organizações
              </div>
              {organizations.map((org) => (
                <button
                  key={org.id}
                  onClick={() => handleSelect(org.id)}
                  className={`w-full text-left px-3 py-2 rounded text-sm transition-colors ${
                    org.id === activeOrg?.id
                      ? 'bg-primary/10 text-primary font-medium'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span>{org.name}</span>
                    {org.id === activeOrg?.id && (
                      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path
                          fillRule="evenodd"
                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                          clipRule="evenodd"
                        />
                      </svg>
                    )}
                  </div>
                  {org.type === 'individual' && (
                    <div className="text-xs text-gray-500 mt-0.5">Individual</div>
                  )}
                </button>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  )
}

