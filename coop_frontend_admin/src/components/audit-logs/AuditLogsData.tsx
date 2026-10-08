export interface AuditLog {
  id: number;
  action: string;
  administrator: string;
  target: string;
  timestamp: string;
  ipAddress: string;
}

export const auditLogs: AuditLog[] = [
  {
    id: 1,
    action: "Loan Approved",
    administrator: "Admin John Cruz",
    target: "LA-2025-0087",
    timestamp: "Jul 25, 2025 10:34:21",
    ipAddress: "192.168.1.10",
  },
  {
    id: 2,
    action: "Member Updated",
    administrator: "Admin John Cruz",
    target: "CSUCC-2019-0042",
    timestamp: "Jul 25, 2025 09:15:44",
    ipAddress: "192.168.1.10",
  },
  {
    id: 3,
    action: "Notification Sent",
    administrator: "Admin Maria Lim",
    target: "All Members",
    timestamp: "Jul 24, 2025 16:22:10",
    ipAddress: "192.168.1.15",
  },
  {
    id: 4,
    action: "Announcement Posted",
    administrator: "Admin John Cruz",
    target: "ANN-2025-014",
    timestamp: "Jul 24, 2025 14:08:33",
    ipAddress: "192.168.1.10",
  },
  {
    id: 5,
    action: "Login",
    administrator: "Admin Maria Lim",
    target: "System",
    timestamp: "Jul 24, 2025 13:55:02",
    ipAddress: "192.168.1.15",
  },
  {
    id: 6,
    action: "Settings Changed",
    administrator: "Super Admin",
    target: "Interest Rate",
    timestamp: "Jul 23, 2025 11:30:00",
    ipAddress: "192.168.1.1",
  },
];
