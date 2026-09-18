# Banking Admin Panel

Full-featured React admin panel for the Banking App.

## Features

- **Dashboard** – Stats cards, 14-day volume chart (deposits / withdrawals / transfers), recent transactions
- **User Management** – Search, filter by status/role, suspend / activate users
- **Account Management** – Search, filter by type/status, suspend / activate / close accounts
- **Transactions** – Search, filter by type/status, reverse completed transactions
- **Payments** – View Khalti & eSewa payments with status filters
- **Auth** – Login with JWT (mock mode works offline), protected routes, role-aware UI
- **Responsive** – Mobile sidebar, modern Tailwind UI

## Tech Stack

- React 19 + TypeScript + Vite
- React Router 7
- Tailwind CSS 4
- Recharts
- Lucide icons

## Quick Start

```bash
cd banking_admin
npm install
npm run dev
```

Open http://localhost:3000

### Demo login

| Email            | Password  |
|------------------|-----------|
| admin@bank.com   | admin123  |

## Mock vs Real API

By default the app runs in **mock mode** (`VITE_USE_MOCK` is not `false`) so everything works without a backend.

To connect to your real Node/Express backend:

1. Create `.env`:
   ```
   VITE_USE_MOCK=false
   VITE_API_URL=http://localhost:5000/api
   ```
2. Ensure admin endpoints exist (or extend the existing backend):
   - `POST /api/auth/login` (admin role)
   - `GET  /api/admin/stats`
   - `GET  /api/admin/chart?days=14`
   - `GET  /api/admin/users`
   - `PATCH /api/admin/users/:id/status`
   - `GET  /api/admin/accounts`
   - `PATCH /api/admin/accounts/:id/status`
   - `GET  /api/admin/transactions`
   - `POST /api/admin/transactions/:id/reverse`
   - `GET  /api/admin/payments`

Vite proxies `/api` → `http://localhost:5000` in development.

## Project structure

```
src/
  components/layout/   # Sidebar, Header, AppLayout
  components/ui/       # Button, Card, Badge, Input, Pagination, Spinner
  context/             # AuthContext
  data/                # Mock data (users, accounts, transactions, payments)
  pages/               # Login, Dashboard, Users, Accounts, Transactions, Payments
  services/api.ts      # API layer (mock + real)
  types/               # Shared TypeScript types matching your SQL schema
  utils/               # cn(), formatCurrency, formatDate, etc.
```

## Scripts

| Command        | Description              |
|----------------|--------------------------|
| `npm run dev`  | Start dev server (port 3000) |
| `npm run build`| Production build         |
| `npm run preview` | Preview production build |

