"use client";

import { useState } from "react";
import { Search } from "lucide-react";
import { NotificationHistory } from "./NotificationHistoryData";
import NotificationBadge from "./NotificationBadge";

interface NotificationHistoryCardProps {
  history: NotificationHistory[];
}

export default function NotificationHistoryCard({ history }: NotificationHistoryCardProps) {
  const [searchQuery, setSearchQuery] = useState("");

  const filteredHistory = history.filter((item) =>
    item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    item.recipient.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="bg-white rounded-[16px] shadow-[0_2px_12px_rgba(0,0,0,0.06)] border border-[#E5E7EB] p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-[18px] font-semibold text-[#1F2937]">Notification History</h2>
        
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280] w-4 h-4" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search..."
            className="w-[180px] h-[36px] pl-9 pr-4 bg-white border border-[#E5E7EB] rounded-[10px] text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:outline-none focus:ring-2 focus:ring-[#166534]/20"
          />
        </div>
      </div>

      {/* Notification List */}
      <div className="space-y-2">
        {filteredHistory.map((item) => (
          <div key={item.id} className="border-b border-[#E5E7EB] pb-2 last:border-0 last:pb-0">
            <div className="flex items-start justify-between gap-3">
              {/* Left side */}
              <div className="flex-1">
                <h3 className="text-[14px] font-semibold text-[#1F2937] mb-0.5">{item.title}</h3>
                <p className="text-[12px] text-[#6B7280]">
                  To: {item.recipient} · {item.recipientCount.toLocaleString()} recipients
                </p>
                <p className="text-[12px] text-[#9CA3AF] mt-0.5">{item.date}</p>
              </div>
              
              {/* Right side - Badge */}
              <NotificationBadge type={item.type} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
