"use client";

import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from "recharts";

const data = [
  { name: "Regular", value: 45, color: "#166534" },
  { name: "Educational", value: 20, color: "#D4AC2B" },
  { name: "Medical", value: 18, color: "#2F855A" },
  { name: "Emergency", value: 12, color: "#F0A128" },
  { name: "Other", value: 5, color: "#9CA3AF" },
];

export default function DonutChartCard() {
  return (
    <div className="bg-white rounded-[14px] p-3 shadow-[0_1px_3px_rgba(0,0,0,0.04)] border border-[#ECECEC]">
      <div className="mb-2">
        <h2 className="text-[14px] font-semibold text-[#0F172A]">Loan Types</h2>
        <p className="text-[11px] text-[#64748B] mt-0.5">Active loans distribution</p>
      </div>
      
      <div className="flex flex-col items-center">
        <div className="flex-shrink-0">
          <ResponsiveContainer width={80} height={80}>
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                innerRadius={24}
                outerRadius={40}
                stroke="white"
                strokeWidth={2}
                dataKey="value"
              >
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Pie>
            <Tooltip 
              contentStyle={{
                backgroundColor: "#FFFFFF",
                border: "1px solid #E5E7EB",
                borderRadius: "8px",
                boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
                padding: "4px",
                fontSize: "10px",
              }}
              formatter={(value: any) => `${value}%`}
            />
          </PieChart>
        </ResponsiveContainer>
        </div>
        
        {/* Custom Legend */}
        <div className="w-full mt-2">
          {data.map((item) => (
            <div key={item.name} className="flex items-center justify-between py-[4px]">
              <div className="flex items-center gap-1.5">
                <div className="w-1 h-1 rounded-full" style={{ backgroundColor: item.color }} />
                <span className="text-[11px] text-[#374151]">{item.name}</span>
              </div>
              <span className="text-[11px] font-semibold text-[#111827]">{item.value}%</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
