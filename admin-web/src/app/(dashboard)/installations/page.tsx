import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Search, Eye, Check, X, Image as ImageIcon } from "lucide-react"
import { GlobalImageViewer, ImageData } from "@/components/global-image-viewer"
import { createClient } from "@/lib/supabase/server"

export default async function InstallationsPage() {
  const supabase = await createClient()
  
  // Try to fetch installations with nested customer data. If FK is not set up perfectly, this might fail or return null for customers.
  const { data: installations, error } = await supabase
    .from('installations')
    .select('*, customers(name, consumer_no)')
    .limit(50)

  if (error) {
    console.error("Error fetching installations:", error)
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "A":
        return <Badge className="bg-green-500 hover:bg-green-600">Approved</Badge>
      case "P":
        return <Badge variant="secondary" className="bg-orange-100 text-orange-800">Pending</Badge>
      case "S":
        return <Badge className="bg-blue-500 hover:bg-blue-600">Submitted</Badge>
      case "R":
        return <Badge variant="destructive">Rejected</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  // To properly pass data to the client-side Image Viewer component, we'd extract it into a client wrapper,
  // but for now we'll just demonstrate the UI structure with the real data fetched on the server.
  
  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-primary">Installations</h2>
          <p className="text-muted-foreground">Verify and manage solar installations and photos.</p>
        </div>
      </div>

      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search by app no, installer..."
            className="pl-8"
          />
        </div>
        <Button variant="outline">Filter Status</Button>
      </div>

      <div className="rounded-md border bg-white shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-muted/50">
            <TableRow>
              <TableHead>Customer / App No</TableHead>
              <TableHead>Dates</TableHead>
              <TableHead>Equipment</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {installations?.map((inst) => {
              const customerName = inst.customers?.name || 'Unknown'
              const consumerNo = inst.customers?.consumer_no || inst.customer_id
              
              return (
                <TableRow key={inst.id}>
                  <TableCell>
                    <div className="font-medium">{customerName}</div>
                    <div className="text-sm text-muted-foreground">{consumerNo}</div>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">Submitted: {inst.submitted_at ? new Date(inst.submitted_at).toLocaleDateString() : 'N/A'}</div>
                    <div className="text-sm text-muted-foreground">Verified: {inst.verified_at ? new Date(inst.verified_at).toLocaleDateString() : 'Pending'}</div>
                  </TableCell>
                  <TableCell>
                    <div>Inverter: <span className="font-medium">{inst.inverter_brand || 'N/A'}</span></div>
                    <div className="text-xs text-muted-foreground">Panels: {inst.panel_count || 0} x {inst.panel_brand || 'N/A'}</div>
                  </TableCell>
                  <TableCell>
                    {getStatusBadge(inst.verification_status || 'P')}
                  </TableCell>
                  <TableCell className="text-right space-x-2">
                    <Button variant="outline" size="sm" title="View Photos requires client component wrapper">
                      <ImageIcon className="h-4 w-4 mr-2" />
                      Photos
                    </Button>
                    {inst.verification_status === 'S' && (
                      <>
                        <Button variant="default" size="icon" className="bg-green-600 hover:bg-green-700" title="Approve">
                          <Check className="h-4 w-4" />
                        </Button>
                        <Button variant="destructive" size="icon" title="Reject">
                          <X className="h-4 w-4" />
                        </Button>
                      </>
                    )}
                  </TableCell>
                </TableRow>
              )
            })}
            {(!installations || installations.length === 0) && (
              <TableRow>
                <TableCell colSpan={5} className="text-center h-24 text-muted-foreground">
                  No installations found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      
      <div className="flex items-center justify-end space-x-2 py-4">
        <Button variant="outline" size="sm" disabled>
          Previous
        </Button>
        <Button variant="outline" size="sm" disabled={!installations || installations.length < 50}>
          Next
        </Button>
      </div>
    </div>
  )
}
