import { Button } from '@/components/ui/button'
import { ChevronRight } from 'lucide-react'
import Link from 'next/link'

export default function ContentSection() {
    return (
        <section className="py-16 md:py-32">
            <div className="mx-auto max-w-5xl px-6">
                <div className="grid gap-6 md:grid-cols-2 md:gap-12">
                    <h2 className="text-4xl font-medium">Comprehensive Bug Tracking & Task Management</h2>
                    <div className="space-y-6">
                        <p>Our platform provides complete project management — from bug tracking to QA workflows, designed for modern development teams.</p>
                        <p>
                            <span className="font-bold">Streamline your workflow</span> with powerful analytics, environment management, and team collaboration tools that help you deliver better software faster.
                        </p>
                        <Button
                            asChild
                            variant="secondary"
                            size="sm"
                            className="gap-1 pr-1.5">
                            <Link href="/bugs">
                                <span>View Bugs</span>
                                <ChevronRight className="size-2" />
                            </Link>
                        </Button>
                    </div>
                </div>
            </div>
        </section>
    )
}