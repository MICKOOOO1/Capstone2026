"use client";

import { Star, Megaphone, Pencil, Trash2 } from "lucide-react";
import { Announcement } from "./AnnouncementsData";
import AnnouncementBadge from "./AnnouncementBadge";

interface AnnouncementCardProps {
  announcement: Announcement;
}

export default function AnnouncementCard({ announcement }: AnnouncementCardProps) {
  return (
    <div className="bg-white rounded-[14px] shadow-[0_2px_12px_rgba(0,0,0,0.06)] border border-[#E5E7EB] p-3 hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)] transition-shadow duration-200">
      <div className="flex items-start gap-3">
        {/* Left Section - Icon */}
        <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
          announcement.isPinned ? "bg-yellow-50" : "bg-gray-100"
        }`}>
          {announcement.isPinned ? (
            <Star className="w-3.5 h-3.5 text-yellow-600" strokeWidth={2} />
          ) : (
            <Megaphone className="w-3.5 h-3.5 text-gray-600" strokeWidth={2} />
          )}
        </div>

        {/* Middle Section - Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-[14px] font-semibold text-[#1F2937] truncate">{announcement.title}</h3>
            {announcement.isPinned && (
              <AnnouncementBadge type="Pinned" />
            )}
          </div>
          <div className="flex items-center gap-2">
            <AnnouncementBadge type="category" text={announcement.category} />
            <span className="text-[11px] text-[#9CA3AF]">{announcement.date}</span>
          </div>
        </div>

        {/* Right Section - Status & Actions */}
        <div className="flex items-center gap-2 flex-shrink-0">
          <AnnouncementBadge type={announcement.status} />
          <div className="flex items-center gap-1.5">
            <button className="w-7 h-7 rounded-full flex items-center justify-center text-[#6B7280] hover:text-[#1F2937] transition-colors">
              <Pencil className="w-3.5 h-3.5" strokeWidth={2} />
            </button>
            <button className="w-7 h-7 rounded-full flex items-center justify-center text-[#6B7280] hover:text-[#EF4444] transition-colors">
              <Trash2 className="w-3.5 h-3.5" strokeWidth={2} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
