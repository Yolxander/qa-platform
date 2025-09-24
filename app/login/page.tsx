import { LoginForm } from "@/components/login-form"
import { Logo } from "@/components/logo"
import Link from "next/link"

export default function Page() {
  return (
    <div className="flex min-h-svh w-full items-center justify-center p-6 md:p-10">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex justify-center">
          <Link href="/" aria-label="Go to home page">
            <Logo />
          </Link>
        </div>
        <LoginForm />
      </div>
    </div>
  )
}
