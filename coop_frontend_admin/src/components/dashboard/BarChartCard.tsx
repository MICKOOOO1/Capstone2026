"use client";

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

const data = [
  { month: "Feb", applications: 24, approved: 18 },
  { month: "Mar", applications: 31, approved: 24 },
  { month: "Apr", applications: 28, approved: 21 },
  { month: "May", applications: 35, approved: 28 },
  { month: "Jun", applications: 42, approved: 35 },
  { month: "Jul", applications: 38, approved: 30 },
];

export default function BarChartCard() {
  return (
    <div className="bg-white rounded-[14px] p-3 shadow-[0_1px_3px_rgba(0,0,0,0.04)] border border-[#ECECEC]">
      <div className="flex items-start justify-between mb-2">
        <div>
          <h2 className="text-[14px] font-semibold text-[#0F172A]">Monthly Loan Applications</h2>
          <p className="text-[11px] text-[#64748B] mt-0.5">Feb – Jul 2025</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5">
            <div className="w-[6px] h-[6px] rounded-full" style={{ backgroundColor: "#166534" }} />
            <span className="text-[10px] text-[#64748B]">Applications</span>
          </div>
          <div className="flex items-center gap-1.5">
            <div className="w-[6px] h-[6px] rounded-full" style={{ backgroundColor: "#D4AC2B" }} />
            <span className="text-[10px] text-[#64748B]">Approved</span>
          </div>
        </div>
      </div>
      
      <ResponsiveContainer width="100%" height={160}>
        <BarChart data={data} margin={{ top: 10, right: 10, left: -15, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#EAECEF" />
          <XAxis 
            dataKey="month" 
            axisLine={false}
            tickLine={false}
            tick={{ fill: "#94A3B8", fontSize: 10 }}
          />
          <YAxis 
            axisLine={false}
            tickLine={false}
            tick={{ fill: "#94A3B8", fontSize: 10 }}
            domain={[0, 60]}
            ticks={[0, 15, 30, 45, 60]}
          />
          <Tooltip 
            contentStyle={{
              backgroundColor: "#FFFFFF",
              border: "1px solid #E5E7EB",
              borderRadius: "8px",
              boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
              padding: "6px",
              fontSize: "10px",
            }}
          />
          <Bar 
            dataKey="applications" 
            name="Applications" 
            fill="#166534" 
            radius={[2, 2, 0, 0]}
            barSize={32}
          />
          <Bar 
            dataKey="approved" 
            name="Approved" 
            fill="#D4AC2B" 
            radius={[2, 2, 0, 0]}
            barSize={32}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
