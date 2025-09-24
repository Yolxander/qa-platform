"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import {
  IconChevronDown,
  IconChevronLeft,
  IconChevronRight,
  IconChevronsLeft,
  IconChevronsRight,
  IconEye,
  IconEdit,
  IconMessage,
  IconExternalLink,
  IconTrash,
} from "@tabler/icons-react"
import { EditBugModal } from "@/components/edit-bug-modal"
import { DeleteBugDialog } from "@/components/delete-bug-dialog"
import {
  ColumnDef,
  ColumnFiltersState,
  flexRender,
  getCoreRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  SortingState,
  useReactTable,
  VisibilityState,
} from "@tanstack/react-table"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

interface BugItem {
  id: number
  title: string
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW"
  status: "Open" | "Closed"
  environment: "Prod" | "Stage" | "Dev"
  reporter: string
  assignee: string
  updatedAt: string
  description: string
}

const getSeverityBadgeVariant = (severity: string) => {
  switch (severity) {
    case "CRITICAL":
      return "destructive"
    case "HIGH":
      return "default"
    case "MEDIUM":
      return "secondary"
    case "LOW":
      return "outline"
    default:
      return "secondary"
  }
}

const getStatusBadgeVariant = (status: string) => {
  switch (status) {
    case "Open":
      return "default"
    case "Closed":
      return "outline"
    default:
      return "secondary"
  }
}

const getEnvironmentBadgeVariant = (environment: string) => {
  switch (environment) {
    case "Prod":
      return "destructive"
    case "Stage":
      return "default"
    case "Dev":
      return "secondary"
    default:
      return "outline"
  }
}

export function BugsTable({ data }: { data: BugItem[] }) {
  const router = useRouter()
  const [rowSelection, setRowSelection] = React.useState({})
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({})
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([])
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [pagination, setPagination] = React.useState({
    pageIndex: 0,
    pageSize: 10,
  })

  // Modal states
  const [editModalOpen, setEditModalOpen] = React.useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = React.useState(false)
  const [selectedBug, setSelectedBug] = React.useState<BugItem | null>(null)

  // Modal handlers
  const handleEditBug = (bug: BugItem) => {
    setSelectedBug(bug)
    setEditModalOpen(true)
  }

  const handleDeleteBug = (bug: BugItem) => {
    setSelectedBug(bug)
    setDeleteDialogOpen(true)
  }

  const handleBugUpdated = () => {
    // This will be passed to the parent component to refresh data
    window.location.reload() // Simple refresh for now
  }

  const createColumns = (
    onEditBug: (bug: BugItem) => void,
    onDeleteBug: (bug: BugItem) => void
  ): ColumnDef<BugItem>[] => [
    {
      accessorKey: "title",
      header: "Title",
      cell: ({ row }) => (
        <div className="flex flex-col">
          <button 
            className="text-left font-medium hover:text-primary hover:underline truncate max-w-[200px]"
            onClick={() => router.push(`/bug/${row.original.id}`)}
            title={row.original.title}
          >
            {row.original.title}
          </button>
        </div>
      ),
      },
    {
      accessorKey: "severity",
      header: "Severity",
      cell: ({ row }) => (
        <Badge variant={getSeverityBadgeVariant(row.original.severity)}>
          {row.original.severity}
        </Badge>
      ),
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => (
        <Badge variant={getStatusBadgeVariant(row.original.status)}>
          {row.original.status}
        </Badge>
      ),
    },
    {
      accessorKey: "environment",
      header: "Environment",
      cell: ({ row }) => (
        <Badge variant={getEnvironmentBadgeVariant(row.original.environment)}>
          {row.original.environment}
        </Badge>
      ),
    },
    {
      accessorKey: "reporter",
      header: "Reporter",
      cell: ({ row }) => (
        <span className="text-sm text-muted-foreground">{row.original.reporter}</span>
      ),
    },
    {
      accessorKey: "assignee",
      header: "Assignee",
      cell: ({ row }) => (
        <span className={`text-sm ${row.original.assignee === "Unassigned" ? "text-muted-foreground italic" : ""}`}>
          {row.original.assignee}
        </span>
      ),
    },
    {
      accessorKey: "updatedAt",
      header: "Updated At",
      cell: ({ row }) => (
        <span className="text-sm text-muted-foreground">{row.original.updatedAt}</span>
      ),
    },
    {
      id: "actions",
      header: "Actions",
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <Button
            size="sm"
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => router.push(`/bug/${row.original.id}`)}
            title="View Details"
          >
            <IconEye className="size-4" />
          </Button>
          <Button
            size="sm"
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => onEditBug(row.original)}
            title="Edit Bug"
          >
            <IconEdit className="size-4" />
          </Button>
          <Button
            size="sm"
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => console.log(`Add comment: ${row.original.title}`)}
            title="Add Comment"
          >
            <IconMessage className="size-4" />
          </Button>
          <Button
            size="sm"
            variant="outline"
            className="h-8 w-8 p-0 text-destructive hover:text-destructive"
            onClick={() => onDeleteBug(row.original)}
            title="Delete Bug"
          >
            <IconTrash className="size-4" />
          </Button>
        </div>
      ),
    },
  ]

  const columns = createColumns(handleEditBug, handleDeleteBug)

  const table = useReactTable({
    data,
    columns,
    state: {
      sorting,
      columnVisibility,
      rowSelection,
      columnFilters,
      pagination,
    },
    enableRowSelection: true,
    onRowSelectionChange: setRowSelection,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    onPaginationChange: setPagination,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFacetedRowModel: getFacetedRowModel(),
    getFacetedUniqueValues: getFacetedUniqueValues(),
  })

  return (
    <div className="w-full space-y-4 px-4 lg:px-6">
      {/* Filter Controls */}
      <div className="flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2 flex-wrap">

            <Label htmlFor="severity-filter">Severity:</Label>
            <Select
              value={(table.getColumn("severity")?.getFilterValue() as string) ?? ""}
              onValueChange={(value) =>
                table.getColumn("severity")?.setFilterValue(value === "all" ? "" : value)
              }
            >
              <SelectTrigger className="h-8 w-[120px]">
                <SelectValue placeholder="All" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="CRITICAL">Critical</SelectItem>
                <SelectItem value="HIGH">High</SelectItem>
                <SelectItem value="MEDIUM">Medium</SelectItem>
                <SelectItem value="LOW">Low</SelectItem>
              </SelectContent>
            </Select>

            <Label htmlFor="environment-filter">Environment:</Label>
            <Select
              value={(table.getColumn("environment")?.getFilterValue() as string) ?? ""}
              onValueChange={(value) =>
                table.getColumn("environment")?.setFilterValue(value === "all" ? "" : value)
              }
            >
              <SelectTrigger className="h-8 w-[100px]">
                <SelectValue placeholder="All" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="Prod">Prod</SelectItem>
                <SelectItem value="Stage">Stage</SelectItem>
                <SelectItem value="Dev">Dev</SelectItem>
              </SelectContent>
            </Select>

            <Label htmlFor="assignee-filter">Assignee:</Label>
            <Select
              value={(table.getColumn("assignee")?.getFilterValue() as string) ?? ""}
              onValueChange={(value) =>
                table.getColumn("assignee")?.setFilterValue(value === "all" ? "" : value)
              }
            >
              <SelectTrigger className="h-8 w-[140px]">
                <SelectValue placeholder="All" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="Unassigned">Unassigned</SelectItem>
                <SelectItem value="Alex Thompson">Alex Thompson</SelectItem>
                <SelectItem value="Maya Johnson">Maya Johnson</SelectItem>
                <SelectItem value="David Kim">David Kim</SelectItem>
                <SelectItem value="Raj Patel">Raj Patel</SelectItem>
                <SelectItem value="Leila Ahmadi">Leila Ahmadi</SelectItem>
                <SelectItem value="Thomas Wilson">Thomas Wilson</SelectItem>
                <SelectItem value="Maria Garcia">Maria Garcia</SelectItem>
                <SelectItem value="James Wilson">James Wilson</SelectItem>
                <SelectItem value="Nina Patel">Nina Patel</SelectItem>
                <SelectItem value="Sophia Martinez">Sophia Martinez</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="flex items-center space-x-2">
            <Input
              placeholder="Search bugs..."
              value={(table.getColumn("title")?.getFilterValue() as string) ?? ""}
              onChange={(event) =>
                table.getColumn("title")?.setFilterValue(event.target.value)
              }
              className="h-8 w-[200px] lg:w-[300px]"
            />
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => {
                  return (
                    <TableHead key={header.id}>
                      {header.isPlaceholder
                        ? null
                        : flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                    </TableHead>
                  )
                })}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() && "selected"}
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
                >
                  No bugs found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between space-x-2 py-4">
        <div className="flex-1 text-sm text-muted-foreground">
          {table.getFilteredSelectedRowModel().rows.length} of{" "}
          {table.getFilteredRowModel().rows.length} row(s) selected.
        </div>
        <div className="flex items-center space-x-6 lg:space-x-8">
          <div className="flex items-center space-x-2">
            <p className="text-sm font-medium">Rows per page</p>
            <Select
              value={`${table.getState().pagination.pageSize}`}
              onValueChange={(value) => {
                table.setPageSize(Number(value))
              }}
            >
              <SelectTrigger className="h-8 w-[70px]">
                <SelectValue placeholder={table.getState().pagination.pageSize} />
              </SelectTrigger>
              <SelectContent side="top">
                {[10, 20, 30, 40, 50].map((pageSize) => (
                  <SelectItem key={pageSize} value={`${pageSize}`}>
                    {pageSize}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex w-[100px] items-center justify-center text-sm font-medium">
            Page {table.getState().pagination.pageIndex + 1} of{" "}
            {table.getPageCount()}
          </div>
          <div className="flex items-center space-x-2">
            <Button
              variant="outline"
              className="hidden h-8 w-8 p-0 lg:flex"
              onClick={() => table.setPageIndex(0)}
              disabled={!table.getCanPreviousPage()}
            >
              <span className="sr-only">Go to first page</span>
              <IconChevronsLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              className="h-8 w-8 p-0"
              onClick={() => table.previousPage()}
              disabled={!table.getCanPreviousPage()}
            >
              <span className="sr-only">Go to previous page</span>
              <IconChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              className="h-8 w-8 p-0"
              onClick={() => table.nextPage()}
              disabled={!table.getCanNextPage()}
            >
              <span className="sr-only">Go to next page</span>
              <IconChevronRight className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              className="hidden h-8 w-8 p-0 lg:flex"
              onClick={() => table.setPageIndex(table.getPageCount() - 1)}
              disabled={!table.getCanNextPage()}
            >
              <span className="sr-only">Go to last page</span>
              <IconChevronsRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </div>

      {/* Modals */}
      {selectedBug && (
        <>
          <EditBugModal
            open={editModalOpen}
            onOpenChange={setEditModalOpen}
            bug={selectedBug}
            onBugUpdated={handleBugUpdated}
          />
          <DeleteBugDialog
            open={deleteDialogOpen}
            onOpenChange={setDeleteDialogOpen}
            bug={selectedBug}
            onBugDeleted={handleBugUpdated}
          />
        </>
      )}
    </div>
  )
}
