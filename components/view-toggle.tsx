"use client";

import { Button } from "@/components/ui/button";
import { IconLayoutGrid, IconTable } from "@tabler/icons-react";

interface ViewToggleProps {
  currentView: "table" | "kanban";
  onViewChange: (view: "table" | "kanban") => void;
}

export function ViewToggle({ currentView, onViewChange }: ViewToggleProps) {
  return (
    <div className="flex items-center gap-1 rounded-lg border p-1">
      <Button
        variant={currentView === "table" ? "default" : "ghost"}
        size="sm"
        onClick={() => onViewChange("table")}
        className="gap-2"
      >
        <IconTable className="h-4 w-4" />
        <span className="hidden sm:inline">Table</span>
      </Button>
      <Button
        variant={currentView === "kanban" ? "default" : "ghost"}
        size="sm"
        onClick={() => onViewChange("kanban")}
        className="gap-2"
      >
        <IconLayoutGrid className="h-4 w-4" />
        <span className="hidden sm:inline">Kanban</span>
      </Button>
    </div>
  );
}
