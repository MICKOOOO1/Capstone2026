"use client";

interface Application {
  id: string;
  member: string;
  type: string;
  amount: string;
  status: "Pending" | "Approved" | "Rejected";
  date: string;
}

const applications: Application[] = [
  {
    id: "LA-2025-0089",
    member: "Juan dela Cruz",
    type: "Regular",
    amount: "₱75,000.00",
    status: "Pending",
    date: "Jul 25, 2025",
  },
  {
    id: "LA-2025-0088",
    member: "Maria Santos",
    type: "Educational",
    amount: "₱50,000.00",
    status: "Approved",
    date: "Jul 25, 2025",
  },
  {
    id: "LA-2025-0087",
    member: "Carlos Reyes",
    type: "Medical",
    amount: "₱30,000.00",
    status: "Pending",
    date: "Jul 24, 2025",
  },
  {
    id: "LA-2025-0086",
    member: "Ana Garcia",
    type: "Emergency",
    amount: "₱20,000.00",
    status: "Rejected",
    date: "Jul 24, 2025",
  },
];

const statusStyles = {
  Pending: "bg-[#FFF7E8] text-[#F59E0B] border-[#FED7AA]",
  Approved: "bg-[#EAFBF1] text-[#10B981] border-[#A7F3D0]",
  Rejected: "bg-[#FDEEEE] text-[#EF4444] border-[#FECACA]",
};

export default function RecentApplications() {
  return (
    <div className="bg-white rounded-[14px] p-3 shadow-[0_1px_3px_rgba(0,0,0,0.04)] border border-[#ECECEC]">
      <div className="flex items-center justify-between mb-2">
        <div>
          <h2 className="text-[14px] font-semibold text-[#0F172A]">Recent Applications</h2>
        </div>
        <a href="#" className="text-[11px] text-[#1A5E38] font-medium hover:underline">
          View All
        </a>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full" style={{ tableLayout: "fixed" }}>
          <colgroup>
            <col style={{ width: "30%" }} />
            <col style={{ width: "14%" }} />
            <col style={{ width: "23%" }} />
            <col style={{ width: "18%" }} />
            <col style={{ width: "15%" }} />
          </colgroup>
          <thead>
            <tr className="bg-[#F8FAFC]">
              <th className="text-left py-2 px-5 text-[10px] font-semibold uppercase text-[#64748B] tracking-wider">
                ID / Member
              </th>
              <th className="text-left py-2 px-5 text-[10px] font-semibold uppercase text-[#64748B] tracking-wider">
                Type
              </th>
              <th className="text-right py-2 px-5 text-[10px] font-semibold uppercase text-[#64748B] tracking-wider">
                Amount
              </th>
              <th className="text-left py-2 px-5 text-[10px] font-semibold uppercase text-[#64748B] tracking-wider">
                Status
              </th>
              <th className="text-right py-2 px-5 text-[10px] font-semibold uppercase text-[#64748B] tracking-wider">
                Date
              </th>
            </tr>
          </thead>
          <tbody>
            {applications.map((app) => (
              <tr key={app.id} className="border-b border-[#F1F5F9] hover:bg-[#F8FAFC] transition-colors">
                <td className="py-2.5 px-5">
                  <div className="flex flex-col gap-0.5">
                    <p className="text-[10px] font-bold text-[#1A5E38]">{app.id}</p>
                    <p className="text-[12px] font-semibold text-[#0F172A]">{app.member}</p>
                  </div>
                </td>
                <td className="py-2.5 px-5 text-[11px] text-[#64748B]">{app.type}</td>
                <td className="py-2.5 px-5 text-[12px] font-semibold text-[#0F172A] text-right">{app.amount}</td>
                <td className="py-2.5 px-5">
                  <span
                    className={`inline-flex items-center px-2 py-1 rounded-full text-[10px] font-medium border ${statusStyles[app.status]}`}
                  >
                    {app.status}
                  </span>
                </td>
                <td className="py-2.5 px-5 text-[11px] text-[#64748B] text-right">{app.date}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
