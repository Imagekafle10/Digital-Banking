import { useEffect, useState } from 'react';
import {
  Users, CreditCard, ArrowLeftRight, Wallet, TrendingUp, AlertCircle,
} from 'lucide-react';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts';
import { fetchDashboardStats, fetchChartData, fetchTransactions } from '../services/api';
import type { DashboardStats, ChartPoint, Transaction } from '../types';
import { formatCurrency, formatNumber, formatRelative } from '../utils/format';
import { Card, CardBody, CardHeader } from '../components/ui/Card';
import { StatusBadge } from '../components/ui/Badge';
import { Spinner } from '../components/ui/Spinner';

function StatCard({
  title, value, sub, icon: Icon, color,
}: {
  title: string; value: string; sub?: string;
  icon: React.ElementType; color: string;
}) {
  return (
    <Card>
      <CardBody className="flex items-start gap-4">
        <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${color}`}>
          <Icon className="h-5 w-5" />
        </div>
        <div className="min-w-0">
          <p className="text-sm text-slate-500">{title}</p>
          <p className="mt-0.5 text-xl font-bold text-slate-900 truncate">{value}</p>
          {sub && <p className="mt-0.5 text-xs text-slate-400">{sub}</p>}
        </div>
      </CardBody>
    </Card>
  );
}

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [chart, setChart] = useState<ChartPoint[]>([]);
  const [recent, setRecent] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetchDashboardStats(),
      fetchChartData(14),
      fetchTransactions({ page: 1, limit: 8 }),
    ]).then(([s, c, t]) => {
      setStats(s);
      setChart(c);
      setRecent(t.data);
    }).finally(() => setLoading(false));
  }, []);

  if (loading || !stats) return <Spinner />;

  return (
    <div className="space-y-6">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard title="Total Users" value={formatNumber(stats.totalUsers)}
          sub={`${stats.activeUsers} active · ${stats.suspendedUsers} suspended`}
          icon={Users} color="bg-primary-50 text-primary-600" />
        <StatCard title="Total Balance" value={formatCurrency(stats.totalBalance)}
          sub={`${stats.activeAccounts} active accounts`}
          icon={CreditCard} color="bg-emerald-50 text-emerald-600" />
        <StatCard title="Transactions" value={formatNumber(stats.totalTransactions)}
          sub={`${stats.todayTransactions} today · ${formatCurrency(stats.volumeToday)}`}
          icon={ArrowLeftRight} color="bg-violet-50 text-violet-600" />
        <StatCard title="Payments" value={formatNumber(stats.totalPayments)}
          sub={`${stats.pendingPayments} pending`}
          icon={Wallet} color="bg-amber-50 text-amber-600" />
      </div>

      <div className="grid gap-6 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardHeader title="Transaction Volume" description="Last 14 days" />
          <CardBody className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chart}>
                <defs>
                  <linearGradient id="gDep" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#1652f0" stopOpacity={0.3} />
                    <stop offset="100%" stopColor="#1652f0" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="gWdr" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#ef4444" stopOpacity={0.3} />
                    <stop offset="100%" stopColor="#ef4444" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(v) => v.slice(5)} />
                <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
                <Tooltip
                  formatter={(value: number) => formatCurrency(value)}
                  contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0', fontSize: 13 }}
                />
                <Legend />
                <Area type="monotone" dataKey="deposits" name="Deposits" stroke="#1652f0" fill="url(#gDep)" strokeWidth={2} />
                <Area type="monotone" dataKey="withdrawals" name="Withdrawals" stroke="#ef4444" fill="url(#gWdr)" strokeWidth={2} />
                <Area type="monotone" dataKey="transfers" name="Transfers" stroke="#8b5cf6" fill="none" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader title="Quick Stats" description="This month" />
          <CardBody className="space-y-4">
            <div className="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-3">
              <div className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4 text-emerald-600" />
                <span className="text-sm text-slate-600">Month volume</span>
              </div>
              <span className="text-sm font-semibold text-slate-900">{formatCurrency(stats.volumeMonth)}</span>
            </div>
            <div className="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-3">
              <div className="flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-amber-600" />
                <span className="text-sm text-slate-600">Pending payments</span>
              </div>
              <span className="text-sm font-semibold text-slate-900">{stats.pendingPayments}</span>
            </div>
            <div className="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-3">
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4 text-primary-600" />
                <span className="text-sm text-slate-600">Suspended users</span>
              </div>
              <span className="text-sm font-semibold text-slate-900">{stats.suspendedUsers}</span>
            </div>
            <div className="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-3">
              <div className="flex items-center gap-2">
                <CreditCard className="h-4 w-4 text-violet-600" />
                <span className="text-sm text-slate-600">Active accounts</span>
              </div>
              <span className="text-sm font-semibold text-slate-900">{stats.activeAccounts}</span>
            </div>
          </CardBody>
        </Card>
      </div>

      <Card>
        <CardHeader title="Recent Transactions" description="Latest activity across all accounts" />
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 text-xs uppercase tracking-wider text-slate-400">
                <th className="px-5 py-3 font-medium">Reference</th>
                <th className="px-5 py-3 font-medium">User</th>
                <th className="px-5 py-3 font-medium">Type</th>
                <th className="px-5 py-3 font-medium">Amount</th>
                <th className="px-5 py-3 font-medium">Status</th>
                <th className="px-5 py-3 font-medium">When</th>
              </tr>
            </thead>
            <tbody>
              {recent.map((t) => (
                <tr key={t.id} className="border-b border-slate-50 hover:bg-slate-50/50">
                  <td className="px-5 py-3 font-mono text-xs text-slate-600">{t.reference.slice(0, 14)}…</td>
                  <td className="px-5 py-3 text-slate-800">{t.userName}</td>
                  <td className="px-5 py-3 capitalize text-slate-600">{t.type.replace('_', ' ')}</td>
                  <td className="px-5 py-3 font-medium text-slate-900">{formatCurrency(t.amount)}</td>
                  <td className="px-5 py-3"><StatusBadge status={t.status} /></td>
                  <td className="px-5 py-3 text-slate-500">{formatRelative(t.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
