import { Cpu, Lock, Sparkles, Zap } from 'lucide-react'
import Image from 'next/image'

export default function FeaturesSection() {
    return (
        <section id="features" className="overflow-hidden py-16 md:py-32">
            <div className="mx-auto max-w-5xl space-y-8 px-6 md:space-y-12">
                <div className="relative z-10 max-w-2xl">
                    <h2 className="text-4xl font-semibold lg:text-5xl">Built for Development Teams</h2>
                    <p className="mt-6 text-lg">Streamline your development workflow with comprehensive bug tracking, task management, and QA processes designed for modern teams.</p>
                </div>
                <div className="mask-b-from-75% mask-l-from-75% mask-b-to-95% mask-l-to-95% relative -mx-4 pr-3 pt-3 md:-mx-12">
                    <div className="perspective-midrange">
                        <div className="rotate-x-6 -skew-2">
                            <div className="aspect-88/36 relative">
                                <Image
                                    src="/landing_page/dark-mode/todo_quick_actions.png"
                                    className="absolute inset-0 z-10 hidden dark:block"
                                    alt="todo quick actions dark"
                                    width={2797}
                                    height={1137}
                                />
                                <Image
                                    src="/landing_page/light-mode/todo_kanban.png"
                                    className="absolute inset-0 z-10 dark:hidden"
                                    alt="todo kanban light"
                                    width={2797}
                                    height={1137}
                                />
                            </div>
                        </div>
                    </div>
                </div>
                <div className="relative mx-auto grid grid-cols-2 gap-x-3 gap-y-6 sm:gap-8 lg:grid-cols-4">
                    <div className="space-y-3">
                        <div className="flex items-center gap-2">
                            <Zap className="size-4" />
                            <h3 className="text-sm font-medium">Quick Actions</h3>
                        </div>
                        <p className="text-muted-foreground text-sm">Fast task management with quick actions for common workflows.</p>
                    </div>
                    <div className="space-y-2">
                        <div className="flex items-center gap-2">
                            <Cpu className="size-4" />
                            <h3 className="text-sm font-medium">Bug Tracking</h3>
                        </div>
                        <p className="text-muted-foreground text-sm">Comprehensive bug tracking with severity levels and environment management.</p>
                    </div>
                    <div className="space-y-2">
                        <div className="flex items-center gap-2">
                            <Lock className="size-4" />
                            <h3 className="text-sm font-medium">QA Workflow</h3>
                        </div>
                        <p className="text-muted-foreground text-sm">Streamlined QA process with ready-for-verification tracking.</p>
                    </div>
                    <div className="space-y-2">
                        <div className="flex items-center gap-2">
                            <Sparkles className="size-4" />
                            <h3 className="text-sm font-medium">Dashboard Analytics</h3>
                        </div>
                        <p className="text-muted-foreground text-sm">Real-time insights with interactive charts and metrics.</p>
                    </div>
                </div>
            </div>
        </section>
    )
}
