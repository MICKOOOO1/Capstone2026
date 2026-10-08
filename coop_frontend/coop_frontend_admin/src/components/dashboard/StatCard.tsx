"use client";

import { LucideIcon, TrendingUp } from "lucide-react";

interface StatCardProps {
  icon: LucideIcon;
  iconBgColor: string;
  iconColor: string;
  customBgColor?: string;
  customIconColor?: string;
  label: string;
  value: string;
  subtitle: string;
  trend?: boolean;
}

export default function StatCard({
  icon: Icon,
  iconBgColor,
  iconColor,
  customBgColor,
  customIconColor,
  label,
  value,
  subtitle,
  trend = true,
}: StatCardProps) {
  return (
    <div className="bg-white rounded-[14px] p-3 shadow-[0_2px_6px_rgba(15,23,42,0.05)] border border-[#E5E7EB] hover:-translate-y-[2px] hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)] transition-all duration-200 h-[72px] min-h-[72px] overflow-hidden">
      <div className="flex items-center justify-between h-full">
        {/* Left: Icon + Text */}
        <div className="flex gap-3 items-center flex-1 min-w-0">
          {/* Icon */}
          <div
            className="w-8 h-8 rounded-[10px] flex items-center justify-center flex-shrink-0"
            style={{ backgroundColor: customBgColor || iconBgColor }}
          >
            <Icon
              className="w-4 h-4"
              style={{ color: customIconColor || iconColor }}
              strokeWidth={2}
            />
          </div>

          {/* Text */}
          <div className="flex flex-col justify-center">
            <p className="text-[10px] font-semibold uppercase text-[#9CA3AF] tracking-[0.08em]">
              {label}
            </p>
            <p className="text-[15px] font-bold text-[#111827] leading-[1.1] mt-0.5">{value}</p>
            <p className="text-[11px] font-normal text-[#94A3B8] mt-[2px]">{subtitle}</p>
          </div>
        </div>

        {/* Top Right: Trend Icon */}
        {trend && (
          <div className="flex items-center gap-1 text-[#10B981] flex-shrink-0">
            <TrendingUp className="w-2.5 h-2.5" strokeWidth={2} />
          </div>
        )}
      </div>
    </div>
  );
}
