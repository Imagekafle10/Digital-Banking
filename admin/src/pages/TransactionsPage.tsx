import { useEffect, useState, useCallback } from 'react';
import { Search, RotateCcw } from 'lucide-react';
import { fetchTransactions, reverseTransaction } from '../services/api';
import type { Transaction, PaginatedResult } from '../types';
import { formatCurrency, formatDateTime } from '../utils/format';
import { Card } from '../components/ui/Card';
import { Select } from '../components/ui/Input';
import { Button } from '../components/ui/Button';
import { StatusBadge } from '../components/ui/Badge';
import { Pagination } from '../components/ui/Pagination';
import { Spinner, EmptyState } from '../components/ui/Spinner';

export function TransactionsPage() {
  const [result, setResult] = useState<PaginatedResult<Transaction> | null>(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [type, setType] = useState('');
  const [actionId, setActionId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setResult(await fetchTransactions({ page, limit: 12, search, status, type }));
    } finally {
      setLoading(false);
    }
  }, [page, search, status, type]);

  useEffect(() => { load(); }, [load]);

  async function handleReverse(t: Transaction) {
    if (!confirm(`Reverse transaction ${t.reference}?`)) return;
    setActionId(t.id);
    try {
      await reverseTransaction(t.id);
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
              placeholder="Search reference, user, account…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            />
          </div>
          <Select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} className="w-full sm:w-36">
            <option value="">All status</option>
            <option value="completed">Completed</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
            <option value="reversed">Reversed</option>
          </Select>
          <Select value={type} onChange={(e) => { setType(e.target.value); setPage(1); }} className="w-full sm:w-40">
            <option value="">All types</option>
            <option value="deposit">Deposit</option>
            <option value="withdrawal">Withdrawal</option>
            <option value="transfer_in">Transfer In</option>
            <option value="transfer_out">Transfer Out</option>
          </Select>
        </div>

        {loading ? <Spinner /> : !result?.data.length ? (
          <EmptyState title="No transactions found" />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 text-xs uppercase tracking-wider text-slate-400">
                    <th className="px-5 py-3 font-medium">Reference</th>
                    <th className="px-5 py-3 font-medium">User / Account</th>
                    <th className="px-5 py-3 font-medium">Type</th>
                    <th className="px-5 py-3 font-medium">Amount</th>
                    <th className="px-5 py-3 font-medium">Counterparty</th>
                    <th className="px-5 py-3 font-medium">Status</th>
                    <th className="px-5 py-3 font-medium">Date</th>
                    <th className="px-5 py-3 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {result.data.map((t) => (
                    <tr key={t.id} className="border-b border-slate-50 hover:bg-slate-50/50">
                      <td className="px-5 py-3 font-mono text-xs text-slate-600">{t.reference}</td>
                      <td className="px-5 py-3">
                        <p className="text-slate-800">{t.userName}</p>
                        <p className="font-mono text-xs text-slate-400">{t.accountNumber}</p>
                      </td>
                      <td className="px-5 py-3 capitalize text-slate-600">{t.type.replace('_', ' ')}</td>
                      <td className="px-5 py-3 font-semibold text-slate-900">{formatCurrency(t.amount)}</td>
                      <td className="px-5 py-3 text-slate-600">
                        {t.counterpartyName || '—'}
                        {t.relatedAccountNumber && (
                          <p className="font-mono text-xs text-slate-400">{t.relatedAccountNumber}</p>
                        )}
                      </td>
                      <td className="px-5 py-3"><StatusBadge status={t.status} /></td>
                      <td className="px-5 py-3 text-slate-500 whitespace-nowrap">{formatDateTime(t.createdAt)}</td>
                      <td className="px-5 py-3">
                        {t.status === 'completed' && (
                          <Button size="sm" variant="secondary" loading={actionId === t.id}
                            onClick={() => handleReverse(t)}>
                            <RotateCcw className="h-3.5 w-3.5" /> Reverse
                          </Button>
                        )}
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
