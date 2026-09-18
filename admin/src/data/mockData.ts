import type {
  User, Account, Transaction, Payment, DashboardStats, ChartPoint,
} from '../types';

const now = Date.now();
const day = 24 * 60 * 60 * 1000;

export const mockUsers: User[] = [
  { id: 'u-admin-001', fullName: 'Admin User', email: 'admin@bank.com', phone: '+9779800000001', dateOfBirth: '1990-01-15', gender: 'Male', role: 'admin', status: 'active', createdAt: new Date(now - 365 * day).toISOString(), updatedAt: new Date(now - 10 * day).toISOString() },
  { id: 'u-001', fullName: 'Ram Sharma', email: 'ram.sharma@email.com', phone: '+9779841001001', dateOfBirth: '1992-05-20', gender: 'Male', role: 'user', status: 'active', createdAt: new Date(now - 200 * day).toISOString(), updatedAt: new Date(now - 2 * day).toISOString() },
  { id: 'u-002', fullName: 'Sita Thapa', email: 'sita.thapa@email.com', phone: '+9779841001002', dateOfBirth: '1995-08-12', gender: 'Female', role: 'user', status: 'active', createdAt: new Date(now - 180 * day).toISOString(), updatedAt: new Date(now - 5 * day).toISOString() },
  { id: 'u-003', fullName: 'Hari Bahadur', email: 'hari.b@email.com', phone: '+9779841001003', dateOfBirth: '1988-03-08', gender: 'Male', role: 'user', status: 'suspended', createdAt: new Date(now - 150 * day).toISOString(), updatedAt: new Date(now - 1 * day).toISOString() },
  { id: 'u-004', fullName: 'Gita KC', email: 'gita.kc@email.com', phone: '+9779841001004', dateOfBirth: '1998-11-25', gender: 'Female', role: 'user', status: 'active', createdAt: new Date(now - 90 * day).toISOString(), updatedAt: new Date(now - 3 * day).toISOString() },
  { id: 'u-005', fullName: 'Bikash Gurung', email: 'bikash.g@email.com', phone: '+9779841001005', dateOfBirth: '1991-07-30', gender: 'Male', role: 'user', status: 'active', createdAt: new Date(now - 60 * day).toISOString(), updatedAt: new Date(now - 7 * day).toISOString() },
  { id: 'u-006', fullName: 'Anita Rai', email: 'anita.rai@email.com', phone: '+9779841001006', dateOfBirth: '1994-02-14', gender: 'Female', role: 'user', status: 'active', createdAt: new Date(now - 45 * day).toISOString(), updatedAt: new Date(now - 1 * day).toISOString() },
  { id: 'u-007', fullName: 'Prakash Adhikari', email: 'prakash.a@email.com', phone: '+9779841001007', dateOfBirth: '1985-09-03', gender: 'Male', role: 'user', status: 'suspended', createdAt: new Date(now - 120 * day).toISOString(), updatedAt: new Date(now - 4 * day).toISOString() },
  { id: 'u-008', fullName: 'Sunita Magar', email: 'sunita.m@email.com', phone: '+9779841001008', dateOfBirth: '1997-12-01', gender: 'Female', role: 'user', status: 'active', createdAt: new Date(now - 30 * day).toISOString(), updatedAt: new Date(now - 0.5 * day).toISOString() },
  { id: 'u-009', fullName: 'Deepak Shrestha', email: 'deepak.s@email.com', phone: '+9779841001009', dateOfBirth: '1993-06-18', gender: 'Male', role: 'user', status: 'active', createdAt: new Date(now - 15 * day).toISOString(), updatedAt: new Date(now - 0.2 * day).toISOString() },
  { id: 'u-010', fullName: 'Maya Tamang', email: 'maya.t@email.com', phone: '+9779841001010', dateOfBirth: '1996-04-22', gender: 'Female', role: 'user', status: 'active', createdAt: new Date(now - 8 * day).toISOString(), updatedAt: new Date(now - 0.1 * day).toISOString() },
];

export const mockAccounts: Account[] = [
  { id: 'a-001', userId: 'u-001', accountNumber: '1001001001', accountType: 'savings', balance: 125000.5, currency: 'NPR', status: 'active', createdAt: new Date(now - 200 * day).toISOString(), updatedAt: new Date(now - 1 * day).toISOString(), userName: 'Ram Sharma', userEmail: 'ram.sharma@email.com' },
  { id: 'a-002', userId: 'u-002', accountNumber: '1001001002', accountType: 'checking', balance: 87500, currency: 'NPR', status: 'active', createdAt: new Date(now - 180 * day).toISOString(), updatedAt: new Date(now - 2 * day).toISOString(), userName: 'Sita Thapa', userEmail: 'sita.thapa@email.com' },
  { id: 'a-003', userId: 'u-003', accountNumber: '1001001003', accountType: 'wallet', balance: 5200, currency: 'NPR', status: 'suspended', createdAt: new Date(now - 150 * day).toISOString(), updatedAt: new Date(now - 1 * day).toISOString(), userName: 'Hari Bahadur', userEmail: 'hari.b@email.com' },
  { id: 'a-004', userId: 'u-004', accountNumber: '1001001004', accountType: 'savings', balance: 340000.75, currency: 'NPR', status: 'active', createdAt: new Date(now - 90 * day).toISOString(), updatedAt: new Date(now - 3 * day).toISOString(), userName: 'Gita KC', userEmail: 'gita.kc@email.com' },
  { id: 'a-005', userId: 'u-005', accountNumber: '1001001005', accountType: 'checking', balance: 15600.25, currency: 'NPR', status: 'active', createdAt: new Date(now - 60 * day).toISOString(), updatedAt: new Date(now - 5 * day).toISOString(), userName: 'Bikash Gurung', userEmail: 'bikash.g@email.com' },
  { id: 'a-006', userId: 'u-006', accountNumber: '1001001006', accountType: 'wallet', balance: 9800, currency: 'NPR', status: 'active', createdAt: new Date(now - 45 * day).toISOString(), updatedAt: new Date(now - 1 * day).toISOString(), userName: 'Anita Rai', userEmail: 'anita.rai@email.com' },
  { id: 'a-007', userId: 'u-007', accountNumber: '1001001007', accountType: 'savings', balance: 0, currency: 'NPR', status: 'closed', createdAt: new Date(now - 120 * day).toISOString(), updatedAt: new Date(now - 10 * day).toISOString(), userName: 'Prakash Adhikari', userEmail: 'prakash.a@email.com' },
  { id: 'a-008', userId: 'u-008', accountNumber: '1001001008', accountType: 'checking', balance: 45200.5, currency: 'NPR', status: 'active', createdAt: new Date(now - 30 * day).toISOString(), updatedAt: new Date(now - 0.5 * day).toISOString(), userName: 'Sunita Magar', userEmail: 'sunita.m@email.com' },
  { id: 'a-009', userId: 'u-009', accountNumber: '1001001009', accountType: 'savings', balance: 210000, currency: 'NPR', status: 'active', createdAt: new Date(now - 15 * day).toISOString(), updatedAt: new Date(now - 0.2 * day).toISOString(), userName: 'Deepak Shrestha', userEmail: 'deepak.s@email.com' },
  { id: 'a-010', userId: 'u-010', accountNumber: '1001001010', accountType: 'wallet', balance: 3200, currency: 'NPR', status: 'active', createdAt: new Date(now - 8 * day).toISOString(), updatedAt: new Date(now - 0.1 * day).toISOString(), userName: 'Maya Tamang', userEmail: 'maya.t@email.com' },
];

const txnTypes: Transaction['type'][] = ['deposit', 'withdrawal', 'transfer_in', 'transfer_out'];
const txnStatuses: Transaction['status'][] = ['completed', 'completed', 'completed', 'pending', 'failed'];

function genTxns(): Transaction[] {
  const list: Transaction[] = [];
  for (let i = 0; i < 60; i++) {
    const acc = mockAccounts[i % mockAccounts.length];
    const type = txnTypes[i % txnTypes.length];
    const amount = Math.round((Math.random() * 50000 + 500) * 100) / 100;
    const related = type.startsWith('transfer') ? mockAccounts[(i + 3) % mockAccounts.length] : null;
    list.push({
      id: `t-${String(i + 1).padStart(3, '0')}`,
      accountId: acc.id,
      type,
      amount,
      balanceAfter: acc.balance,
      reference: `TXN${Date.now().toString(36).toUpperCase()}${i}`,
      relatedAccountId: related?.id ?? null,
      status: txnStatuses[i % txnStatuses.length],
      remarks: type === 'deposit' ? 'Top-up' : type === 'withdrawal' ? 'ATM withdrawal' : 'P2P transfer',
      createdAt: new Date(now - (i * 0.4 + Math.random()) * day).toISOString(),
      accountNumber: acc.accountNumber,
      userName: acc.userName,
      relatedAccountNumber: related?.accountNumber ?? null,
      counterpartyName: related?.userName ?? null,
    });
  }
  return list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
}

export const mockTransactions = genTxns();

export const mockPayments: Payment[] = [
  { id: 'p-001', accountId: 'a-001', provider: 'khalti', amount: 5000, providerReference: 'KHL-REF-1001', status: 'completed', createdAt: new Date(now - 2 * day).toISOString(), updatedAt: new Date(now - 2 * day).toISOString(), accountNumber: '1001001001', userName: 'Ram Sharma' },
  { id: 'p-002', accountId: 'a-002', provider: 'esewa', amount: 2500, providerReference: 'ESW-REF-2002', status: 'completed', createdAt: new Date(now - 1.5 * day).toISOString(), updatedAt: new Date(now - 1.5 * day).toISOString(), accountNumber: '1001001002', userName: 'Sita Thapa' },
  { id: 'p-003', accountId: 'a-004', provider: 'khalti', amount: 10000, providerReference: 'KHL-REF-1003', status: 'pending', createdAt: new Date(now - 0.5 * day).toISOString(), updatedAt: new Date(now - 0.5 * day).toISOString(), accountNumber: '1001001004', userName: 'Gita KC' },
  { id: 'p-004', accountId: 'a-006', provider: 'esewa', amount: 1500, providerReference: 'ESW-REF-2004', status: 'failed', createdAt: new Date(now - 3 * day).toISOString(), updatedAt: new Date(now - 3 * day).toISOString(), accountNumber: '1001001006', userName: 'Anita Rai' },
  { id: 'p-005', accountId: 'a-008', provider: 'khalti', amount: 7500, providerReference: 'KHL-REF-1005', status: 'completed', createdAt: new Date(now - 4 * day).toISOString(), updatedAt: new Date(now - 4 * day).toISOString(), accountNumber: '1001001008', userName: 'Sunita Magar' },
  { id: 'p-006', accountId: 'a-009', provider: 'esewa', amount: 20000, providerReference: 'ESW-REF-2006', status: 'initiated', createdAt: new Date(now - 0.2 * day).toISOString(), updatedAt: new Date(now - 0.2 * day).toISOString(), accountNumber: '1001001009', userName: 'Deepak Shrestha' },
  { id: 'p-007', accountId: 'a-010', provider: 'khalti', amount: 800, providerReference: 'KHL-REF-1007', status: 'expired', createdAt: new Date(now - 6 * day).toISOString(), updatedAt: new Date(now - 5 * day).toISOString(), accountNumber: '1001001010', userName: 'Maya Tamang' },
  { id: 'p-008', accountId: 'a-001', provider: 'esewa', amount: 3500, providerReference: 'ESW-REF-2008', status: 'refunded', createdAt: new Date(now - 10 * day).toISOString(), updatedAt: new Date(now - 9 * day).toISOString(), accountNumber: '1001001001', userName: 'Ram Sharma' },
];

export function getDashboardStats(): DashboardStats {
  const activeUsers = mockUsers.filter((u) => u.status === 'active').length;
  const suspendedUsers = mockUsers.filter((u) => u.status === 'suspended').length;
  const activeAccounts = mockAccounts.filter((a) => a.status === 'active').length;
  const totalBalance = mockAccounts.reduce((s, a) => s + a.balance, 0);
  const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
  const todayTxns = mockTransactions.filter((t) => new Date(t.createdAt) >= todayStart);
  const monthStart = new Date(); monthStart.setDate(1); monthStart.setHours(0, 0, 0, 0);
  const monthTxns = mockTransactions.filter((t) => new Date(t.createdAt) >= monthStart);
  return {
    totalUsers: mockUsers.length, activeUsers, suspendedUsers,
    totalAccounts: mockAccounts.length, activeAccounts, totalBalance,
    totalTransactions: mockTransactions.length, todayTransactions: todayTxns.length,
    totalPayments: mockPayments.length,
    pendingPayments: mockPayments.filter((p) => p.status === 'pending' || p.status === 'initiated').length,
    volumeToday: todayTxns.reduce((s, t) => s + t.amount, 0),
    volumeMonth: monthTxns.reduce((s, t) => s + t.amount, 0),
  };
}

export function getChartData(days = 14): ChartPoint[] {
  const points: ChartPoint[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now - i * day);
    const dateStr = d.toISOString().slice(0, 10);
    const dayTxns = mockTransactions.filter((t) => t.createdAt.slice(0, 10) === dateStr);
    points.push({
      date: dateStr,
      deposits: dayTxns.filter((t) => t.type === 'deposit').reduce((s, t) => s + t.amount, 0),
      withdrawals: dayTxns.filter((t) => t.type === 'withdrawal').reduce((s, t) => s + t.amount, 0),
      transfers: dayTxns.filter((t) => t.type === 'transfer_in' || t.type === 'transfer_out').reduce((s, t) => s + t.amount, 0),
      count: dayTxns.length,
    });
  }
  return points;
}
