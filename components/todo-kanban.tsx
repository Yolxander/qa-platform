"use client";

import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  KanbanBoard,
  KanbanCard,
  KanbanCards,
  KanbanHeader,
  KanbanProvider,
} from "@/components/ui/kanban";
import {
  IconPlayerPlay,
  IconCheck,
  IconRotateClockwise,
} from "@tabler/icons-react";

interface TodoItem {
  id: number;
  title: string;
  issueLink: string;
  status: "OPEN" | "IN_PROGRESS" | "DONE";
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
  dueDate: string;
  environment: "Prod" | "Stage" | "Dev";
  assignee: string;
  quickAction: "Start" | "Mark Done" | "Reopen";
  column?: string;
}

const columns = [
  { id: "OPEN", name: "Open", color: "#6B7280" },
  { id: "IN_PROGRESS", name: "In Progress", color: "#F59E0B" },
  { id: "DONE", name: "Done", color: "#10B981" },
];

const getSeverityBadgeVariant = (severity: string) => {
  switch (severity) {
    case "CRITICAL":
      return "destructive";
    case "HIGH":
      return "default";
    case "MEDIUM":
      return "secondary";
    case "LOW":
      return "outline";
    default:
      return "secondary";
  }
};

const getQuickActionIcon = (action: string) => {
  switch (action) {
    case "Start":
      return <IconPlayerPlay className="size-4" />;
    case "Mark Done":
      return <IconCheck className="size-4" />;
    case "Reopen":
      return <IconRotateClockwise className="size-4" />;
    default:
      return <IconPlayerPlay className="size-4" />;
  }
};

const getInitials = (name: string) => {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase();
};

export function TodoKanban({ data }: { data: TodoItem[] }) {
  // Transform data to include column mapping and ensure proper format
  const [todos, setTodos] = useState<TodoItem[]>(
    data.map((item) => ({
      ...item,
      column: item.status, // Map status to column
    }))
  );

  const handleDataChange = (newData: TodoItem[]) => {
    setTodos(newData);
  };

  return (
    <div className="w-full space-y-4 px-4 lg:px-6">
      <KanbanProvider
        columns={columns}
        data={todos}
        onDataChange={handleDataChange}
      >
        {(column) => (
          <KanbanBoard id={column.id} key={column.id}>
            <KanbanHeader>
              <div className="flex items-center gap-2">
                <div
                  className="h-2 w-2 rounded-full"
                  style={{ backgroundColor: column.color }}
                />
                <span className="font-medium">{column.name}</span>
                <Badge variant="secondary" className="ml-auto">
                  {todos.filter((todo) => todo.column === column.id).length}
                </Badge>
              </div>
            </KanbanHeader>
            <KanbanCards id={column.id}>
              {(todo: TodoItem) => (
                <KanbanCard
                  column={column.id}
                  id={todo.id}
                  key={todo.id}
                  name={todo.title}
                >
                  <div className="space-y-3">
                    {/* Title and Issue Link */}
                    <div className="flex flex-col gap-1">
                      <p className="m-0 font-medium text-sm leading-tight">
                        {todo.title}
                      </p>
                      <a
                        href={`/issues/${todo.issueLink}`}
                        className="text-xs text-primary hover:underline"
                      >
                        {todo.issueLink}
                      </a>
                    </div>

                    {/* Severity Badge */}
                    <div className="flex justify-between items-center">
                      <Badge variant={getSeverityBadgeVariant(todo.severity)} className="text-xs">
                        {todo.severity}
                      </Badge>
                      <Badge variant="outline" className="text-xs">
                        {todo.environment}
                      </Badge>
                    </div>

                    {/* Due Date */}
                    <div className="text-xs text-muted-foreground">
                      Due: {todo.dueDate}
                    </div>

                    {/* Assignee and Quick Action */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Avatar className="h-6 w-6">
                          <AvatarFallback className="text-xs">
                            {getInitials(todo.assignee)}
                          </AvatarFallback>
                        </Avatar>
                        <span className="text-xs text-muted-foreground">
                          {todo.assignee}
                        </span>
                      </div>
                      <Button
                        size="sm"
                        variant="outline"
                        className="h-6 gap-1 px-2 text-xs"
                        onClick={() =>
                          console.log(`${todo.quickAction} clicked for ${todo.title}`)
                        }
                      >
                        {getQuickActionIcon(todo.quickAction)}
                        <span className="hidden sm:inline">{todo.quickAction}</span>
                      </Button>
                    </div>
                  </div>
                </KanbanCard>
              )}
            </KanbanCards>
          </KanbanBoard>
        )}
      </KanbanProvider>
    </div>
  );
}
