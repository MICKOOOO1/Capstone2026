"use client";

import { useMemo, useState } from "react";
import { Calendar, ChevronDown, Search, Send, X } from "lucide-react";
import { Member, mockMembers } from "@/components/members/MembersData";
import NotificationTypePills from "./NotificationTypePills";

type RecipientTarget =
  | "allMembers"
  | "activeLoanMembers"
  | "specificMember"
  | "selectedMembers";

const recipientOptions: Array<{
  value: RecipientTarget;
  label: string;
  count: number;
  countLabel?: string;
}> = [
  { value: "allMembers", label: "All Members", count: 1284 },
  { value: "activeLoanMembers", label: "Active Loan Members", count: 342 },
  { value: "specificMember", label: "Specific Member", count: 0 },
  { value: "selectedMembers", label: "Selected Members", count: 0, countLabel: "0 selected members" },
];

const controlBase =
  "h-10 rounded-[8px] border border-[#D1D5DB] bg-white text-[14px] font-medium text-[#0F172A] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15";
const labelBase =
  "mb-1.5 block text-[11px] font-bold uppercase tracking-wide text-[#64748B]";
const primaryButtonBase =
  "inline-flex h-10 shrink-0 items-center justify-center rounded-[8px] bg-[#155D3B] text-[14px] font-bold text-white transition-colors hover:bg-[#134A30] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/25 disabled:cursor-not-allowed disabled:bg-[#94A3B8]";

const getDisplayIdNumber = (idNumber: string) => idNumber.replace(/^CSUCC-/, "");
const normalizeSearch = (value: string) => value.trim().toLowerCase();

export default function SendNotificationCard() {
  const [selectedType, setSelectedType] = useState("Information");
  const [sendTo, setSendTo] = useState<RecipientTarget>("allMembers");
  const [memberSearch, setMemberSearch] = useState("");
  const [selectedMember, setSelectedMember] = useState<Member | null>(null);
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [schedule, setSchedule] = useState("");
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);

  const selectedRecipientOption = recipientOptions.find((option) => option.value === sendTo) ?? recipientOptions[0];
  const isSpecificMember = sendTo === "specificMember";
  const recipientCount = isSpecificMember
    ? selectedMember
      ? 1
      : 0
    : selectedRecipientOption.count;
  const recipientSummary = isSpecificMember
    ? selectedMember
      ? "1 member"
      : "Select 1 member"
    : selectedRecipientOption.countLabel ?? `${recipientCount.toLocaleString()} members`;
  const canSend = title.trim() !== "" && message.trim() !== "" && recipientCount > 0;

  const matchingMembers = useMemo(() => {
    const query = normalizeSearch(memberSearch);

    if (!query || selectedMember) {
      return [];
    }

    return mockMembers
      .filter((member) => {
        const memberText = [
          member.fullName,
          member.email,
          member.idNumber,
          getDisplayIdNumber(member.idNumber),
        ]
          .join(" ")
          .toLowerCase();

        return memberText.includes(query);
      })
      .slice(0, 5);
  }, [memberSearch, selectedMember]);

  const handleRecipientChange = (value: RecipientTarget) => {
    setSendTo(value);

    if (value !== "specificMember") {
      setMemberSearch("");
      setSelectedMember(null);
    }
  };

  const handleSelectMember = (member: Member) => {
    setSelectedMember(member);
    setMemberSearch(member.fullName);
  };

  const clearSelectedMember = () => {
    setSelectedMember(null);
    setMemberSearch("");
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (canSend) {
      setIsConfirmOpen(true);
    }
  };

  const handleConfirmSend = () => {
    setIsConfirmOpen(false);
    window.alert("Frontend only: notification sending is ready for backend integration.");
  };

  return (
    <>
      <form
        onSubmit={handleSubmit}
        className="overflow-hidden rounded-[8px] border border-[#E1E7EF] bg-white shadow-[0_1px_3px_rgba(15,23,42,0.08)]"
      >
        <div className="border-b border-[#E5E7EB] px-6 py-4">
          <h2 className="text-[18px] font-semibold leading-6 text-[#0F172A]">
            Send Notification
          </h2>
        </div>

        <div className="space-y-4 px-6 py-5">
          <div>
            <label className={labelBase} htmlFor="notification-recipient">
              Send To
            </label>
            <div className="relative">
              <select
                id="notification-recipient"
                value={sendTo}
                onChange={(event) => handleRecipientChange(event.target.value as RecipientTarget)}
                className={`${controlBase} w-full appearance-none px-4 pr-10`}
              >
                {recipientOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
              <ChevronDown className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#64748B]" />
            </div>
            <p className="mt-1.5 text-[12px] font-medium text-[#64748B]">
              Recipients: {recipientSummary}
            </p>
          </div>

          {isSpecificMember && (
            <div className="rounded-[8px] border border-[#E5E7EB] bg-[#F8FAFC] p-3">
              <label className={labelBase} htmlFor="specific-member-search">
                Search Member
              </label>
              <div className="relative">
                <Search className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#94A3B8]" />
                <input
                  id="specific-member-search"
                  type="text"
                  value={memberSearch}
                  onChange={(event) => {
                    setMemberSearch(event.target.value);
                    setSelectedMember(null);
                  }}
                  placeholder="Search by ID Number or member name..."
                  className={`${controlBase} w-full pl-11 pr-4 placeholder:text-[#64748B]`}
                />
              </div>

              {matchingMembers.length > 0 && (
                <div className="mt-2 overflow-hidden rounded-[8px] border border-[#E5E7EB] bg-white">
                  {matchingMembers.map((member) => (
                    <button
                      key={member.idNumber}
                      type="button"
                      onClick={() => handleSelectMember(member)}
                      className="flex w-full items-center justify-between gap-3 border-b border-[#F1F5F9] px-3 py-2 text-left transition-colors last:border-b-0 hover:bg-[#F8FAFC]"
                    >
                      <span>
                        <span className="block text-[13px] font-semibold text-[#0F172A]">
                          {member.fullName}
                        </span>
                        <span className="block text-[12px] font-medium text-[#64748B]">
                          {getDisplayIdNumber(member.idNumber)}
                        </span>
                      </span>
                      <span className="truncate text-[12px] text-[#64748B]">
                        {member.email}
                      </span>
                    </button>
                  ))}
                </div>
              )}

              {memberSearch && !selectedMember && matchingMembers.length === 0 && (
                <p className="mt-2 text-[12px] font-medium text-[#64748B]">
                  No matching members found.
                </p>
              )}

              {selectedMember && (
                <div className="mt-3 rounded-[8px] border border-[#BBF7D0] bg-white p-3">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="text-[11px] font-bold uppercase tracking-wide text-[#64748B]">
                        Selected Member
                      </p>
                      <p className="mt-1 text-[13px] font-semibold text-[#155D3B]">
                        {getDisplayIdNumber(selectedMember.idNumber)}
                      </p>
                      <p className="text-[14px] font-semibold text-[#0F172A]">
                        {selectedMember.fullName}
                      </p>
                      <p className="text-[12px] text-[#64748B]">
                        {selectedMember.email}
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={clearSelectedMember}
                      className="flex h-7 w-7 items-center justify-center rounded-[7px] border border-[#D1D5DB] bg-white text-[#64748B] transition-colors hover:border-[#155D3B] hover:text-[#155D3B]"
                      aria-label="Clear selected member"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          <div>
            <label className={labelBase}>Notification Type</label>
            <NotificationTypePills
              selectedType={selectedType}
              onTypeChange={setSelectedType}
            />
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div className="md:col-span-2">
              <label className={labelBase} htmlFor="notification-title">
                Title
              </label>
              <input
                id="notification-title"
                type="text"
                value={title}
                onChange={(event) => setTitle(event.target.value)}
                placeholder="Enter notification title..."
                className={`${controlBase} w-full px-4 placeholder:text-[#64748B]`}
              />
            </div>

            <div className="md:col-span-2">
              <label className={labelBase} htmlFor="notification-message">
                Message
              </label>
              <textarea
                id="notification-message"
                value={message}
                onChange={(event) => setMessage(event.target.value)}
                placeholder="Write your notification message..."
                rows={4}
                className="min-h-[104px] w-full resize-none rounded-[8px] border border-[#D1D5DB] bg-white px-4 py-3 text-[14px] font-medium text-[#0F172A] placeholder:text-[#64748B] focus:border-[#155D3B] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
              />
            </div>
          </div>

          <div>
            <label className={labelBase} htmlFor="notification-schedule">
              Schedule (Optional)
            </label>
            <div className="relative">
              <input
                id="notification-schedule"
                type="datetime-local"
                value={schedule}
                onChange={(event) => setSchedule(event.target.value)}
                className={`${controlBase} w-full px-4 pr-10`}
              />
              <Calendar className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#64748B]" />
            </div>
            <p className="mt-1.5 text-[12px] font-medium text-[#64748B]">
              Leave empty to send immediately.
            </p>
          </div>
        </div>

        <div className="flex items-center justify-end border-t border-[#E5E7EB] px-6 py-4">
          <button
            type="submit"
            disabled={!canSend}
            className={`${primaryButtonBase} gap-2.5 px-5`}
          >
            <Send className="h-4 w-4" />
            Send Notification
          </button>
        </div>
      </form>

      {isConfirmOpen && (
        <div
          className="fixed inset-0 z-[80] flex items-center justify-center bg-[#0F172A]/35 px-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby="send-notification-dialog-title"
        >
          <div className="w-full max-w-[420px] rounded-[10px] border border-[#E5E7EB] bg-white shadow-[0_18px_45px_rgba(15,23,42,0.22)]">
            <div className="border-b border-[#E5E7EB] px-5 py-4">
              <h3
                id="send-notification-dialog-title"
                className="text-[18px] font-semibold leading-6 text-[#0F172A]"
              >
                Send Notification?
              </h3>
              <p className="mt-1 text-[13px] font-medium leading-5 text-[#64748B]">
                This notification will be sent to {recipientSummary}.
              </p>
            </div>
            <div className="flex items-center justify-end gap-2 px-5 py-4">
              <button
                type="button"
                onClick={() => setIsConfirmOpen(false)}
                className="inline-flex h-10 items-center justify-center rounded-[8px] border border-[#D1D5DB] bg-white px-4 text-[14px] font-bold text-[#374151] transition-colors hover:bg-[#F8FAFC] focus:outline-none focus:ring-2 focus:ring-[#155D3B]/15"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmSend}
                className={`${primaryButtonBase} px-5`}
              >
                Send Notification
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
