"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { Session } from "@supabase/supabase-js";
import Sidebar from "@/components/shared/Sidebar";
import Navbar from "@/components/shared/Navbar";
import { SidebarProvider, useSidebar } from "@/contexts/SidebarContext";
import { getSupabaseClient } from "@/lib/supabase";

function AdminContent({ children }: { children: React.ReactNode }) {
  const { isCollapsed } = useSidebar();

  return (
    <main className={`transition-all duration-300 ${
      isCollapsed ? "ml-[76px]" : "ml-64"
    } mt-[72px] px-9 py-7`}>
      {children}
    </main>
  );
}

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [isCheckingAccess, setIsCheckingAccess] = useState(true);
  const [isAuthorized, setIsAuthorized] = useState(false);

  useEffect(() => {
    let active = true;
    const supabase = getSupabaseClient();
    const applySession = (session: Session | null) => {
      if (!active) return;
      const authorized = session?.user.app_metadata.role === "coop_admin";
      setIsAuthorized(authorized);
      setIsCheckingAccess(false);
      if (!authorized) router.replace("/login");
    };

    void supabase.auth.getSession().then(({ data }) => applySession(data.session));
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      applySession(session);
    });

    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, [router]);

  if (isCheckingAccess || !isAuthorized) {
    return <div className="min-h-screen bg-[#F5F6F8]" aria-busy="true" />;
  }

  return (
    <SidebarProvider>
      <div className="min-h-screen bg-[#F5F6F8]">
        <Sidebar />
        <Navbar />
        <AdminContent>{children}</AdminContent>
      </div>
    </SidebarProvider>
  );
}
