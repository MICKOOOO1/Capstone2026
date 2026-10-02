export interface Announcement {
  id: string;
  title: string;
  category: string;
  date: string;
  status: "Published" | "Scheduled" | "Draft";
  isPinned: boolean;
}

export const announcements: Announcement[] = [
  {
    id: "1",
    title: "Office Hours During Holy Week",
    category: "Operations",
    date: "Jul 20, 2025",
    status: "Published",
    isPinned: true,
  },
  {
    id: "2",
    title: "New Interest Rate Effective August 2025",
    category: "Policy",
    date: "Jul 18, 2025",
    status: "Published",
    isPinned: true,
  },
  {
    id: "3",
    title: "Loan Application Requirement Update",
    category: "Loans",
    date: "Jul 15, 2025",
    status: "Published",
    isPinned: false,
  },
  {
    id: "4",
    title: "System Maintenance — July 30",
    category: "System",
    date: "Jul 29, 2025",
    status: "Scheduled",
    isPinned: false,
  },
  {
    id: "5",
    title: "Holiday Schedule for August",
    category: "Operations",
    date: "Jul 25, 2025",
    status: "Draft",
    isPinned: false,
  },
];
