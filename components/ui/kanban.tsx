"use client";

import * as React from "react";
import { createContext, useContext, useCallback } from "react";

interface KanbanColumn {
  id: string;
  name: string;
  color: string;
}

interface KanbanData {
  id: string | number;
  [key: string]: any;
}

interface KanbanContextType {
  columns: KanbanColumn[];
  data: KanbanData[];
  onDataChange: (data: KanbanData[]) => void;
}

const KanbanContext = createContext<KanbanContextType | null>(null);

interface KanbanProviderProps {
  columns: KanbanColumn[];
  data: KanbanData[];
  onDataChange: (data: KanbanData[]) => void;
  children: (column: KanbanColumn) => React.ReactNode;
}

export function KanbanProvider({
  columns,
  data,
  onDataChange,
  children,
}: KanbanProviderProps) {
  return (
    <KanbanContext.Provider value={{ columns, data, onDataChange }}>
      <div className="flex gap-4 overflow-x-auto p-4">
        {columns.map((column) => children(column))}
      </div>
    </KanbanContext.Provider>
  );
}

interface KanbanBoardProps {
  id: string;
  children: React.ReactNode;
}

export function KanbanBoard({ id, children }: KanbanBoardProps) {
  return (
    <div className="flex min-w-80 flex-col rounded-lg border bg-background">
      {children}
    </div>
  );
}

interface KanbanHeaderProps {
  children: React.ReactNode;
}

export function KanbanHeader({ children }: KanbanHeaderProps) {
  return (
    <div className="flex items-center justify-between border-b p-4">
      {children}
    </div>
  );
}

interface KanbanCardsProps {
  id: string;
  children: (item: KanbanData) => React.ReactNode;
}

export function KanbanCards({ id, children }: KanbanCardsProps) {
  const context = useContext(KanbanContext);
  if (!context) {
    throw new Error("KanbanCards must be used within a KanbanProvider");
  }

  const { data, onDataChange } = context;

  const handleDragStart = useCallback(
    (e: React.DragEvent, itemId: string | number) => {
      e.dataTransfer.setData("text/plain", itemId.toString());
    },
    []
  );

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      const itemId = e.dataTransfer.getData("text/plain");
      
      // Find the item being dragged
      const draggedItem = data.find((item) => item.id.toString() === itemId);
      if (!draggedItem) return;

      // Update the item's column
      const updatedData = data.map((item) =>
        item.id.toString() === itemId
          ? { ...item, column: id }
          : item
      );

      onDataChange(updatedData);
    },
    [data, onDataChange, id]
  );

  const columnData = data.filter((item) => item.column === id);

  return (
    <div
      className="flex-1 space-y-2 p-4"
      onDragOver={handleDragOver}
      onDrop={handleDrop}
    >
      {columnData.map((item) => (
        <div
          key={item.id}
          draggable
          onDragStart={(e) => handleDragStart(e, item.id)}
          className="cursor-move"
        >
          {children(item)}
        </div>
      ))}
    </div>
  );
}

interface KanbanCardProps {
  id: string | number;
  column: string;
  name: string;
  children: React.ReactNode;
}

export function KanbanCard({ id, column, name, children }: KanbanCardProps) {
  return (
    <div className="rounded-lg border bg-card p-3 shadow-sm transition-shadow hover:shadow-md">
      {children}
    </div>
  );
}
