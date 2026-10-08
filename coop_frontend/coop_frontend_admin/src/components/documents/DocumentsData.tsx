export interface Document {
  id: string;
  name: string;
  category: string;
  type: "PDF" | "DOCX" | "PNG" | "XLSX";
  size: string;
  uploaded: string;
}

export const documents: Document[] = [
  {
    id: "1",
    name: "Loan Application Form v3.2",
    category: "Loan Forms",
    type: "PDF",
    size: "245 KB",
    uploaded: "Jul 20, 2025",
  },
  {
    id: "2",
    name: "Member Terms and Conditions 2025",
    category: "Terms & Conditions",
    type: "DOCX",
    size: "512 KB",
    uploaded: "Jan 5, 2025",
  },
  {
    id: "3",
    name: "Loan Policy Manual",
    category: "Policies",
    type: "PDF",
    size: "1.2 MB",
    uploaded: "Jun 10, 2025",
  },
  {
    id: "4",
    name: "Co-Maker Requirements",
    category: "Loan Forms",
    type: "DOCX",
    size: "180 KB",
    uploaded: "Jul 15, 2025",
  },
  {
    id: "5",
    name: "Membership Guidelines 2025",
    category: "Guidelines",
    type: "PDF",
    size: "340 KB",
    uploaded: "Jul 18, 2025",
  },
];
