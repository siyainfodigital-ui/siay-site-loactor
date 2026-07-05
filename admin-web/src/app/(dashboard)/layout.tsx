import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar"
import { AppSidebar } from "@/components/app-sidebar"

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <main className="flex w-full flex-col p-4 bg-muted/10 min-h-svh overflow-hidden">
        <SidebarTrigger />
        <div className="flex-1 rounded-xl p-4 mt-2 border bg-card text-card-foreground shadow-sm">
          {children}
        </div>
      </main>
    </SidebarProvider>
  )
}
