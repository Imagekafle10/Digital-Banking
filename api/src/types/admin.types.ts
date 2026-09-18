export interface AdminListQuery {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
  type?: string;
  role?: string;
  startDate?: string;
  endDate?: string;
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
