const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';

export interface LoanApplication {
  id: string;
  memberId: string;
  member: string;
  type: string;
  amount: string;
  status: "Pending" | "Under Review" | "Approved" | "Rejected" | "Released" | "Completed" | "Overdue";
  date: string;
}

export interface BackendLoanApplication {
  id: number;
  applicantName: string;
  amount: number;
  status: string;
  dateSubmitted: string;
  purpose: string;
  memberId?: string;
  income?: number;
  creditScore?: number;
}

// Transform backend data to frontend format
function transformToFrontendFormat(backendApp: BackendLoanApplication): LoanApplication {
  return {
    id: `LA-2025-${String(backendApp.id).padStart(4, '0')}`,
    memberId: backendApp.memberId ?? '',
    member: backendApp.applicantName,
    type: backendApp.purpose || 'Regular',
    amount: `₱${backendApp.amount.toLocaleString('en-PH', { minimumFractionDigits: 2 })}`,
    status: backendApp.status.charAt(0).toUpperCase() + backendApp.status.slice(1) as LoanApplication['status'],
    date: new Date(backendApp.dateSubmitted).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  };
}

export async function fetchLoanApplications(): Promise<LoanApplication[]> {
  try {
    const response = await fetch(`${API_BASE_URL}/api/loan-applications`);
    if (!response.ok) {
      throw new Error('Failed to fetch loan applications');
    }
    const data: BackendLoanApplication[] = await response.json();
    return data.map(transformToFrontendFormat);
  } catch (error) {
    console.error('Error fetching loan applications:', error);
    // Return mock data as fallback
    return [];
  }
}

export async function fetchLoanApplicationById(id: string): Promise<LoanApplication> {
  try {
    const numericId = parseInt(id.replace('LA-2025-', ''));
    const response = await fetch(`${API_BASE_URL}/api/loan-applications/${numericId}`);
    if (!response.ok) {
      throw new Error('Failed to fetch loan application');
    }
    const data: BackendLoanApplication = await response.json();
    return transformToFrontendFormat(data);
  } catch (error) {
    console.error('Error fetching loan application:', error);
    throw error;
  }
}

export async function createLoanApplication(application: Omit<LoanApplication, 'id' | 'date'>): Promise<LoanApplication> {
  try {
    const response = await fetch(`${API_BASE_URL}/api/loan-applications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        applicantName: application.member,
        amount: parseFloat(application.amount.replace('₱', '').replace(',', '')),
        purpose: application.type,
        status: application.status.toLowerCase()
      }),
    });
    if (!response.ok) {
      throw new Error('Failed to create loan application');
    }
    const data: BackendLoanApplication = await response.json();
    return transformToFrontendFormat(data);
  } catch (error) {
    console.error('Error creating loan application:', error);
    throw error;
  }
}

export async function updateLoanApplicationStatus(id: string, status: string): Promise<LoanApplication> {
  try {
    const numericId = parseInt(id.replace('LA-2025-', ''));
    const response = await fetch(`${API_BASE_URL}/api/loan-applications/${numericId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status: status.toLowerCase() }),
    });
    if (!response.ok) {
      throw new Error('Failed to update loan application');
    }
    const data: BackendLoanApplication = await response.json();
    return transformToFrontendFormat(data);
  } catch (error) {
    console.error('Error updating loan application:', error);
    throw error;
  }
}
