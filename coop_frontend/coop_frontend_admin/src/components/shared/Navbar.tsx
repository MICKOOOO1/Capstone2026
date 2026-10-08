"use client";

import { usePathname, useRouter } from "next/navigation";
import { Bell, CalendarDays, LogOut } from "lucide-react";
import { useSidebar } from "@/contexts/SidebarContext";
import { profile } from "@/components/profile/ProfileData";
import { getSupabaseClient } from "@/lib/supabase";

const pageHeaders: Record<string, { title: string; subtitle: string }> = {
  "/dashboard": {
    title: "Dashboard",
    subtitle: "Overview of cooperative activities and system information",
  },
  "/loan-applications": {
    title: "Loan Applications",
    subtitle: "Review and manage member loan applications",
  },
  "/members": {
    title: "All Accounts",
    subtitle: "Manage member and administrator accounts",
  },
  "/active-loans": {
    title: "Active Loans",
    subtitle: "Monitor and manage active member loans",
  },
  "/notifications": {
    title: "Notifications",
    subtitle: "View and manage system notifications",
  },
  "/announcements": {
    title: "Announcements",
    subtitle: "Create and manage cooperative announcements",
  },
  "/documents": {
    title: "Documents",
    subtitle: "Manage cooperative and member documents",
  },
  "/content-manager": {
    title: "Content Manager",
    subtitle: "Manage system content and information",
  },
  "/reports": {
    title: "Reports",
    subtitle: "View and generate cooperative reports",
  },
  "/audit-logs": {
    title: "Audit Logs",
    subtitle: "Review system activities and account actions",
  },
  "/settings": {
    title: "Settings",
    subtitle: "Manage system settings and preferences",
  },
  "/profile": {
    title: "My Profile",
    subtitle: "View and manage your account information",
  },
};

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const { isCollapsed } = useSidebar();
  const pageHeader = pageHeaders[pathname] ?? pageHeaders["/dashboard"];

  const currentDate = new Date().toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
  const initials = `${profile.firstName[0] ?? ""}${profile.lastName[0] ?? ""}`;

  return (
    <header className={`fixed top-0 right-0 z-10 flex h-[72px] items-center justify-between border-b border-[#E5E7EB] bg-white px-7 transition-all duration-300 ${
      isCollapsed ? "left-[76px]" : "left-64"
    }`}>
      {/* Left Section */}
      <div>
        <h1 className="text-[20px] font-bold leading-none text-[#0F172A]">
          {pageHeader.title}
        </h1>
        <p className="mt-1 text-[13px] font-medium leading-none text-[#64748B]">
          {pageHeader.subtitle}
        </p>
      </div>

      {/* Right Section */}
      <div className="flex items-center gap-3">
        <div className="flex h-8 items-center gap-1.5 rounded-full border border-[#D1D5DB] bg-white px-3 text-[13px] font-semibold text-[#334155]">
          <CalendarDays className="h-[14px] w-[14px] text-[#155D3B]" strokeWidth={2.3} />
          <span>{currentDate}</span>
        </div>

        {/* Notification */}
        <button
          onClick={() => router.push('/notifications')}
          className="relative flex h-8 w-8 items-center justify-center rounded-full border border-[#E5E7EB] transition-all hover:border-[#166534] hover:bg-[#F5F6F8] hover:shadow-sm"
          aria-label="Open notifications"
        >
          <Bell className="h-[15px] w-[15px] text-[#6B7280] transition-colors hover:text-[#166534]" />
          <span className="absolute right-[7px] top-[6px] h-2 w-2 rounded-full border border-white bg-[#EF4444]"></span>
        </button>

        <button
          type="button"
          onClick={async () => {
            await getSupabaseClient().auth.signOut();
            router.replace("/login");
          }}
          className="flex h-8 w-8 items-center justify-center rounded-full border border-[#E5E7EB] text-[#64748B] hover:bg-[#F5F6F8] hover:text-[#155D3B]"
          aria-label="Sign out"
          title="Sign out"
        >
          <LogOut className="h-4 w-4" />
        </button>

        {/* User Profile */}
        <div className="flex items-center gap-2.5 pl-1">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[#155D3B]">
            <span className="text-[12px] font-bold text-white">{initials}</span>
          </div>
          <div>
            <p className="text-[14px] font-bold leading-none text-[#0F172A]">
              {profile.firstName} {profile.lastName}
            </p>
            <p className="mt-0.5 text-[11px] font-semibold leading-none text-[#155D3B]">
              {profile.role}
            </p>
          </div>
        </div>
      </div>
    </header>
  );
}
