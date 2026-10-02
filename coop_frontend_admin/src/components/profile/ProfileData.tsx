export interface Profile {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  department: string;
  position: string;
  role: string;
  username: string;
  accountStatus: string;
  dateCreated: string;
  lastPasswordChange: string;
  lastLogin: string;
  office: string;
}

export interface Activity {
  id: string;
  action: string;
  description: string;
  date: string;
  time: string;
}

export const profile: Profile = {
  id: "ADM-2020-001",
  firstName: "John",
  lastName: "Cruz",
  email: "john.cruz@csucc.coop",
  phone: "+63 917 000 0001",
  department: "IT Department",
  position: "Super Administrator",
  role: "Super Administrator",
  username: "jcruz",
  accountStatus: "Active",
  dateCreated: "January 15, 2020",
  lastPasswordChange: "July 10, 2025",
  lastLogin: "Jul 25, 2025 • 8:42 AM",
  office: "CSUCC MPC Main Office",
};

export const activities: Activity[] = [
  {
    id: "1",
    action: "Logged in",
    description: "Successfully logged in from IP 192.168.1.10",
    date: "Jul 25, 2025",
    time: "8:42 AM",
  },
  {
    id: "2",
    action: "Updated Profile",
    description: "Updated phone number and department information",
    date: "Jul 20, 2025",
    time: "3:15 PM",
  },
  {
    id: "3",
    action: "Changed Password",
    description: "Password successfully updated",
    date: "Jul 10, 2025",
    time: "11:30 AM",
  },
  {
    id: "4",
    action: "Approved Loan",
    description: "Approved loan application LA-2025-0087",
    date: "Jul 8, 2025",
    time: "2:45 PM",
  },
];
