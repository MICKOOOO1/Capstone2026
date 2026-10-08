"use client";

import { FormEvent, useMemo, useState } from "react";
import { X } from "lucide-react";
import { Member, memberRoles, memberStatuses } from "./MembersData";

interface MemberFormModalProps {
  mode: "add" | "edit";
  member: Member | null;
  onClose: () => void;
  onSubmit: (member: Member) => void;
}

const emptyMember: Member = {
  idNumber: "",
  fullName: "",
  email: "",
  department: "",
  role: "Member",
  status: "Active",
  createdAt: "",
};

export default function MemberFormModal({
  mode,
  member,
  onClose,
  onSubmit,
}: MemberFormModalProps) {
  const [formData, setFormData] = useState<Member>(member ?? emptyMember);
  const availableStatuses = memberStatuses.filter(
    (status) => formData.role === "Super Administrator" || status !== "Inactive"
  );

  const isComplete = useMemo(
    () =>
      formData.idNumber.trim() !== "" &&
      formData.fullName.trim() !== "" &&
      formData.email.trim() !== "" &&
      formData.department.trim() !== "",
    [formData]
  );

  const updateField = (field: keyof Member, value: string) => {
    setFormData((current) => {
      if (field === "role") {
        const nextRole = value as Member["role"];

        return {
          ...current,
          role: nextRole,
          status:
            nextRole === "Super Administrator" || current.status !== "Inactive"
              ? current.status
              : "Active",
        };
      }

      if (field === "status") {
        if (value === "Inactive" && current.role !== "Super Administrator") {
          return current;
        }

        return { ...current, status: value as Member["status"] };
      }

      return { ...current, [field]: value } as Member;
    });
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (!isComplete) {
      return;
    }

    onSubmit({
      ...formData,
      idNumber: formData.idNumber.trim(),
      fullName: formData.fullName.trim(),
      email: formData.email.trim(),
      department: formData.department.trim(),
    });
  };

  return (
    <div
      className="fixed inset-0 z-[80] flex items-center justify-center bg-[#111827]/40 px-4"
      onMouseDown={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="member-form-title"
    >
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-[540px] rounded-[14px] border border-[#E5E7EB] bg-white shadow-[0_24px_60px_rgba(15,23,42,0.24)]"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b border-[#E5E7EB] px-5 py-4">
          <div>
            <h2 id="member-form-title" className="text-[15px] font-bold text-[#1F2937]">
              {mode === "add" ? "Create Account" : "Edit Member"}
            </h2>
            <p className="mt-0.5 text-[12px] text-[#6B7280]">
              {mode === "add" ? "Create a temporary frontend account." : formData.idNumber}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-full text-[#6B7280] transition-colors hover:bg-[#F1F5F9] hover:text-[#155D3B]"
            aria-label="Close member form"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="grid gap-3 px-5 py-4 md:grid-cols-2">
          <label className="space-y-1.5">
            <span className="text-[12px] font-semibold text-[#374151]">ID Number</span>
            <input
              name="idNumber"
              type="text"
              value={formData.idNumber}
              onChange={(event) => updateField("idNumber", event.target.value)}
              className="h-[38px] w-full rounded-[10px] border border-[#D1D5DB] px-3 text-[13px] text-[#1F2937] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
            />
          </label>
          <label className="space-y-1.5">
            <span className="text-[12px] font-semibold text-[#374151]">Full Name</span>
            <input
              name="fullName"
              type="text"
              value={formData.fullName}
              onChange={(event) => updateField("fullName", event.target.value)}
              className="h-[38px] w-full rounded-[10px] border border-[#D1D5DB] px-3 text-[13px] text-[#1F2937] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
            />
          </label>
          <label className="space-y-1.5">
            <span className="text-[12px] font-semibold text-[#374151]">Email Address</span>
            <input
              name="email"
              type="email"
              value={formData.email}
              onChange={(event) => updateField("email", event.target.value)}
              className="h-[38px] w-full rounded-[10px] border border-[#D1D5DB] px-3 text-[13px] text-[#1F2937] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
            />
          </label>
          <label className="space-y-1.5">
            <span className="text-[12px] font-semibold text-[#374151]">Department</span>
            <input
              name="department"
              type="text"
              value={formData.department}
              onChange={(event) => updateField("department", event.target.value)}
              className="h-[38px] w-full rounded-[10px] border border-[#D1D5DB] px-3 text-[13px] text-[#1F2937] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
            />
          </label>
          <label className="space-y-1.5">
            <span className="text-[12px] font-semibold text-[#374151]">Role</span>
            <select
              name="role"
              value={formData.role}
              onChange={(event) => updateField("role", event.target.value)}
              className="h-[38px] w-full rounded-[10px] border border-[#D1D5DB] bg-white px-3 text-[13px] text-[#1F2937] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
            >
              {memberRoles.map((role) => (
                <option key={role} value={role}>
                  {role}
                </option>
              ))}
            </select>
          </label>
          <label className="space-y-1.5">
            <span className="text-[12px] font-semibold text-[#374151]">Status</span>
            <select
              name="status"
              value={formData.status}
              onChange={(event) => updateField("status", event.target.value)}
              className="h-[38px] w-full rounded-[10px] border border-[#D1D5DB] bg-white px-3 text-[13px] text-[#1F2937] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
            >
              {availableStatuses.map((status) => (
                <option key={status} value={status}>
                  {status}
                </option>
              ))}
            </select>
          </label>
        </div>

        <div className="flex justify-end gap-2 border-t border-[#E5E7EB] px-5 py-4">
          <button
            type="button"
            onClick={onClose}
            className="h-[36px] rounded-[10px] border border-[#D1D5DB] bg-white px-4 text-[13px] font-semibold text-[#374151] transition-colors hover:bg-[#F9FAFB]"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={!isComplete}
            className="h-[36px] rounded-[10px] bg-[#155D3B] px-4 text-[13px] font-semibold text-white transition-colors hover:bg-[#134A30] disabled:cursor-not-allowed disabled:bg-[#9CA3AF]"
          >
            {mode === "add" ? "Create Account" : "Save Changes"}
          </button>
        </div>
      </form>
    </div>
  );
}
