import { useEffect, useState, useCallback } from 'react';
import { Search, Shield, ShieldOff } from 'lucide-react';
import { fetchUsers, updateUserStatus } from '../services/api';
import type { User, PaginatedResult } from '../types';
import { formatDate } from '../utils/format';
import { Card } from '../components/ui/Card';
import { Input, Select } from '../components/ui/Input';
import { Button } from '../components/ui/Button';
import { StatusBadge } from '../components/ui/Badge';
import { Pagination } from '../components/ui/Pagination';
import { Spinner, EmptyState } from '../components/ui/Spinner';

export function UsersPage() {
  const [result, setResult] = useState<PaginatedResult<User> | null>(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [role, setRole] = useState('');
  const [actionId, setActionId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchUsers({ page, limit: 10, search, status, role });
      setResult(data);
    } finally {
      setLoading(false);
    }
  }, [page, search, status, role]);

  useEffect(() => { load(); }, [load]);

  async function toggleStatus(user: User) {
    setActionId(user.id);
    try {
      const next = user.status === 'active' ? 'suspended' : 'active';
      await updateUserStatus(user.id, next);
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
              placeholder="Search name, email, phone…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            />
          </div>
          <Select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }} className="w-full sm:w-36">
            <option value="">All status</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
          </Select>
          <Select value={role} onChange={(e) => { setRole(e.target.value); setPage(1); }} className="w-full sm:w-36">
            <option value="">All roles</option>
            <option value="user">User</option>
            <option value="admin">Admin</option>
          </Select>
        </div>

        {loading ? <Spinner /> : !result?.data.length ? (
          <EmptyState title="No users found" description="Try adjusting filters" />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-100 text-xs uppercase tracking-wider text-slate-400">
                    <th className="px-5 py-3 font-medium">Name</th>
                    <th className="px-5 py-3 font-medium">Contact</th>
                    <th className="px-5 py-3 font-medium">Role</th>
                    <th className="px-5 py-3 font-medium">Status</th>
                    <th className="px-5 py-3 font-medium">Joined</th>
                    <th className="px-5 py-3 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {result.data.map((u) => (
                    <tr key={u.id} className="border-b border-slate-50 hover:bg-slate-50/50">
                      <td className="px-5 py-3">
                        <p className="font-medium text-slate-900">{u.fullName}</p>
                        <p className="text-xs text-slate-400">{u.gender} · {u.dateOfBirth}</p>
                      </td>
                      <td className="px-5 py-3">
                        <p className="text-slate-700">{u.email}</p>
                        <p className="text-xs text-slate-400">{u.phone}</p>
                      </td>
                      <td className="px-5 py-3"><StatusBadge status={u.role} /></td>
                      <td className="px-5 py-3"><StatusBadge status={u.status} /></td>
                      <td className="px-5 py-3 text-slate-500">{formatDate(u.createdAt)}</td>
                      <td className="px-5 py-3">
                        {u.role !== 'admin' && (
                          <Button
                            size="sm"
                            variant={u.status === 'active' ? 'danger' : 'success'}
                            loading={actionId === u.id}
                            onClick={() => toggleStatus(u)}
                          >
                            {u.status === 'active' ? (
                              <><ShieldOff className="h-3.5 w-3.5" /> Suspend</>
                            ) : (
                              <><Shield className="h-3.5 w-3.5" /> Activate</>
                            )}
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
