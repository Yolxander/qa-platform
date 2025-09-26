import { IconTrendingDown, IconTrendingUp } from "@tabler/icons-react"

import { Badge } from "@/components/ui/badge"
import {
  Card,
  CardAction,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"

interface MetricsData {
  openIssues: number
  readyForQA: number
  mttr: string
  criticalOpen: number
  totalBugs: number
  totalTodos: number
  openTodos: number
  inProgressTodos: number
  doneTodos: number
}

interface SectionCardsProps {
  data?: MetricsData
}

export function SectionCards({ data }: SectionCardsProps) {
  // Use real data if available, otherwise show loading state
  const metrics = data || {
    openIssues: 0,
    readyForQA: 0,
    mttr: 'N/A',
    criticalOpen: 0,
    totalBugs: 0,
    totalTodos: 0,
    openTodos: 0,
    inProgressTodos: 0,
    doneTodos: 0
  }
  return (
    <div className="*:data-[slot=card]:from-primary/5 *:data-[slot=card]:to-card dark:*:data-[slot=card]:bg-card grid grid-cols-1 gap-4 px-4 *:data-[slot=card]:bg-gradient-to-t *:data-[slot=card]:shadow-xs lg:px-6 @xl/main:grid-cols-2 @5xl/main:grid-cols-4">
      <Card className="@container/card">
        <CardHeader>
          <CardDescription>Open Issues</CardDescription>
          <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
            {metrics.openIssues}
          </CardTitle>
          <CardAction>
            <Badge variant="outline">
              <IconTrendingUp />
              {metrics.openIssues > 0 ? `+${metrics.openIssues}` : '0'}
            </Badge>
          </CardAction>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1.5 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium">
            Active bugs and todos <IconTrendingUp className="size-4" />
          </div>
        </CardFooter>
      </Card>
      <Card className="@container/card">
        <CardHeader>
          <CardDescription>Ready for QA</CardDescription>
          <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
            {metrics.readyForQA}
          </CardTitle>
          <CardAction>
            <Badge variant="outline">
              <IconTrendingDown />
              {metrics.readyForQA > 0 ? `-${metrics.readyForQA}` : '0'}
            </Badge>
          </CardAction>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1.5 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium">
            Items ready for testing <IconTrendingDown className="size-4" />
          </div>
        </CardFooter>
      </Card>
      <Card className="@container/card">
        <CardHeader>
          <CardDescription>MTTR (last 14d)</CardDescription>
          <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
            {metrics.mttr}
          </CardTitle>
          <CardAction>
            <Badge variant="outline">
              <IconTrendingUp />
              {metrics.mttr !== 'N/A' ? `+${metrics.mttr}` : 'N/A'}
            </Badge>
          </CardAction>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1.5 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium">
            Mean time to resolve <IconTrendingUp className="size-4" />
          </div>
        </CardFooter>
      </Card>
      <Card className="@container/card">
        <CardHeader>
          <CardDescription>Critical Open</CardDescription>
          <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
            {metrics.criticalOpen}
          </CardTitle>
          <CardAction>
            <Badge variant="destructive">
              <IconTrendingUp />
              {metrics.criticalOpen > 0 ? `+${metrics.criticalOpen}` : '0'}
            </Badge>
          </CardAction>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1.5 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium text-destructive">
            Requires immediate attention <IconTrendingUp className="size-4" />
          </div>
        </CardFooter>
      </Card>
    </div>
  )
}
