"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { getSupabaseClient } from "@/lib/supabase";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsLoading(true);

    try {
      const { data, error: signInError } = await getSupabaseClient().auth.signInWithPassword({
        email: email.trim(),
        password,
      });

      if (signInError) throw signInError;
      if (data.user.app_metadata.role !== "coop_admin") {
        await getSupabaseClient().auth.signOut();
        throw new Error("This account is not authorized for the admin portal.");
      }

      router.replace("/dashboard");
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Unable to sign in.");
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#F5F6F8] px-5">
      <form onSubmit={handleSubmit} className="w-full max-w-[380px] border-t-4 border-[#155D3B] bg-white p-8 shadow-sm">
        <p className="text-xs font-bold uppercase tracking-[0.18em] text-[#155D3B]">CSUCC ER MPC</p>
        <h1 className="mt-3 text-2xl font-bold text-[#0F172A]">Admin sign in</h1>
        <label className="mt-7 block text-sm font-semibold text-[#334155]" htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          autoComplete="username"
          required
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          className="mt-2 h-11 w-full border border-[#CBD5E1] px-3 text-sm outline-none focus:border-[#155D3B] focus:ring-2 focus:ring-[#155D3B]/15"
        />
        <label className="mt-5 block text-sm font-semibold text-[#334155]" htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          autoComplete="current-password"
          required
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className="mt-2 h-11 w-full border border-[#CBD5E1] px-3 text-sm outline-none focus:border-[#155D3B] focus:ring-2 focus:ring-[#155D3B]/15"
        />
        {error && <p role="alert" className="mt-4 text-sm text-red-700">{error}</p>}
        <button
          type="submit"
          disabled={isLoading}
          className="mt-7 h-11 w-full bg-[#155D3B] px-4 text-sm font-semibold text-white hover:bg-[#10482D] disabled:cursor-wait disabled:opacity-60"
        >
          {isLoading ? "Signing in..." : "Sign in"}
        </button>
      </form>
    </main>
  );
}