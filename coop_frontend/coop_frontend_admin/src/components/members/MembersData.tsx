export type MemberRole = "Member" | "Administrator" | "Super Administrator";
export type MemberStatus = "Active" | "Pending" | "Suspended" | "Inactive" | "Blocked";
export type MemberRoleFilter = "All Roles" | MemberRole;
export type MemberStatusFilter = "All Status" | MemberStatus;
export type MemberSortOption = "Name A-Z" | "Name Z-A" | "Newest" | "Oldest";

export interface Member {
  idNumber: string;
  fullName: string;
  email: string;
  department: string;
  role: MemberRole;
  status: MemberStatus;
  createdAt: string;
}

export const roleFilterOptions: MemberRoleFilter[] = [
  "All Roles",
  "Member",
  "Administrator",
  "Super Administrator",
];

export const statusFilterOptions: MemberStatusFilter[] = [
  "All Status",
  "Active",
  "Inactive",
  "Blocked",
  "Suspended",
];

export const memberSortOptions: MemberSortOption[] = [
  "Name A-Z",
  "Name Z-A",
  "Newest",
  "Oldest",
];

export const memberRoles: MemberRole[] = [
  "Member",
  "Administrator",
  "Super Administrator",
];

export const memberStatuses: MemberStatus[] = [
  "Active",
  "Inactive",
  "Blocked",
  "Suspended",
];

export const mockMembers: Member[] = [
  {
    idNumber: "CSUCC-2019-0042",
    fullName: "Maria Santos",
    email: "maria.santos@csuccmpc.edu.ph",
    department: "College of Engineering",
    role: "Member",
    status: "Active",
    createdAt: "2019-01-15",
  },
  {
    idNumber: "CSUCC-2020-0089",
    fullName: "Juan Dela Cruz",
    email: "juan.delacruz@csuccmpc.edu.ph",
    department: "College of Education",
    role: "Member",
    status: "Active",
    createdAt: "2020-03-03",
  },
  {
    idNumber: "CSUCC-2021-0156",
    fullName: "Rosa Mendoza",
    email: "rosa.mendoza@csuccmpc.edu.ph",
    department: "Administration",
    role: "Administrator",
    status: "Pending",
    createdAt: "2021-06-10",
  },
  {
    idNumber: "CSUCC-2022-0234",
    fullName: "Carlos Reyes",
    email: "carlos.reyes@csuccmpc.edu.ph",
    department: "College of Nursing",
    role: "Member",
    status: "Active",
    createdAt: "2022-08-22",
  },
  {
    idNumber: "CSUCC-2018-0012",
    fullName: "Ana Torres",
    email: "ana.torres@csuccmpc.edu.ph",
    department: "Finance Office",
    role: "Administrator",
    status: "Suspended",
    createdAt: "2018-11-05",
  },
  {
    idNumber: "CSUCC-2023-0310",
    fullName: "Pedro Santos",
    email: "pedro.santos@csuccmpc.edu.ph",
    department: "College of Arts",
    role: "Member",
    status: "Active",
    createdAt: "2023-02-14",
  },
  {
    idNumber: "CSUCC-2020-0117",
    fullName: "Elena Garcia",
    email: "elena.garcia@csuccmpc.edu.ph",
    department: "College of Business",
    role: "Member",
    status: "Active",
    createdAt: "2020-07-18",
  },
  {
    idNumber: "CSUCC-2021-0188",
    fullName: "Mark Villanueva",
    email: "mark.villanueva@csuccmpc.edu.ph",
    department: "Information Technology Office",
    role: "Super Administrator",
    status: "Active",
    createdAt: "2021-09-12",
  },
  {
    idNumber: "CSUCC-2024-0365",
    fullName: "Liza Ramos",
    email: "liza.ramos@csuccmpc.edu.ph",
    department: "College of Education",
    role: "Member",
    status: "Pending",
    createdAt: "2024-01-26",
  },
  {
    idNumber: "CSUCC-2019-0061",
    fullName: "Nestor Lim",
    email: "nestor.lim@csuccmpc.edu.ph",
    department: "College of Agriculture",
    role: "Member",
    status: "Active",
    createdAt: "2019-10-09",
  },
  {
    idNumber: "CSUCC-2022-0268",
    fullName: "Catherine Flores",
    email: "catherine.flores@csuccmpc.edu.ph",
    department: "Registrar Office",
    role: "Administrator",
    status: "Active",
    createdAt: "2022-11-14",
  },
  {
    idNumber: "CSUCC-2018-0029",
    fullName: "Ramon Aquino",
    email: "ramon.aquino@csuccmpc.edu.ph",
    department: "College of Engineering",
    role: "Member",
    status: "Blocked",
    createdAt: "2018-12-20",
  },
  {
    idNumber: "CSUCC-2023-0301",
    fullName: "Grace Bautista",
    email: "grace.bautista@csuccmpc.edu.ph",
    department: "College of Nursing",
    role: "Member",
    status: "Active",
    createdAt: "2023-01-30",
  },
  {
    idNumber: "CSUCC-2024-0404",
    fullName: "Allan Navarro",
    email: "allan.navarro@csuccmpc.edu.ph",
    department: "Accounting Office",
    role: "Member",
    status: "Pending",
    createdAt: "2024-04-04",
  },
  {
    idNumber: "CSUCC-2020-0102",
    fullName: "Irene Castillo",
    email: "irene.castillo@csuccmpc.edu.ph",
    department: "College of Business",
    role: "Member",
    status: "Active",
    createdAt: "2020-05-22",
  },
  {
    idNumber: "CSUCC-2021-0199",
    fullName: "Samuel Ortega",
    email: "samuel.ortega@csuccmpc.edu.ph",
    department: "Facilities Management",
    role: "Member",
    status: "Active",
    createdAt: "2021-12-03",
  },
  {
    idNumber: "CSUCC-2017-0008",
    fullName: "Teresa Manuel",
    email: "teresa.manuel@csuccmpc.edu.ph",
    department: "Human Resources",
    role: "Administrator",
    status: "Blocked",
    createdAt: "2017-08-11",
  },
  {
    idNumber: "CSUCC-2022-0250",
    fullName: "Paolo Cruz",
    email: "paolo.cruz@csuccmpc.edu.ph",
    department: "College of Arts",
    role: "Member",
    status: "Active",
    createdAt: "2022-10-02",
  },
  {
    idNumber: "CSUCC-2024-0419",
    fullName: "Mikaela Robles",
    email: "mikaela.robles@csuccmpc.edu.ph",
    department: "College of Education",
    role: "Member",
    status: "Pending",
    createdAt: "2024-05-19",
  },
  {
    idNumber: "CSUCC-2020-0094",
    fullName: "Dennis Mercado",
    email: "dennis.mercado@csuccmpc.edu.ph",
    department: "Security Office",
    role: "Member",
    status: "Active",
    createdAt: "2020-04-16",
  },
  {
    idNumber: "CSUCC-2023-0337",
    fullName: "Janine Lopez",
    email: "janine.lopez@csuccmpc.edu.ph",
    department: "Library Services",
    role: "Member",
    status: "Active",
    createdAt: "2023-08-07",
  },
  {
    idNumber: "CSUCC-2019-0075",
    fullName: "Victor Salazar",
    email: "victor.salazar@csuccmpc.edu.ph",
    department: "College of Agriculture",
    role: "Member",
    status: "Suspended",
    createdAt: "2019-12-01",
  },
  {
    idNumber: "CSUCC-2021-0171",
    fullName: "Patricia Uy",
    email: "patricia.uy@csuccmpc.edu.ph",
    department: "Finance Office",
    role: "Super Administrator",
    status: "Inactive",
    createdAt: "2021-07-25",
  },
  {
    idNumber: "CSUCC-2022-0282",
    fullName: "Miguel Fernandez",
    email: "miguel.fernandez@csuccmpc.edu.ph",
    department: "Information Technology Office",
    role: "Administrator",
    status: "Active",
    createdAt: "2022-12-12",
  },
  {
    idNumber: "CSUCC-2024-0433",
    fullName: "Sofia Magbanua",
    email: "sofia.magbanua@csuccmpc.edu.ph",
    department: "College of Nursing",
    role: "Member",
    status: "Pending",
    createdAt: "2024-06-03",
  },
];
