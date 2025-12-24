'use client'

import React, { useState } from 'react'
import { useOrganization } from '@/contexts/OrganizationContext'
import { Card, CardBody, CardHeader } from '@/components/ui/Card'
import { ButtonPrimary, ButtonSecondary } from '@/components/ui/Button'
import { StatusBadge } from '@/components/ui/StatusBadge'

interface OrganizationSelectionModalProps {
  isOpen: boolean
  onClose: () => void
  onSelect: (orgId: string) => void
}

export function OrganizationSelectionModal({
  isOpen,
  onClose,
  onSelect,
}: OrganizationSelectionModalProps) {
  const { organizations, activeOrg, isLoading } = useOrganization()
  const [selectedOrgId, setSelectedOrgId] = useState<string | null>(activeOrg?.id || null)
  const [isChanging, setIsChanging] = useState(false)

  if (!isOpen) return null

  const handleConfirm = async () => {
    if (!selectedOrgId) return

    setIsChanging(true)
    try {
      await onSelect(selectedOrgId)
      onClose()
    } catch (error) {
      console.error('Error selecting organization:', error)
      alert('Erro ao selecionar organização. Tente novamente.')
    } finally {
      setIsChanging(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
      <Card className="w-full max-w-md">
        <CardHeader>
          <h2 className="text-lg font-semibold">Selecionar Organização</h2>
          <p className="text-sm text-gray-600 mt-1">
            Você pertence a {organizations.length} organizações. Selecione qual deseja usar:
          </p>
        </CardHeader>
        <CardBody>
          {isLoading ? (
            <div className="text-center py-8">
              <div className="text-gray-500">Carregando organizações...</div>
            </div>
          ) : (
            <>
              <div className="space-y-2 mb-6">
                {organizations.map((org) => (
                  <button
                    key={org.id}
                    onClick={() => setSelectedOrgId(org.id)}
                    className={`w-full text-left p-4 border rounded-lg transition-colors ${
                      selectedOrgId === org.id
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="font-medium text-gray-900">{org.name}</span>
                          <StatusBadge
                            status={org.type === 'individual' ? 'pending' : 'active'}
                          >
                            {org.type === 'individual' ? 'Individual' : 'Igreja'}
                          </StatusBadge>
                        </div>
                        {org.contact_email && (
                          <p className="text-sm text-gray-500">{org.contact_email}</p>
                        )}
                      </div>
                      {selectedOrgId === org.id && (
                        <svg
                          className="w-5 h-5 text-primary"
                          fill="currentColor"
                          viewBox="0 0 20 20"
                        >
                          <path
                            fillRule="evenodd"
                            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                            clipRule="evenodd"
                          />
                        </svg>
                      )}
                    </div>
                  </button>
                ))}
              </div>
              <div className="flex gap-3">
                <ButtonSecondary
                  onClick={onClose}
                  disabled={isChanging}
                  className="flex-1"
                >
                  Cancelar
                </ButtonSecondary>
                <ButtonPrimary
                  onClick={handleConfirm}
                  disabled={!selectedOrgId || isChanging}
                  isLoading={isChanging}
                  className="flex-1"
                >
                  Selecionar
                </ButtonPrimary>
              </div>
            </>
          )}
        </CardBody>
      </Card>
    </div>
  )
}

