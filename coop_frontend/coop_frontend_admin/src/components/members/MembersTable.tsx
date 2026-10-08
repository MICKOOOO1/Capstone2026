"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Ban,
  Eye,
  KeyRound,
  MoreVertical,
  Pencil,
  ShieldCheck,
  Trash2,
  Unlock,
} from "lucide-react";
import { Member } from "./MembersData";
import RoleBadge from "./RoleBadge";
import StatusBadge from "./StatusBadge";
import MembersPagination from "./MembersPagination";
import { profile } from "@/components/profile/ProfileData";

interface MembersTableProps {
  members: Member[];
  currentPage: number;
  totalPages: number;
  totalItems: number;
  showingFrom: number;
  showingTo: number;
  onPageChange: (page: number) => void;
  onViewMember: (member: Member) => void;
  onEditMember: (member: Member) => void;
  onToggleBlockStatus: (member: Member) => void;
  onDeleteMember: (member: Member) => void;
}

interface ActionMenuState {
  idNumber: string;
  top: number;
  left: number;
}

const getDisplayIdNumber = (idNumber: string) => idNumber.replace(/^CSUCC-/, "");

export default function MembersTable({
  members,
  currentPage,
  totalPages,
  totalItems,
  showingFrom,
  showingTo,
  onPageChange,
  onViewMember,
  onEditMember,
  onToggleBlockStatus,
  onDeleteMember,
}: MembersTableProps) {
  const router = useRouter();
  const [openMenu, setOpenMenu] = useState<ActionMenuState | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const selectedMember = openMenu
    ? members.find((member) => member.idNumber === openMenu.idNumber)
    : null;

  const currentUserFullName = `${profile.firstName} ${profile.lastName}`.toLowerCase();
  const isCurrentActiveSuperAdmin = (member: Member) =>
    member.role === "Super Administrator" &&
    member.status === "Active" &&
    profile.role === "Super Administrator" &&
    profile.accountStatus === "Active" &&
    (member.idNumber === profile.id ||
      member.email.toLowerCase() === profile.email.toLowerCase() ||
      member.fullName.toLowerCase() === currentUserFullName);

  const handleResetPassword = (member: Member) => {
    window.alert(`Frontend only: password reset prepared for ${member.fullName}.`);
  };

  const handleRolePrivileges = () => {
    router.push("/settings");
  };

  const handleDeleteMember = (member: Member) => {
    const shouldDelete = window.confirm(
      `Delete ${member.fullName} from this frontend list? This will not affect any database.`
    );

    if (shouldDelete) {
      onDeleteMember(member);
    }
  };

  useEffect(() => {
    const handlePointerDown = (event: MouseEvent) => {
      const target = event.target as HTMLElement;

      if (target.closest("[data-member-action-button='true']")) {
        return;
      }

      if (menuRef.current && !menuRef.current.contains(target)) {
        setOpenMenu(null);
      }
    };

    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setOpenMenu(null);
      }
    };

    const closeOnViewportChange = () => setOpenMenu(null);

    document.addEventListener("mousedown", handlePointerDown);
    document.addEventListener("keydown", handleEscape);
    window.addEventListener("resize", closeOnViewportChange);
    window.addEventListener("scroll", closeOnViewportChange, true);

    return () => {
      document.removeEventListener("mousedown", handlePointerDown);
      document.removeEventListener("keydown", handleEscape);
      window.removeEventListener("resize", closeOnViewportChange);
      window.removeEventListener("scroll", closeOnViewportChange, true);
    };
  }, []);

  const handleActionButtonClick = (
    member: Member,
    event: React.MouseEvent<HTMLButtonElement>
  ) => {
    if (openMenu?.idNumber === member.idNumber) {
      setOpenMenu(null);
      return;
    }

    const rect = event.currentTarget.getBoundingClientRect();
    const menuWidth = 214;

    setOpenMenu({
      idNumber: member.idNumber,
      top: rect.bottom + 6,
      left: Math.max(12, Math.min(rect.right - menuWidth, window.innerWidth - menuWidth - 12)),
    });
  };

  return (
    <div className="relative">
      <div className="overflow-hidden border-t border-[#E5E7EB]">
        <table className="w-full table-fixed">
          <colgroup>
            <col className="w-[11%]" />
            <col className="w-[16%]" />
            <col className="w-[26%]" />
            <col className="w-[16%]" />
            <col className="w-[13%]" />
            <col className="w-[11%]" />
            <col className="w-[7%]" />
          </colgroup>
          <thead>
            <tr className="h-11 border-b border-[#E5E7EB] bg-[#F8FAFC]">
              <th className="px-3 text-left text-[10px] font-semibold uppercase tracking-wide text-[#64748B]">
                ID Number
              </th>
              <th className="px-3 text-left text-[10px] font-semibold uppercase tracking-wide text-[#64748B]">
                Full Name
              </th>
              <th className="px-3 text-left text-[10px] font-semibold uppercase tracking-wide text-[#64748B]">
                Email Address
              </th>
              <th className="px-3 text-left text-[10px] font-semibold uppercase tracking-wide text-[#64748B]">
                Department
              </th>
              <th className="px-3 text-center text-[10px] font-semibold uppercase tracking-wide text-[#64748B]">
                Role
              </th>
              <th className="px-3 text-center text-[10px] font-semibold uppercase tracking-wide text-[#64748B]">
                Status
              </th>
              <th className="px-3 text-center text-[10px] font-semibold uppercase tracking-wide text-[#64748B]">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            {members.length > 0 ? (
              members.map((member) => (
                <tr
                  key={member.idNumber}
                  className="h-[62px] border-b border-[#E5E7EB] transition-colors last:border-b-0 hover:bg-[#F8FAFC]"
                >
                  <td className="truncate whitespace-nowrap px-3 text-[13px] font-semibold text-[#155D3B]" title={member.idNumber}>
                    {getDisplayIdNumber(member.idNumber)}
                  </td>
                  <td className="truncate whitespace-nowrap px-3 text-[13px] font-semibold text-[#0F172A]" title={member.fullName}>
                    {member.fullName}
                  </td>
                  <td className="truncate whitespace-nowrap px-3 text-[13px] font-normal text-[#334155]" title={member.email}>
                    <a
                      href={`mailto:${member.email}`}
                      className="block truncate transition-colors hover:text-[#155D3B]"
                    >
                      {member.email}
                    </a>
                  </td>
                  <td className="truncate whitespace-nowrap px-3 text-[13px] font-normal text-[#334155]" title={member.department}>
                    {member.department}
                  </td>
                  <td className="px-3 text-center">
                    <RoleBadge role={member.role} />
                  </td>
                  <td className="px-3 text-center">
                    <StatusBadge status={member.status} />
                  </td>
                  <td className="px-3">
                    <div className="flex justify-center">
                      <button
                        type="button"
                        data-member-action-button="true"
                        onClick={(event) => handleActionButtonClick(member, event)}
                        className="flex h-[34px] w-[34px] items-center justify-center rounded-[8px] border border-[#D1D5DB] bg-white text-[#64748B] transition-colors hover:border-[#155D3B] hover:bg-[#F8FAFC] hover:text-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/20"
                        aria-label={`Open actions for ${member.fullName}`}
                        aria-expanded={openMenu?.idNumber === member.idNumber}
                      >
                        <MoreVertical className="h-[18px] w-[18px]" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={7} className="px-4 py-10 text-center text-[14px] text-[#64748B]">
                  No members found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <MembersPagination
        currentPage={currentPage}
        totalPages={totalPages}
        totalItems={totalItems}
        showingFrom={showingFrom}
        showingTo={showingTo}
        onPageChange={onPageChange}
      />

      {openMenu && selectedMember && (
        <div
          ref={menuRef}
          style={{ top: openMenu.top, left: openMenu.left }}
          className="fixed z-[60] w-[214px] rounded-[10px] border border-[#E5E7EB] bg-white py-1.5 shadow-[0_12px_30px_rgba(15,23,42,0.16)]"
          role="menu"
        >
          <button
            type="button"
            onClick={() => {
              onViewMember(selectedMember);
              setOpenMenu(null);
            }}
            className="flex w-full items-center gap-2.5 px-3 py-2 text-left text-[12px] font-medium text-[#374151] transition-colors hover:bg-[#F8FAFC] hover:text-[#155D3B]"
            role="menuitem"
          >
            <Eye className="h-4 w-4" />
            View Details
          </button>
          {isCurrentActiveSuperAdmin(selectedMember) ? (
            <button
              type="button"
              onClick={() => {
                router.push("/profile");
                setOpenMenu(null);
              }}
              className="flex w-full items-center gap-2.5 px-3 py-2 text-left text-[12px] font-medium text-[#374151] transition-colors hover:bg-[#F8FAFC] hover:text-[#155D3B]"
              role="menuitem"
            >
              <Pencil className="h-4 w-4" />
              Edit My Account
            </button>
          ) : (
            <>
              {selectedMember.role !== "Super Administrator" && (
                <>
                  <button
                    type="button"
                    onClick={() => {
                      onEditMember(selectedMember);
                      setOpenMenu(null);
                    }}
                    className="flex w-full items-center gap-2.5 px-3 py-2 text-left text-[12px] font-medium text-[#374151] transition-colors hover:bg-[#F8FAFC] hover:text-[#155D3B]"
                    role="menuitem"
                  >
                    <Pencil className="h-4 w-4" />
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      handleResetPassword(selectedMember);
                      setOpenMenu(null);
                    }}
                    className="flex w-full items-center gap-2.5 px-3 py-2 text-left text-[12px] font-medium text-[#374151] transition-colors hover:bg-[#F8FAFC] hover:text-[#155D3B]"
                    role="menuitem"
                  >
                    <KeyRound className="h-4 w-4" />
                    Reset Password
                  </button>
                </>
              )}

              {(selectedMember.role === "Administrator" ||
                selectedMember.role === "Super Administrator") && (
                <button
                  type="button"
                  onClick={() => {
                    handleRolePrivileges();
                    setOpenMenu(null);
                  }}
                  className="flex w-full items-center gap-2.5 px-3 py-2 text-left text-[12px] font-medium text-[#374151] transition-colors hover:bg-[#F8FAFC] hover:text-[#155D3B]"
                  role="menuitem"
                >
                  <ShieldCheck className="h-4 w-4" />
                  Role &amp; Privileges
                </button>
              )}

              <button
                type="button"
                onClick={() => {
                  onToggleBlockStatus(selectedMember);
                  setOpenMenu(null);
                }}
                className={`flex w-full items-center gap-2.5 px-3 py-2 text-left text-[12px] font-medium transition-colors ${
                  selectedMember.status === "Blocked"
                    ? "text-[#047857] hover:bg-[#ECFDF5] hover:text-[#155D3B]"
                    : "text-[#B91C1C] hover:bg-[#FEF2F2] hover:text-[#991B1B]"
                }`}
                role="menuitem"
              >
                {selectedMember.status === "Blocked" ? (
                  <Unlock className="h-4 w-4" />
                ) : (
                  <Ban className="h-4 w-4" />
                )}
                {selectedMember.status === "Blocked" ? "Unblock" : "Block"}
              </button>

              <div className="my-1 border-t border-[#F1F5F9]" />

              <button
                type="button"
                onClick={() => {
                  handleDeleteMember(selectedMember);
                  setOpenMenu(null);
                }}
                className="flex w-full items-center gap-2.5 px-3 py-2 text-left text-[12px] font-semibold text-[#B91C1C] transition-colors hover:bg-[#FEF2F2] hover:text-[#991B1B]"
                role="menuitem"
              >
                <Trash2 className="h-4 w-4" />
                Delete
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
}
