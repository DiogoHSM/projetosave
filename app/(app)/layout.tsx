import { AppLayout } from '@/components/layout/AppLayout'

export default function AuthenticatedLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Sidebar items serão definidos por página específica
  // Por enquanto, layout básico
  return (
    <AppLayout sidebarItems={[]}>
      {children}
    </AppLayout>
  )
}

