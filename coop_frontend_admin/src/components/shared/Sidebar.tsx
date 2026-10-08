"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import Link from "next/link";
import { useSidebar } from "@/contexts/SidebarContext";

import {
  ChevronDown,
  LayoutDashboard,
  FileText,
  Users,
  CreditCard,
  Bell,
  Megaphone,
  Folder,
  Layers3,
  BarChart3,
  ClipboardList,
  Settings,
  User,
  LogOut,
  Menu,
  type LucideIcon
} from "lucide-react";

type NavItem = {
  icon: LucideIcon;
  label: string;
  href: string;
};

type AccordionItem = {
  type: "accordion";
  id: "communication" | "system-management";
  icon: LucideIcon;
  label: string;
  children: NavItem[];
};

type NavSection = {
  label: string;
  items: Array<NavItem | AccordionItem>;
};

const navGroups: NavSection[] = [
  {
    label: "MAIN",
    items: [
      { icon: LayoutDashboard, label: "Dashboard", href: "/dashboard" },
    ],
  },
  {
    label: "LOAN MANAGEMENT",
    items: [
      { icon: FileText, label: "Loan Applications", href: "/loan-applications" },
      { icon: Users, label: "All Accounts", href: "/members" },
      { icon: CreditCard, label: "Active Loans", href: "/active-loans" },
    ],
  },
  {
    label: "COMMUNICATION",
    items: [
      {
        type: "accordion",
        id: "communication",
        icon: Bell,
        label: "Communication",
        children: [
          { icon: Bell, label: "Notifications", href: "/notifications" },
          { icon: Megaphone, label: "Announcements", href: "/announcements" },
        ],
      },
    ],
  },
  {
    label: "MANAGEMENT",
    items: [
      {
        type: "accordion",
        id: "system-management",
        icon: Folder,
        label: "System Management",
        children: [
          { icon: Folder, label: "Documents", href: "/documents" },
          { icon: Layers3, label: "Content Manager", href: "/content-manager" },
          { icon: BarChart3, label: "Reports", href: "/reports" },
          { icon: ClipboardList, label: "Audit Logs", href: "/audit-logs" },
        ],
      },
    ],
  },
  {
    label: "ACCOUNT",
    items: [
      { icon: Settings, label: "Settings", href: "/settings" },
      { icon: User, label: "My Profile", href: "/profile" },
    ],
  },
];

const bottomItems = [
  { icon: LogOut, label: "Log Out", href: "/logout" },
];

const accordionGroups = navGroups
  .flatMap((group) => group.items)
  .filter((item): item is AccordionItem =>
    "type" in item && item.type === "accordion"
  );

function isAccordionItem(item: NavItem | AccordionItem): item is AccordionItem {
  return "type" in item && item.type === "accordion";
}

function getActiveAccordionGroup(pathname: string) {
  return accordionGroups.find((group) =>
    group.children.some((child) => child.href === pathname)
  )?.id ?? null;
}

export default function Sidebar() {
  const pathname = usePathname();
  const { isCollapsed, toggleSidebar } = useSidebar();
  const [openGroup, setOpenGroup] = useState<string | null>(() =>
    getActiveAccordionGroup(pathname)
  );

  useEffect(() => {
    const activeGroup = getActiveAccordionGroup(pathname);

    if (activeGroup) {
      setOpenGroup(activeGroup);
    }
  }, [pathname]);

  const navItemClass = (isActive: boolean, isChild = false) =>
    `flex h-9 items-center rounded-[8px] transition-all duration-200 ${
      isActive
        ? "bg-white text-[#155D3B]"
        : "text-white/90 hover:bg-white/10"
    } ${
      isCollapsed
        ? "justify-center px-0"
        : isChild
          ? "gap-2.5 px-3 pl-7"
          : "gap-3 px-3"
    }`;

  return (
    <aside className={`fixed left-0 top-0 z-20 flex h-screen flex-col overflow-hidden bg-[#155D3B] text-white transition-all duration-300 ${
      isCollapsed ? "w-[76px]" : "w-64"
    }`}>
      {/* Header */}
      <div className={`flex h-[70px] shrink-0 items-center border-b border-white/10 ${
        isCollapsed ? "justify-center px-0" : "justify-between px-6"
      }`}>
        {!isCollapsed && (
          <h1 className="text-[11px] font-bold uppercase leading-none tracking-[6px] text-[#E7C84B]">
            CSUCC MPC
          </h1>
        )}
        <button
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[8px] border border-white/10 bg-white/[0.04] text-[#E7C84B] transition-colors hover:bg-white/10"
          onClick={toggleSidebar}
          aria-label="Toggle sidebar"
        >
          <Menu className="h-[22px] w-[22px]" strokeWidth={2.4} />
        </button>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto px-4 py-3">
        <div className="space-y-3">
          {navGroups.map((group) => (
            <section key={group.label} className="space-y-2">
              {!isCollapsed && (
                <h2 className="px-1 text-[11px] font-bold uppercase leading-none text-white/55">
                  {group.label}
                </h2>
              )}
              <ul className="space-y-1">
                {group.items.map((item) => (
                  <li key={item.label}>
                    {isAccordionItem(item) ? (
                      <>
                        <button
                          type="button"
                          onClick={() =>
                            setOpenGroup((current) =>
                              current === item.id ? null : item.id
                            )
                          }
                          className={`flex h-9 w-full items-center rounded-[8px] text-white/90 transition-all duration-200 hover:bg-white/10 ${
                            isCollapsed ? "justify-center px-0" : "gap-3 px-3"
                          }`}
                          aria-expanded={openGroup === item.id}
                        >
                          <span className="flex h-5 w-6 shrink-0 items-center justify-center">
                            <item.icon size={18} strokeWidth={2} />
                          </span>
                          {!isCollapsed && (
                            <>
                              <span className="min-w-0 flex-1 text-left text-[15px] font-bold leading-none">
                                {item.label}
                              </span>
                              <ChevronDown
                                className={`h-4 w-4 shrink-0 transition-transform duration-200 ${
                                  openGroup === item.id ? "rotate-0" : "-rotate-90"
                                }`}
                                strokeWidth={2.2}
                              />
                            </>
                          )}
                        </button>
                        {openGroup === item.id && (
                          <ul className={`mt-1 space-y-1 ${isCollapsed ? "" : "pl-0"}`}>
                            {item.children.map((child) => (
                              <li key={child.label}>
                                <Link
                                  href={child.href}
                                  className={navItemClass(pathname === child.href, true)}
                                >
                                  <span className="flex h-5 w-6 shrink-0 items-center justify-center">
                                    <child.icon size={isCollapsed ? 18 : 16} strokeWidth={2} />
                                  </span>
                                  {!isCollapsed && (
                                    <span className="text-[14px] font-semibold leading-none">
                                      {child.label}
                                    </span>
                                  )}
                                </Link>
                              </li>
                            ))}
                          </ul>
                        )}
                      </>
                    ) : (
                      <Link
                        href={item.href}
                        className={navItemClass(pathname === item.href)}
                      >
                        <span className="flex h-5 w-6 shrink-0 items-center justify-center">
                          <item.icon size={18} strokeWidth={2} />
                        </span>
                        {!isCollapsed && <span className="text-[15px] font-bold leading-none">{item.label}</span>}
                      </Link>
                    )}
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      </nav>

      {/* Bottom Section */}
      <div className="mt-auto shrink-0 px-4 pb-5">
        <div className="mb-5 border-t border-white/10" />
        <ul className="space-y-1">
          {bottomItems.map((item) => (
            <li key={item.label}>
              <Link
                href={item.href}
                className={navItemClass(pathname === item.href)}
              >
                <span className="flex h-5 w-6 shrink-0 items-center justify-center">
                  <item.icon size={18} strokeWidth={2} />
                </span>
                {!isCollapsed && <span className="text-[15px] font-bold leading-none">{item.label}</span>}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </aside>
  );
}
