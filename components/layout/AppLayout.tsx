'use client'

import React from 'react'
import { Header } from './Header'
import { Sidebar } from './Sidebar'

interface AppLayoutProps {
  children: React.ReactNode
  sidebarItems?: Array<{
    label: string
    href: string
    icon?: React.ReactNode
  }>
}

export function AppLayout({ children, sidebarItems = [] }: AppLayoutProps) {
  return (
    <div className="flex h-screen flex-col">
      <Header />
      <div className="flex flex-1 overflow-hidden">
        {sidebarItems.length > 0 && <Sidebar items={sidebarItems} />}
        <main className="flex-1 overflow-y-auto bg-gray-50">
          <div className="p-6">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}

