"use client";

import { useMemo, useState } from "react";
import MemberToolbar from "@/components/members/MemberToolbar";
import MembersTable from "@/components/members/MembersTable";
import MemberDetailsModal from "@/components/members/MemberDetailsModal";
import MemberFormModal from "@/components/members/MemberFormModal";
import {
  Member,
  MemberRoleFilter,
  MemberSortOption,
  MemberStatusFilter,
  mockMembers,
} from "@/components/members/MembersData";

interface AppliedFilters {
  search: string;
  memberId: string;
  role: MemberRoleFilter;
  status: MemberStatusFilter;
}

const normalizeFilterValue = (value: string) => value.trim().toLowerCase();

export default function MembersPage() {
  const [members, setMembers] = useState<Member[]>(mockMembers);
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

  const toggleMemberBlockStatus = (member: Member) => {
    const nextStatus = member.status === "Blocked" ? "Active" : "Blocked";

    setMembers((currentMembers) =>
      currentMembers.map((currentMember) =>
        currentMember.idNumber === member.idNumber
          ? { ...currentMember, status: nextStatus }
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
