export interface LoanType {
  id: string;
  name: string;
  description: string;
  interestRate: string;
  minimum: string;
  maximum: string;
  term: string;
  isActive: boolean;
}

export const loanTypes: LoanType[] = [
  {
    id: "1",
    name: "Regular Loan",
    description: "Standard multipurpose loan for employees",
    interestRate: "1.5%/mo",
    minimum: "₱5,000.00",
    maximum: "₱150,000.00",
    term: "12 mos",
    isActive: true,
  },
  {
    id: "2",
    name: "Emergency Loan",
    description: "Quick access loan for urgent financial needs",
    interestRate: "2.0%/mo",
    minimum: "₱3,000.00",
    maximum: "₱50,000.00",
    term: "6 mos",
    isActive: true,
  },
  {
    id: "3",
    name: "Educational Loan",
    description: "Loan for tuition and educational expenses",
    interestRate: "1.25%/mo",
    minimum: "₱10,000.00",
    maximum: "₱200,000.00",
    term: "24 mos",
    isActive: true,
  },
  {
    id: "4",
    name: "Medical Loan",
    description: "Healthcare and medical expense coverage",
    interestRate: "1.75%/mo",
    minimum: "₱5,000.00",
    maximum: "₱100,000.00",
    term: "12 mos",
    isActive: false,
  },
  {
    id: "5",
    name: "Housing Loan",
    description: "Home renovation and construction loan",
    interestRate: "1.0%/mo",
    minimum: "₱50,000.00",
    maximum: "₱500,000.00",
    term: "36 mos",
    isActive: true,
  },
];
