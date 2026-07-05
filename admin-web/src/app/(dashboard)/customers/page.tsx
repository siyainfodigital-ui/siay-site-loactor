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
import { Search, Plus, Eye, Edit, UserPlus, Image as ImageIcon } from "lucide-react"
import { createClient } from "@/lib/supabase/server"

export default async function CustomersPage() {
  const supabase = await createClient()
  const { data: customers, error } = await supabase
    .from('customers')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(50)

  if (error) {
    console.error("Error fetching customers:", error)
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "V":
        return <Badge className="bg-green-500 hover:bg-green-600">Visited</Badge>
      case "D":
        return <Badge className="bg-blue-500 hover:bg-blue-600">Done</Badge>
      case "P":
      default:
        return <Badge variant="secondary" className="bg-orange-100 text-orange-800">Pending</Badge>
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-primary">Customers</h2>
          <p className="text-muted-foreground">Manage PM Surya Ghar customer applications.</p>
        </div>
        <Button className="gap-2">
          <Plus className="h-4 w-4" /> Add Customer
        </Button>
      </div>

      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search by name, mobile..."
            className="pl-8"
          />
        </div>
        <Button variant="outline">Filter</Button>
      </div>

      <div className="rounded-md border bg-white shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-muted/50">
            <TableRow>
              <TableHead>Customer Info</TableHead>
              <TableHead>Consumer No</TableHead>
              <TableHead>Location & Installer</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {customers?.map((customer) => (
              <TableRow key={customer.id}>
                <TableCell>
                  <div className="font-medium">{customer.name}</div>
                  <div className="text-sm text-muted-foreground">{customer.mobile}</div>
                </TableCell>
                <TableCell>
                  <div className="font-medium">{customer.consumer_no || 'N/A'}</div>
                  <div className="text-sm text-muted-foreground">{customer.solar_kw ? `${customer.solar_kw} kW` : ''}</div>
                </TableCell>
                <TableCell>
                  <div>{customer.village || customer.taluka || 'Unknown'}</div>
                  <div className="text-sm text-muted-foreground flex items-center gap-1">
                    <UserPlus className="h-3 w-3" />
                    {customer.installer || "Unassigned"}
                  </div>
                </TableCell>
                <TableCell>
                  <div className="flex flex-col gap-2 items-start">
                    {getStatusBadge(customer.status)}
                  </div>
                </TableCell>
                <TableCell className="text-right space-x-2">
                  <Button variant="ghost" size="icon" title="View Details">
                    <Eye className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" title="Edit Customer">
                    <Edit className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" title="Assign Installer">
                    <UserPlus className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" title="View Installation">
                    <ImageIcon className="h-4 w-4" />
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {(!customers || customers.length === 0) && (
              <TableRow>
                <TableCell colSpan={5} className="text-center h-24 text-muted-foreground">
                  No customers found.
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
        <Button variant="outline" size="sm" disabled={!customers || customers.length < 50}>
          Next
        </Button>
      </div>
    </div>
  )
}
