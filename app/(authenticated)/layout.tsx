import React from 'react'
import { AppLayoutClient } from '@/components/layout/AppLayoutClient'

export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Sidebar items serão definidos por página específica
  // Por enquanto, layout básico
  return (
    <AppLayoutClient sidebarItems={[]}>
      {children}
    </AppLayoutClient>
  )
}
