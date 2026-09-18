import { useEffect, useState, useCallback } from 'react';
import { Search } from 'lucide-react';
import { fetchPayments } from '../services/api';
import type { Payment, PaginatedResult } from '../types';
import { formatCurrency, formatDateTime } from '../utils/format';
import { Card } from '../components/ui/Card';
import { Select } from '../components/ui/Input';
import { StatusBadge } from '../components/ui/Badge';
import { Pagination } from '../components/ui/Pagination';
import { Spinner, EmptyState } from '../components/ui/Spinner';

export function PaymentsPage() {
  const [result, setResult] = useState<PaginatedResult<Payment> | null>(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [type, setType] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setResult(await fetchPayments({ page, limit: 10, search, status, type }));
    } finally {
      setLoading(false);
    }
  }, [page, search, status, type]);

  useEffect(() => { load(); }, [load]);

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex flex-col gap-3 border-b border-slate-100 p-4 sm:flex-row sm:items-center">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              className="w-full rounded-lg border border-slate-200 py-2 pl-9 pr-3 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
              placeholder="Search reference, user, account…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            />
          </div>
          <Select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} className="w-full sm:w-36">
            <option value="">All status</option>
            <option value="completed">Completed</option>
            <option value="pending">Pending</option>
            <option value="initiated">Initiated</option>
            <option value="failed">Failed</option>
            <option value="expired">Expired</option>
            <option value="refunded">Refunded</option>
          </Select>
          <Select value={type} onChange={(e) => { setType(e.target.value); setPage(1); }} className="w-full sm:w-36">
            <option value="">All providers</option>
            <option value="khalti">Khalti</option>
            <option value="esewa">eSewa</option>
          </Select>
        </div>

        {loading ? <Spinner /> : !result?.data.length ? (
          <EmptyState title="No payments found" />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 text-xs uppercase tracking-wider text-slate-400">
                    <th className="px-5 py-3 font-medium">Reference</th>
                    <th className="px-5 py-3 font-medium">User / Account</th>
                    <th className="px-5 py-3 font-medium">Provider</th>
                    <th className="px-5 py-3 font-medium">Amount</th>
                    <th className="px-5 py-3 font-medium">Status</th>
                    <th className="px-5 py-3 font-medium">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {result.data.map((p) => (
                    <tr key={p.id} className="border-b border-slate-50 hover:bg-slate-50/50">
                      <td className="px-5 py-3 font-mono text-xs text-slate-600">{p.providerReference}</td>
                      <td className="px-5 py-3">
                        <p className="text-slate-800">{p.userName}</p>
                        <p className="font-mono text-xs text-slate-400">{p.accountNumber}</p>
                      </td>
                      <td className="px-5 py-3 capitalize font-medium text-slate-700">{p.provider}</td>
                      <td className="px-5 py-3 font-semibold text-slate-900">{formatCurrency(p.amount)}</td>
                      <td className="px-5 py-3"><StatusBadge status={p.status} /></td>
                      <td className="px-5 py-3 text-slate-500 whitespace-nowrap">{formatDateTime(p.createdAt)}</td>
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
