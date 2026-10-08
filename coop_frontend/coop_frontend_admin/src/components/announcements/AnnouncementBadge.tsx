"use client";

interface AnnouncementBadgeProps {
  type: "Published" | "Scheduled" | "Draft" | "Pinned" | "category";
  text?: string;
}

export default function AnnouncementBadge({ type, text }: AnnouncementBadgeProps) {
  const styles = {
    Published: "bg-green-50 text-green-700 border-green-200",
    Scheduled: "bg-blue-50 text-blue-700 border-blue-200",
    Draft: "bg-gray-50 text-gray-700 border-gray-200",
    Pinned: "bg-yellow-50 text-yellow-700 border-yellow-300 border",
    category: "bg-gray-50 text-gray-600 border-gray-200",
  };

  const displayText = text || type;

  return (
    <span className={`inline-flex items-center h-[18px] px-2 py-0 rounded-full text-[10px] font-medium border ${styles[type]}`}>
      {displayText}
    </span>
  );
}
