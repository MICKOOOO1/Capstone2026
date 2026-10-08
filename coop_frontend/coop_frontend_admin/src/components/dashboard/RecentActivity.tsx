"use client";

import { CheckCircle, FileText, DollarSign, XCircle, UserPlus } from "lucide-react";

interface Activity {
  icon: any;
  iconColor: string;
  iconTextColor: string;
  title: string;
  description: string;
  timestamp: string;
}

const activities: Activity[] = [
  {
    icon: CheckCircle,
    iconColor: "bg-green-100",
    iconTextColor: "text-green-600",
    title: "Loan Approved",
    description: "LA-2025-0088 approved for Maria Santos",
    timestamp: "2 hours ago",
  },
  {
    icon: FileText,
    iconColor: "bg-blue-100",
    iconTextColor: "text-blue-600",
    title: "New Application",
    description: "Juan dela Cruz submitted Regular loan",
    timestamp: "3 hours ago",
  },
  {
    icon: DollarSign,
    iconColor: "bg-green-100",
    iconTextColor: "text-green-600",
    title: "Payment Received",
    description: "₱5,000 payment from Carlos Reyes",
    timestamp: "5 hours ago",
  },
  {
    icon: XCircle,
    iconColor: "bg-red-100",
    iconTextColor: "text-red-600",
    title: "Application Rejected",
    description: "LA-2025-0086 rejected - insufficient docs",
    timestamp: "6 hours ago",
  },
  {
    icon: UserPlus,
    iconColor: "bg-blue-100",
    iconTextColor: "text-blue-600",
    title: "New Member",
    description: "Ben Aquino registered",
    timestamp: "1 day ago",
  },
];

export default function RecentActivity() {
  return (
    <div className="bg-white rounded-[14px] p-3 shadow-[0_1px_3px_rgba(0,0,0,0.04)] border border-[#ECECEC]">
      <div className="mb-2">
        <h2 className="text-[14px] font-semibold text-[#0F172A]">Recent Activity</h2>
      </div>

      <div className="space-y-0.5">
        {activities.map((activity, index) => (
          <div key={index} className="flex gap-2 py-1 rounded-lg hover:bg-[#F8FAFC] transition-colors cursor-pointer">
            {/* Icon */}
            <div className={`w-[22px] h-[22px] ${activity.iconColor} rounded-full flex items-center justify-center flex-shrink-0`}>
              <activity.icon className={`w-2.5 h-2.5 ${activity.iconTextColor}`} />
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <p className="text-[12px] font-semibold text-[#0F172A]">{activity.title}</p>
              <p className="text-[11px] text-[#64748B] truncate">{activity.description}</p>
              <p className="text-[10px] text-[#64748B] mt-0.5">{activity.timestamp}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
