import { useEffect, useState, useCallback } from 'react';
import { Search, Ban, CheckCircle, XCircle } from 'lucide-react';
import { fetchAccounts, updateAccountStatus } from '../services/api';
import type { Account, PaginatedResult, AccountStatus } from '../types';
import { formatCurrency, formatDate } from '../utils/format';
import { Card } from '../components/ui/Card';
import { Select } from '../components/ui/Input';
import { Button } from '../components/ui/Button';
import { StatusBadge } from '../components/ui/Badge';
import { Pagination } from '../components/ui/Pagination';
import { Spinner, EmptyState } from '../components/ui/Spinner';

export function AccountsPage() {
  const [result, setResult] = useState<PaginatedResult<Account> | null>(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [type, setType] = useState('');
  const [actionId, setActionId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setResult(await fetchAccounts({ page, limit: 10, search, status, type }));
    } finally {
      setLoading(false);
    }
  }, [page, search, status, type]);

  useEffect(() => { load(); }, [load]);

  async function setAccountStatus(acc: Account, next: AccountStatus) {
    setActionId(acc.id);
    try {
      await updateAccountStatus(acc.id, next);
      await load();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setActionId(null);
    }
  }

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex flex-col gap-3 border-b border-slate-100 p-4 sm:flex-row sm:items-center">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              className="w-full rounded-lg border border-slate-200 py-2 pl-9 pr-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
              placeholder="Search account #, name, email…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            />
          </div>
          <Select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} className="w-full sm:w-36">
            <option value="">All status</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
            <option value="closed">Closed</option>
          </Select>
          <Select value={type} onChange={(e) => { setType(e.target.value); setPage(1); }} className="w-full sm:w-36">
            <option value="">All types</option>
            <option value="savings">Savings</option>
            <option value="checking">Checking</option>
            <option value="wallet">Wallet</option>
          </Select>
        </div>

        {loading ? <Spinner /> : !result?.data.length ? (
          <EmptyState title="No accounts found" />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 text-xs uppercase tracking-wider text-slate-400">
                    <th className="px-5 py-3 font-medium">Account</th>
                    <th className="px-5 py-3 font-medium">Owner</th>
                    <th className="px-5 py-3 font-medium">Type</th>
                    <th className="px-5 py-3 font-medium">Balance</th>
                    <th className="px-5 py-3 font-medium">Status</th>
                    <th className="px-5 py-3 font-medium">Opened</th>
                    <th className="px-5 py-3 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {result.data.map((a) => (
                    <tr key={a.id} className="border-b border-slate-50 hover:bg-slate-50/50">
                      <td className="px-5 py-3 font-mono text-sm font-medium text-slate-800">{a.accountNumber}</td>
                      <td className="px-5 py-3">
                        <p className="text-slate-800">{a.userName}</p>
                        <p className="text-xs text-slate-400">{a.userEmail}</p>
                      </td>
                      <td className="px-5 py-3 capitalize text-slate-600">{a.accountType}</td>
                      <td className="px-5 py-3 font-semibold text-slate-900">{formatCurrency(a.balance, a.currency)}</td>
                      <td className="px-5 py-3"><StatusBadge status={a.status} /></td>
                      <td className="px-5 py-3 text-slate-500">{formatDate(a.createdAt)}</td>
                      <td className="px-5 py-3">
                        <div className="flex gap-1.5">
                          {a.status === 'active' && (
                            <Button size="sm" variant="danger" loading={actionId === a.id}
                              onClick={() => setAccountStatus(a, 'suspended')}>
                              <Ban className="h-3.5 w-3.5" /> Suspend
                            </Button>
                          )}
                          {a.status === 'suspended' && (
                            <>
                              <Button size="sm" variant="success" loading={actionId === a.id}
                                onClick={() => setAccountStatus(a, 'active')}>
                                <CheckCircle className="h-3.5 w-3.5" /> Activate
                              </Button>
                              <Button size="sm" variant="secondary" loading={actionId === a.id}
                                onClick={() => setAccountStatus(a, 'closed')}>
                                <XCircle className="h-3.5 w-3.5" /> Close
                              </Button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <Pagination page={result.page} totalPages={result.totalPages} total={result.total} onPageChange={setPage} />
          </>
        )}
      </Card>
    </div>
  );
}
