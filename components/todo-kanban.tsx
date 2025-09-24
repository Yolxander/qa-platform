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
  IconArrowRight,
} from "@tabler/icons-react";
import { supabase } from "@/lib/supabase";
import { toast } from "sonner";

interface TodoItem {
  id: number;
  title: string;
  issueLink: string;
  status: "OPEN" | "IN_PROGRESS" | "READY_FOR_QA" | "DONE";
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
  dueDate: string;
  environment: "Prod" | "Stage" | "Dev";
  assignee: string;
  quickAction: "Start" | "Mark Done" | "Send to QA" | "Reopen";
  column?: string;
}

const columns = [
  { id: "OPEN", name: "Open", color: "#6B7280" },
  { id: "IN_PROGRESS", name: "In Progress", color: "#F59E0B" },
  { id: "READY_FOR_QA", name: "Ready for QA", color: "#8B5CF6" },
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
    case "Send to QA":
      return <IconArrowRight className="size-4" />;
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
  const [isUpdating, setIsUpdating] = useState(false);

  const handleDataChange = async (newData: TodoItem[]) => {
    // Find the item that was moved by comparing with previous state
    const movedItem = newData.find((newItem) => {
      const oldItem = todos.find((old) => old.id === newItem.id);
      return oldItem && oldItem.column !== newItem.column;
    });

    if (movedItem) {
      setIsUpdating(true);
      // Update the database with the new status
      await updateTodoStatus(movedItem.id, movedItem.column);
      setIsUpdating(false);
    }

    setTodos(newData);
  };

  const updateTodoStatus = async (todoId: number, newStatus: string) => {
    if (!supabase) {
      toast.error("Database not configured");
      return;
    }

    try {
      const { error } = await supabase
        .from('todos')
        .update({ status: newStatus })
        .eq('id', todoId);

      if (error) {
        throw error;
      }

      toast.success(`Todo moved to ${newStatus}`);
    } catch (error) {
      console.error("Error updating todo status:", error);
      toast.error("Failed to update todo status");
      // Revert the change on error
      setTodos(todos);
    }
  };

  return (
    <div className="w-full space-y-4 px-4 lg:px-6">
      {isUpdating && (
        <div className="flex items-center justify-center py-2">
          <div className="text-sm text-muted-foreground">Updating todo status...</div>
        </div>
      )}
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
