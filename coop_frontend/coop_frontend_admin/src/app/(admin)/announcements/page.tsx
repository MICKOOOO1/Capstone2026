"use client";

import { useState } from "react";
import { Search, Plus } from "lucide-react";
import AnnouncementCard from "@/components/announcements/AnnouncementCard";
import { announcements } from "@/components/announcements/AnnouncementsData";

export default function AnnouncementsPage() {
  const [searchQuery, setSearchQuery] = useState("");

  const filteredAnnouncements = announcements.filter((announcement) =>
    announcement.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    announcement.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="px-4 py-4">
      {/* Search and Action Bar */}
      <div className="flex items-center justify-between mb-3">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 text-[#6B7280] w-3.5 h-3.5" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search announcements..."
            className="w-[180px] h-[36px] pl-9 pr-3 bg-white border border-[#E5E7EB] rounded-[9999px] text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:outline-none focus:ring-2 focus:ring-[#166534]/20"
          />
        </div>

        {/* New Announcement Button */}
        <button className="flex items-center gap-2 px-4 h-[36px] bg-[#166534] rounded-[9999px] text-[13px] font-semibold text-white hover:bg-[#145232] transition-colors">
          <Plus className="w-3.5 h-3.5" />
          New Announcement
        </button>
      </div>

      {/* Announcement List */}
      <div className="space-y-3">
        {filteredAnnouncements.map((announcement) => (
          <AnnouncementCard key={announcement.id} announcement={announcement} />
        ))}
      </div>
    </div>
  );
}
