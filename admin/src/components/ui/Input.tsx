import { cn } from '../../utils/cn';

interface Props extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export function Input({ label, error, className, id, ...rest }: Props) {
  return (
    <div className="space-y-1.5">
      {label && <label htmlFor={id} className="block text-sm font-medium text-slate-700">{label}</label>}
      <input
        id={id}
        className={cn(
          'w-full rounded-lg border border-slate-200 bg-white px-3.5 py-2.5 text-sm',
          'placeholder:text-slate-400 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 transition-colors',
          error && 'border-red-400 focus:border-red-500 focus:ring-red-500/20',
          className,
        )}
        {...rest}
      />
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  );
}

export function Select({ label, error, className, id, children, ...rest }: React.SelectHTMLAttributes<HTMLSelectElement> & { label?: string; error?: string }) {
  return (
    <div className="space-y-1.5">
      {label && <label htmlFor={id} className="block text-sm font-medium text-slate-700">{label}</label>}
      <select
        id={id}
        className={cn(
          'w-full rounded-lg border border-slate-200 bg-white px-3.5 py-2.5 text-sm',
          'focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20',
          className,
        )}
        {...rest}
      >
        {children}
      </select>
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  );
}
