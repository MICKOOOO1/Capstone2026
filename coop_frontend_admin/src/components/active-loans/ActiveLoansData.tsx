export interface ActiveLoan {
  loanNumber: string;
  memberName: string;
  memberId: string;
  type: string;
  originalAmount: string;
  balance: string;
  monthlyDue: string;
  nextDue: string;
  status: "Current" | "Due Soon" | "Overdue";
  createdAt: string;
}

export const activeLoans: ActiveLoan[] = [
  {
    loanNumber: "LN-2026-0042",
    memberName: "Maria Santos",
    memberId: "2023-0337",
    type: "Regular",
    originalAmount: "₱100,000.00",
    balance: "₱82,666.67",
    monthlyDue: "₱8,266.67",
    nextDue: "Oct 15, 2026",
    status: "Current",
    createdAt: "2026-08-15",
  },
  {
    loanNumber: "LN-2026-0038",
    memberName: "Pedro Santos",
    memberId: "2023-0310",
    type: "Educational",
    originalAmount: "₱60,000.00",
    balance: "₱45,000.00",
    monthlyDue: "₱3,750.00",
    nextDue: "Sep 30, 2026",
    status: "Due Soon",
    createdAt: "2026-07-01",
  },
  {
    loanNumber: "LN-2026-0029",
    memberName: "Carlo Reyes",
    memberId: "2023-0301",
    type: "Regular",
    originalAmount: "₱40,000.00",
    balance: "₱28,500.00",
    monthlyDue: "₱2,375.00",
    nextDue: "Sep 12, 2026",
    status: "Overdue",
    createdAt: "2026-06-12",
  },
  {
    loanNumber: "LN-2026-0015",
    memberName: "Ben Aquino",
    memberId: "2022-0282",
    type: "Medical",
    originalAmount: "₱24,000.00",
    balance: "₱15,000.00",
    monthlyDue: "₱1,500.00",
    nextDue: "Oct 10, 2026",
    status: "Current",
    createdAt: "2026-05-10",
  },
  {
    loanNumber: "LN-2026-0011",
    memberName: "Grace Bautista",
    memberId: "2022-0268",
    type: "Emergency",
    originalAmount: "₱30,000.00",
    balance: "₱18,750.00",
    monthlyDue: "₱3,125.00",
    nextDue: "Sep 28, 2026",
    status: "Due Soon",
    createdAt: "2026-04-28",
  },
  {
    loanNumber: "LN-2026-0008",
    memberName: "Miguel Fernandez",
    memberId: "2022-0250",
    type: "Regular",
    originalAmount: "₱120,000.00",
    balance: "₱96,000.00",
    monthlyDue: "₱10,000.00",
    nextDue: "Oct 20, 2026",
    status: "Current",
    createdAt: "2026-04-20",
  },
  {
    loanNumber: "LN-2026-0004",
    memberName: "Catherine Flores",
    memberId: "2022-0234",
    type: "Medical",
    originalAmount: "₱50,000.00",
    balance: "₱37,500.00",
    monthlyDue: "₱4,166.67",
    nextDue: "Sep 5, 2026",
    status: "Overdue",
    createdAt: "2026-03-05",
  },
];
