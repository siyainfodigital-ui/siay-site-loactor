import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Users, FileText, Wrench, CheckCircle, Clock, XCircle, HardHat, Briefcase } from "lucide-react"

export default async function DashboardPage() {
  // In a real app, these numbers would come from a Supabase query
  // e.g., const { count } = await supabase.from('customers').select('*', { count: 'exact', head: true })

  const stats = [
    { title: "Total Customers", value: "52,481", icon: Users, color: "text-blue-500" },
    { title: "Today's Applications", value: "142", icon: FileText, color: "text-indigo-500" },
    { title: "Pending Installations", value: "3,210", icon: Clock, color: "text-orange-500" },
    { title: "Installations In Progress", value: "840", icon: Wrench, color: "text-yellow-500" },
    { title: "Ready for Verification", value: "412", icon: FileText, color: "text-purple-500" },
    { title: "Verified Installations", value: "48,015", icon: CheckCircle, color: "text-green-500" },
    { title: "Rejected", value: "84", icon: XCircle, color: "text-red-500" },
    { title: "Active Installers", value: "450", icon: HardHat, color: "text-slate-500" },
    { title: "Active Office Staff", value: "24", icon: Briefcase, color: "text-slate-700" },
  ]

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight text-primary">Dashboard</h2>
        <p className="text-muted-foreground">Overview of the PM Surya Ghar management system.</p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <Card className="col-span-4">
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
          </CardHeader>
          <CardContent className="pl-2">
            <div className="h-[300px] flex items-center justify-center text-muted-foreground border-2 border-dashed rounded-lg m-4">
              Activity Chart Placeholder (Recharts)
            </div>
          </CardContent>
        </Card>
        <Card className="col-span-3">
          <CardHeader>
            <CardTitle>Pending Verification Queue</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-8">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex items-center">
                  <div className="ml-4 space-y-1">
                    <p className="text-sm font-medium leading-none">Customer #{1000 + i}</p>
                    <p className="text-sm text-muted-foreground">App No: SG-2024-00{i}</p>
                  </div>
                  <div className="ml-auto font-medium text-orange-500 text-sm">Review</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
