export type UserRole = 'user' | 'admin';
export type UserStatus = 'active' | 'suspended';
export type Gender = 'Male' | 'Female' | 'Other';
export type AccountType = 'savings' | 'checking' | 'wallet';
export type AccountStatus = 'active' | 'suspended' | 'closed';
export type TransactionType = 'deposit' | 'withdrawal' | 'transfer_in' | 'transfer_out';
export type TransactionStatus = 'pending' | 'completed' | 'failed' | 'reversed';
export type PaymentProvider = 'khalti' | 'esewa';
export type PaymentStatus = 'initiated' | 'pending' | 'completed' | 'failed' | 'expired' | 'refunded';

export interface User {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  dateOfBirth: string;
  gender: Gender;
  role: UserRole;
  status: UserStatus;
  createdAt: string;
  updatedAt: string;
}

export interface Account {
  id: string;
  userId: string;
  accountNumber: string;
  accountType: AccountType;
  balance: number;
  currency: string;
  status: AccountStatus;
  createdAt: string;
  updatedAt: string;
  userName?: string;
  userEmail?: string;
}

export interface Transaction {
  id: string;
  accountId: string;
  type: TransactionType;
  amount: number;
  balanceAfter: number;
  reference: string;
  relatedAccountId?: string | null;
  status: TransactionStatus;
  remarks?: string;
  createdAt: string;
  accountNumber?: string;
  userName?: string;
  relatedAccountNumber?: string | null;
  counterpartyName?: string | null;
}

export interface Payment {
  id: string;
  accountId: string;
  provider: PaymentProvider;
  amount: number;
  providerReference: string;
  status: PaymentStatus;
  createdAt: string;
  updatedAt: string;
  accountNumber?: string;
  userName?: string;
}

export interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  suspendedUsers: number;
  totalAccounts: number;
  activeAccounts: number;
  totalBalance: number;
  totalTransactions: number;
  todayTransactions: number;
  totalPayments: number;
  pendingPayments: number;
  volumeToday: number;
  volumeMonth: number;
}

export interface ChartPoint {
  date: string;
  deposits: number;
  withdrawals: number;
  transfers: number;
  count: number;
}

export interface AuthUser {
  id: string;
  fullName: string;
  email: string;
  role: UserRole;
}

export interface LoginResponse {
  user: AuthUser;
  accessToken: string;
}

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface ListParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
  type?: string;
  role?: string;
  startDate?: string;
  endDate?: string;
}
