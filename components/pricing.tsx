"use client"

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Check } from 'lucide-react'
import { ComingSoonModal } from '@/components/coming-soon-modal'

export default function Pricing() {
    const [modalOpen, setModalOpen] = useState(false)
    const [selectedPlan, setSelectedPlan] = useState("")

    const handleComingSoonClick = (planName: string) => {
        setSelectedPlan(planName)
        setModalOpen(true)
    }

    return (
        <section id="pricing">
            <div className="mx-auto max-w-6xl px-6">
                <div className="mx-auto max-w-2xl space-y-6 text-center">
                    <h1 className="text-center text-4xl font-semibold lg:text-5xl">Pricing that Scales with Your Team</h1>
                    <p>Choose the perfect plan for your development team. From individual developers to large organizations, we have the right solution for your project management needs.</p>
                </div>

                <div className="mt-8 grid gap-6 md:mt-20 md:grid-cols-3">
                    <Card>
                        <CardHeader>
                            <CardTitle className="font-medium">Free</CardTitle>

                            <span className="my-3 block text-2xl font-semibold">$0 / mo</span>

                            <CardDescription className="text-sm">Per editor</CardDescription>
                            <Button
                                asChild
                                variant="outline"
                                className="mt-4 w-full">
                                <Link href="/dashboard">Get Started</Link>
                            </Button>
                        </CardHeader>

                        <CardContent className="space-y-4">
                            <hr className="border-dashed" />

                            <ul className="list-outside space-y-3 text-sm">
                                {['Basic Bug Tracking', 'Task Management', 'Email Support'].map((item, index) => (
                                    <li
                                        key={index}
                                        className="flex items-center gap-2">
                                        <Check className="size-3" />
                                        {item}
                                    </li>
                                ))}
                            </ul>
                        </CardContent>
                    </Card>

                    <Card className="relative">
                        <span className="bg-linear-to-br/increasing absolute inset-x-0 -top-3 mx-auto flex h-6 w-fit items-center rounded-full from-purple-400 to-amber-300 px-3 py-1 text-xs font-medium text-amber-950 ring-1 ring-inset ring-white/20 ring-offset-1 ring-offset-gray-950/5">Popular</span>

                        <CardHeader>
                            <CardTitle className="font-medium">Pro</CardTitle>

                            <span className="my-3 block text-2xl font-semibold">$19 / mo</span>

                            <CardDescription className="text-sm">Per editor</CardDescription>

                            <Button
                                className="mt-4 w-full"
                                onClick={() => handleComingSoonClick("Pro Plan")}>
                                Coming Soon
                            </Button>
                        </CardHeader>

                        <CardContent className="space-y-4">
                            <hr className="border-dashed" />

                            <ul className="list-outside space-y-3 text-sm">
                                {['Everything in Free Plan', 'Advanced Analytics', 'Team Collaboration', 'QA Workflow Management', 'Priority Support', 'Custom Integrations', 'Advanced Reporting', 'Environment Management', 'Team Dashboard', 'API Access'].map((item, index) => (
                                    <li
                                        key={index}
                                        className="flex items-center gap-2">
                                        <Check className="size-3" />
                                        {item}
                                    </li>
                                ))}
                            </ul>
                        </CardContent>
                    </Card>

                    <Card className="flex flex-col">
                        <CardHeader>
                            <CardTitle className="font-medium">Startup</CardTitle>

                            <span className="my-3 block text-2xl font-semibold">$29 / mo</span>

                            <CardDescription className="text-sm">Per editor</CardDescription>

                            <Button
                                variant="outline"
                                className="mt-4 w-full"
                                onClick={() => handleComingSoonClick("Startup Plan")}>
                                Coming Soon
                            </Button>
                        </CardHeader>

                        <CardContent className="space-y-4">
                            <hr className="border-dashed" />

                            <ul className="list-outside space-y-3 text-sm">
                                {['Everything in Pro Plan', 'Enterprise Security', 'Dedicated Support'].map((item, index) => (
                                    <li
                                        key={index}
                                        className="flex items-center gap-2">
                                        <Check className="size-3" />
                                        {item}
                                    </li>
                                ))}
                            </ul>
                        </CardContent>
                    </Card>
                </div>
            </div>
            
            <ComingSoonModal
                open={modalOpen}
                onOpenChange={setModalOpen}
                planName={selectedPlan}
            />
        </section>
    )
}
