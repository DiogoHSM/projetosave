'use client'

import { AppLayout } from './AppLayout'
import { OrganizationProvider } from '@/contexts/OrganizationContext'

interface AppLayoutClientProps {
  children: React.ReactNode
  sidebarItems?: Array<{
    label: string
    href: string
    icon?: React.ReactNode
  }>
}

export function AppLayoutClient({ children, sidebarItems = [] }: AppLayoutClientProps) {
  return (
    <OrganizationProvider>
      <AppLayout sidebarItems={sidebarItems}>
        {children}
      </AppLayout>
    </OrganizationProvider>
  )
}
