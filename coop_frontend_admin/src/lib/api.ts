import { getSupabaseClient } from './supabase'
import type { Member, MemberStatus } from '@/components/members/MembersData'

export interface LoanApplication {
  id: string;
  memberId: string;
  member: string;
  type: string;
  amount: string;
  status: "Pending" | "Under Review" | "Approved" | "Rejected" | "Released" | "Completed" | "Overdue";
  date: string;
}

export interface SupabaseLoanApplication {
  id: string;
  application_id: string;
  member_id: string;
  member_name: string;
  loan_type: string;
  amount: number;
  purpose: string;
  status: string;
  income?: number;
  credit_score?: number;
  date_submitted: string;
  date_approved?: string;
  date_released?: string;
  date_completed?: string;
}

export interface SupabaseMember {
  id: string;
  member_id: string;
  first_name: string;
  last_name: string;
  email?: string | null;
  address?: string | null;
  status?: string | null;
  date_joined?: string | null;
  created_at?: string | null;
}

// Transform Supabase data to frontend format
function transformToFrontendFormat(supabaseApp: SupabaseLoanApplication): LoanApplication {
  const status = supabaseApp.status === 'under review'
    ? 'Under Review'
    : supabaseApp.status.charAt(0).toUpperCase() + supabaseApp.status.slice(1)

  return {
    id: supabaseApp.application_id,
    memberId: supabaseApp.member_id,
    member: supabaseApp.member_name,
    type: supabaseApp.loan_type,
    amount: `₱${supabaseApp.amount.toLocaleString('en-PH', { minimumFractionDigits: 2 })}`,
    status: status as LoanApplication['status'],
    date: new Date(supabaseApp.date_submitted).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  };
}

function toMemberStatus(status?: string | null): MemberStatus {
  switch ((status ?? '').toLowerCase()) {
    case 'active':
      return 'Active';
    case 'inactive':
      return 'Inactive';
    case 'suspended':
      return 'Blocked';
    default:
      return 'Pending';
  }
}

function toDatabaseMemberStatus(status: MemberStatus): 'active' | 'inactive' | 'suspended' {
  if (status === 'Inactive') return 'inactive';
  if (status === 'Blocked' || status === 'Suspended') return 'suspended';
  return 'active';
}

function transformMember(member: SupabaseMember): Member {
  return {
    idNumber: member.member_id,
    fullName: `${member.first_name} ${member.last_name}`.trim(),
    email: member.email ?? '',
    department: member.address ?? 'Not set',
    role: 'Member',
    status: toMemberStatus(member.status),
    createdAt: member.date_joined ?? member.created_at ?? new Date().toISOString(),
  };
}

export async function fetchLoanApplications(): Promise<LoanApplication[]> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('loan_applications')
      .select(`
        *,
        members (
          member_id,
          first_name,
          last_name
        )
      `)
      .order('date_submitted', { ascending: false });

    if (error) throw error;

    return data.map((app) => transformToFrontendFormat({
      ...app,
      member_id: app.members?.member_id || '',
      member_name: app.members ? `${app.members.first_name} ${app.members.last_name}` : app.member_name
    }));
  } catch (error) {
    throw new Error(`Unable to fetch loan applications: ${String(error)}`);
  }
}

export async function fetchLoanApplicationById(id: string): Promise<LoanApplication> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('loan_applications')
      .select(`
        *,
        members (
          member_id,
          first_name,
          last_name
        )
      `)
      .eq('application_id', id)
      .single();

    if (error) throw error;

    return transformToFrontendFormat({
      ...data,
      member_id: data.members?.member_id || '',
      member_name: data.members ? `${data.members.first_name} ${data.members.last_name}` : data.member_name
    });
  } catch (error) {
    console.error('Error fetching loan application:', error);
    throw error;
  }
}

export async function createLoanApplication(application: Omit<LoanApplication, 'id' | 'date'>): Promise<LoanApplication> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('loan_applications')
      .insert({
        application_id: `LA-2025-${Date.now().toString().slice(-4)}`,
        member_id: application.memberId,
        member_name: application.member,
        loan_type: application.type,
        amount: parseFloat(application.amount.replace('₱', '').replace(',', '')),
        purpose: application.type,
        status: application.status.toLowerCase(),
        date_submitted: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    return transformToFrontendFormat(data);
  } catch (error) {
    console.error('Error creating loan application:', error);
    throw error;
  }
}

export async function updateLoanApplicationStatus(id: string, status: string): Promise<LoanApplication> {
  try {
    const client = getSupabaseClient();

    if (status.toLowerCase() === 'approved') {
      const { data, error } = await client.functions.invoke('loan-approval', {
        body: { application_id: id },
      });

      if (error) throw error;
      const result = Array.isArray(data) ? data[0] : data;
      if (!result?.success) {
        throw new Error(result?.message || 'Loan application could not be approved.');
      }

      return fetchLoanApplicationById(id);
    }

    const { data, error } = await client
      .from('loan_applications')
      .update({ status: status.toLowerCase() })
      .eq('application_id', id)
      .select()
      .single();

    if (error) throw error;

    return transformToFrontendFormat(data);
  } catch (error) {
    console.error('Error updating loan application:', error);
    throw error;
  }
}

// New functions for members
export async function fetchMembers(): Promise<Member[]> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('members')
      .select('id, member_id, first_name, last_name, email, address, status, date_joined, created_at')
      .order('date_joined', { ascending: false });

    if (error) throw error;
    return data.map(transformMember);
  } catch (error) {
    throw new Error(`Unable to fetch members: ${String(error)}`);
  }
}

export async function updateMemberStatus(memberId: string, status: MemberStatus): Promise<Member> {
  try {
    const { data, error } = await getSupabaseClient()
      .from('members')
      .update({ status: toDatabaseMemberStatus(status) })
      .eq('member_id', memberId)
      .select()
      .single();

    if (error) throw error;
    return transformMember(data);
  } catch (error) {
    console.error('Error updating member status:', error);
    throw error;
  }
}
