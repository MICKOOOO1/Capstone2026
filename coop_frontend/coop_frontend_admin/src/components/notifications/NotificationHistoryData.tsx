export interface NotificationHistory {
  id: string;
  title: string;
  recipient: string;
  recipientCount: number;
  date: string;
  type: "Maintenance" | "Reminder" | "Promotion" | "Information" | "Emergency" | "Approval" | "Reject";
}

export const notificationHistory: NotificationHistory[] = [
  {
    id: "1",
    title: "System Maintenance Scheduled",
    recipient: "All Members",
    recipientCount: 1284,
    date: "Jul 24, 2025",
    type: "Maintenance",
  },
  {
    id: "2",
    title: "Loan Payment Reminder",
    recipient: "Active Members",
    recipientCount: 1156,
    date: "Jul 23, 2025",
    type: "Reminder",
  },
  {
    id: "3",
    title: "New Loan Promotion Available",
    recipient: "All Members",
    recipientCount: 1284,
    date: "Jul 22, 2025",
    type: "Promotion",
  },
  {
    id: "4",
    title: "Account Information Update",
    recipient: "Pending Approval",
    recipientCount: 48,
    date: "Jul 21, 2025",
    type: "Information",
  },
  {
    id: "5",
    title: "Emergency: Server Downtime",
    recipient: "All Members",
    recipientCount: 1284,
    date: "Jul 20, 2025",
    type: "Emergency",
  },
  {
    id: "6",
    title: "Loan Application Approved",
    recipient: "Maria Santos",
    recipientCount: 1,
    date: "Jul 19, 2025",
    type: "Approval",
  },
];
