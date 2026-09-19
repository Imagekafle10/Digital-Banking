import { cn } from '../../utils/cn';

const variants: Record<string, string> = {
  default: 'bg-slate-100 text-slate-700',
  success: 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200',
  warning: 'bg-amber-50 text-amber-700 ring-1 ring-amber-200',
  danger: 'bg-red-50 text-red-700 ring-1 ring-red-200',
  info: 'bg-primary-50 text-primary-700 ring-1 ring-primary-200',
  navy: 'bg-primary-100 text-primary-900 ring-1 ring-primary-300',
};

export function Badge({ children, variant = 'default', className }: { children: React.ReactNode; variant?: keyof typeof variants; className?: string }) {
  return (
    <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', variants[variant], className)}>
      {children}
    </span>
  );
}

export function StatusBadge({ status }: { status: string }) {
  const map: Record<string, keyof typeof variants> = {
    active: 'success', completed: 'success',
    suspended: 'warning', pending: 'warning', initiated: 'warning',
    closed: 'default', failed: 'danger', expired: 'danger', reversed: 'navy',
    refunded: 'info', admin: 'navy', user: 'info',
  };
  return <Badge variant={map[status] || 'default'}>{status}</Badge>;
}
