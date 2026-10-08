"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import MemberToolbar from "@/components/members/MemberToolbar";
import MembersTable from "@/components/members/MembersTable";
import MemberDetailsModal from "@/components/members/MemberDetailsModal";
import MemberFormModal from "@/components/members/MemberFormModal";
import { fetchMembers, updateMemberStatus } from "@/lib/api";
import { getSupabaseClient } from "@/lib/supabase";
import {
  Member,
  MemberRoleFilter,
  MemberSortOption,
  MemberStatusFilter,
} from "@/components/members/MembersData";

interface AppliedFilters {
  search: string;
  memberId: string;
  role: MemberRoleFilter;
  status: MemberStatusFilter;
}

const normalizeFilterValue = (value: string) => value.trim().toLowerCase();

export default function MembersPage() {
  const [members, setMembers] = useState<Member[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [searchInput, setSearchInput] = useState("");
  const [memberIdInput, setMemberIdInput] = useState("");
  const [filters, setFilters] = useState<AppliedFilters>({
    search: "",
    memberId: "",
    role: "All Roles",
    status: "All Status",
  });
  const [pageSize, setPageSize] = useState(10);
  const [sortOption, setSortOption] = useState<MemberSortOption>("Newest");
  const [currentPage, setCurrentPage] = useState(1);
  const [viewedMember, setViewedMember] = useState<Member | null>(null);
  const [memberForm, setMemberForm] = useState<{
    mode: "add" | "edit";
    member: Member | null;
  } | null>(null);

  const loadMembers = useCallback(async () => {
    try {
      const data = await fetchMembers();
      setMembers(data);
      setLoadError("");
    } catch (error) {
      console.error("Failed to load members:", error);
      setMembers([]);
      setLoadError(error instanceof Error ? error.message : "Unable to load members.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const request = window.setTimeout(() => void loadMembers(), 0);
    return () => window.clearTimeout(request);
  }, [loadMembers]);

  useEffect(() => {
    const client = getSupabaseClient();
    const channel = client
      .channel("admin-members")
      .on("postgres_changes", { event: "*", schema: "public", table: "members" }, () => {
        void loadMembers();
      })
      .subscribe();

    return () => {
      void client.removeChannel(channel);
    };
  }, [loadMembers]);

  const filteredMembers = useMemo(() => {
    const search = normalizeFilterValue(filters.search);
    const memberId = normalizeFilterValue(filters.memberId);

    return members.filter((member) => {
      if (member.status === "Pending") {
        return false;
      }

      const searchableText = [
        member.fullName,
        member.email,
        member.department,
      ]
        .join(" ")
        .toLowerCase();

      const matchesSearch = search === "" || searchableText.includes(search);
      const matchesMemberId =
        memberId === "" || member.idNumber.toLowerCase().includes(memberId);
      const matchesRole =
        filters.role === "All Roles" || member.role === filters.role;
      const matchesStatus =
        filters.status === "All Status" || member.status === filters.status;

      return matchesSearch && matchesMemberId && matchesRole && matchesStatus;
    });
  }, [members, filters]);

  const sortedMembers = useMemo(() => {
    return [...filteredMembers].sort((firstMember, secondMember) => {
      if (sortOption === "Name A-Z") {
        return firstMember.fullName.localeCompare(secondMember.fullName);
      }

      if (sortOption === "Name Z-A") {
        return secondMember.fullName.localeCompare(firstMember.fullName);
      }

      const firstDate = Date.parse(firstMember.createdAt);
      const secondDate = Date.parse(secondMember.createdAt);

      return sortOption === "Newest"
        ? secondDate - firstDate
        : firstDate - secondDate;
    });
  }, [filteredMembers, sortOption]);

  const totalPages = Math.max(1, Math.ceil(sortedMembers.length / pageSize));
  const activePage = Math.min(currentPage, totalPages);
  const pageStartIndex = (activePage - 1) * pageSize;
  const paginatedMembers = sortedMembers.slice(
    pageStartIndex,
    pageStartIndex + pageSize
  );
  const showingFrom = sortedMembers.length === 0 ? 0 : pageStartIndex + 1;
  const showingTo = Math.min(pageStartIndex + pageSize, sortedMembers.length);
  const showClearButton =
    filters.search.trim() !== "" || filters.memberId.trim() !== "";

  const applyTextFilters = () => {
    setFilters((current) => ({
      ...current,
      search: searchInput,
      memberId: memberIdInput,
    }));
    setCurrentPage(1);
  };

  const updateRoleFilter = (role: MemberRoleFilter) => {
    setFilters((current) => ({ ...current, role }));
    setCurrentPage(1);
  };

  const updateStatusFilter = (status: MemberStatusFilter) => {
    setFilters((current) => ({ ...current, status }));
    setCurrentPage(1);
  };

  const updateSortOption = (sort: MemberSortOption) => {
    setSortOption(sort);
    setCurrentPage(1);
  };

  const updatePageSize = (size: number) => {
    setPageSize(size);
    setCurrentPage(1);
  };

  const clearMemberControls = () => {
    setSearchInput("");
    setMemberIdInput("");
    setFilters({
      search: "",
      memberId: "",
      role: "All Roles",
      status: "All Status",
    });
    setSortOption("Newest");
    setCurrentPage(1);
  };

  const toggleMemberBlockStatus = async (member: Member) => {
    const nextStatus = member.status === "Blocked" ? "Active" : "Blocked";

    const updatedMember = await updateMemberStatus(member.idNumber, nextStatus);
    setMembers((currentMembers) =>
      currentMembers.map((currentMember) =>
        currentMember.idNumber === member.idNumber
          ? updatedMember
          : currentMember
      )
    );
  };

  const deleteMember = (member: Member) => {
    setMembers((currentMembers) =>
      currentMembers.filter(
        (currentMember) => currentMember.idNumber !== member.idNumber
      )
    );
    setCurrentPage(1);
  };

  const saveMember = (member: Member) => {
    if (memberForm?.mode === "edit" && memberForm.member) {
      setMembers((currentMembers) =>
        currentMembers.map((currentMember) =>
        currentMember.idNumber === memberForm.member?.idNumber
            ? member
            : currentMember
        )
      );
    } else {
      setMembers((currentMembers) => [
        { ...member, createdAt: new Date().toISOString() },
        ...currentMembers,
      ]);
    }

    setMemberForm(null);
    setCurrentPage(1);
  };

  return (
    <>
      <div className="overflow-hidden rounded-[8px] border border-[#E1E7EF] bg-white shadow-[0_1px_3px_rgba(15,23,42,0.08)]">
        <MemberToolbar
          searchValue={searchInput}
          memberIdValue={memberIdInput}
          roleFilter={filters.role}
          statusFilter={filters.status}
          sortOption={sortOption}
          pageSize={pageSize}
          showClear={showClearButton}
          onSearchChange={setSearchInput}
          onMemberIdChange={setMemberIdInput}
          onApplyFilters={applyTextFilters}
          onClearFilters={clearMemberControls}
          onRoleFilterChange={updateRoleFilter}
          onStatusFilterChange={updateStatusFilter}
          onSortChange={updateSortOption}
          onPageSizeChange={updatePageSize}
          onAddMember={() => setMemberForm({ mode: "add", member: null })}
        />

        {loading && (
          <div className="border-t border-[#E5E7EB] px-4 py-6 text-center text-[14px] text-[#64748B]">
            Loading members from database...
          </div>
        )}

        {loadError && !loading && (
          <div className="border-t border-[#FECACA] bg-[#FEF2F2] px-4 py-3 text-[13px] font-medium text-[#B91C1C]">
            {loadError}
          </div>
        )}

        {!loading && !loadError && (
          <MembersTable
            members={paginatedMembers}
            currentPage={activePage}
            totalPages={totalPages}
            totalItems={sortedMembers.length}
            showingFrom={showingFrom}
            showingTo={showingTo}
            onPageChange={setCurrentPage}
            onViewMember={setViewedMember}
            onEditMember={(member) => setMemberForm({ mode: "edit", member })}
            onToggleBlockStatus={toggleMemberBlockStatus}
            onDeleteMember={deleteMember}
          />
        )}
      </div>

      <MemberDetailsModal
        member={viewedMember}
        onClose={() => setViewedMember(null)}
      />

      {memberForm && (
        <MemberFormModal
          key={`${memberForm.mode}-${memberForm.member?.idNumber ?? "new"}`}
          mode={memberForm.mode}
          member={memberForm.member}
          onClose={() => setMemberForm(null)}
          onSubmit={saveMember}
        />
      )}
    </>
  );
}
