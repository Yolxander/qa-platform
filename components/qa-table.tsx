"use client"

import * as React from "react"
import {
  IconChevronDown,
  IconChevronLeft,
  IconChevronRight,
  IconChevronsLeft,
  IconChevronsRight,
  IconCheck,
  IconExternalLink,
} from "@tabler/icons-react"
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
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
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

interface QAItem {
  id: number
  title: string
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW"
  environment: "Prod" | "Stage" | "Dev"
  issueLink?: string
  updatedAt: string
  assignee: string
  dueDate: string
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

const columns: ColumnDef<QAItem>[] = [
  {
    accessorKey: "title",
    header: "Task Title",
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-medium">{row.original.title}</span>
        {row.original.issueLink && (
          <a 
            href={row.original.issueLink.startsWith('bug-') 
              ? `/bug/${row.original.issueLink.replace('bug-', '')}` 
              : `/bug/${row.original.id}`
            }
            className="text-sm text-primary hover:underline"
          >
            {row.original.issueLink}
          </a>
        )}
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
    accessorKey: "environment",
    header: "Environment",
    cell: ({ row }) => (
      <Badge variant={getEnvironmentBadgeVariant(row.original.environment)}>
        {row.original.environment}
      </Badge>
    ),
  },
  {
    accessorKey: "dueDate",
    header: "Due Date",
    cell: ({ row }) => (
      <span className="text-sm font-medium">{row.original.dueDate}</span>
    ),
  },
  {
    accessorKey: "assignee",
    header: "Assignee",
    cell: ({ row }) => (
      <span className={`text-sm ${!row.original.assignee || row.original.assignee === "Unassigned" ? "text-muted-foreground italic" : ""}`}>
        {row.original.assignee || "Unassigned"}
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
    id: "action",
    header: "Action",
    cell: ({ row }) => {
      return (
        <Button
          size="sm"
          className="h-8 gap-2"
          onClick={() => window.location.href = `/verify/${row.original.id}`}
        >
          <IconCheck className="size-4" />
          Verify
        </Button>
      )
    },
  },
]

export function QATable({ data }: { data: QAItem[] }) {
  const [rowSelection, setRowSelection] = React.useState({})
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({})
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([])
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [pagination, setPagination] = React.useState({
    pageIndex: 0,
    pageSize: 10,
  })

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
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
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
            <SelectTrigger className="h-8 w-[120px]">
              <SelectValue placeholder="All" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="Unassigned">Unassigned</SelectItem>
              <SelectItem value="Me">Me</SelectItem>
              <SelectItem value="Others">Others</SelectItem>
            </SelectContent>
          </Select>

          <Label htmlFor="sort-select">Sort:</Label>
          <Select
            value={sorting.length > 0 ? sorting[0].id : ""}
            onValueChange={(value) =>
              setSorting(value ? [{ id: value, desc: false }] : [])
            }
          >
            <SelectTrigger className="h-8 w-[120px]">
              <SelectValue placeholder="Sort by" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="dueDate">Due Date</SelectItem>
              <SelectItem value="updatedAt">Updated</SelectItem>
              <SelectItem value="severity">Severity</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="flex items-center space-x-2">
          <Input
            placeholder="Search tasks..."
            value={(table.getColumn("title")?.getFilterValue() as string) ?? ""}
            onChange={(event) =>
              table.getColumn("title")?.setFilterValue(event.target.value)
            }
            className="h-8 w-[150px] lg:w-[250px]"
          />
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
                  No tasks ready for QA.
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
    </div>
  )
}
