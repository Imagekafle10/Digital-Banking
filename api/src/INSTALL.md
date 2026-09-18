# Admin API – Install Guide

Copy these files into your existing `api` project, then wire the route in `app.ts`.

## 1. Copy files

From this `admin_backend` folder into your `api/src`:

| Source file                         | Destination in your api          |
|-------------------------------------|----------------------------------|
| `middlewares/requireAdmin.ts`       | `src/middlewares/requireAdmin.ts`|
| `models/AdminQueries.ts`            | `src/models/AdminQueries.ts`     |
| `services/adminService.ts`          | `src/services/adminService.ts`   |
| `controllers/adminControllers.ts`   | `src/controllers/adminControllers.ts` |
| `routes/adminRoutes.ts`             | `src/routes/adminRoutes.ts`      |
| `types/admin.types.ts`              | `src/types/admin.types.ts`       |

## 2. Fix import paths (if needed)

Your auth middleware path may differ. In these files:

- `middlewares/requireAdmin.ts`
- `controllers/adminControllers.ts`
- `routes/adminRoutes.ts`

The import is:

```ts
import auth from "../middlewares/auth/auth";
import { AuthRequest } from "../middlewares/auth/auth";
```

Change to match your actual auth file location (e.g. `../middlewares/auth` if that’s how you export it).

`AuthRequest` must expose:

```ts
req.user?: { id: string; role: "user" | "admin" }
```

(Your existing middleware already does this.)

## 3. Register routes in `app.ts`

```ts
import adminRoutes from "./routes/adminRoutes";

// ... existing middleware (cors, helmet, json, etc.)

app.use("/api/auth", authRoutes);
app.use("/api/banking", bankingRoutes);
app.use("/api/payment", paymentRoutes);
app.use("/api/admin", adminRoutes);   // ← add this line
```

## 4. CORS – allow the admin panel origin

In `app.ts` allowedOrigins, include:

```ts
const allowedOrigins = [
  "http://localhost:3000",   // React admin (Vite)
  "http://127.0.0.1:3000",
  "http://localhost:8888",
  "http://192.168.18.201:8888",
];
```

## 5. Create an admin user in MySQL

```sql
-- Option A: promote an existing user
UPDATE users SET role = 'admin' WHERE email = 'your@email.com';

-- Option B: insert a dedicated admin (password must be a bcrypt hash)
-- Generate hash in Node:  await bcrypt.hash('admin123', 12)
INSERT INTO users (id, fullName, email, password, phone, dateOfBirth, gender, role, status)
VALUES (
  UUID(),
  'Admin User',
  'admin@bank.com',
  '$2b$12$REPLACE_WITH_REAL_BCRYPT_HASH',
  '+9779800000001',
  '1990-01-15',
  'Male',
  'admin',
  'active'
);
```

Quick way to get a bcrypt hash from your project:

```bash
node -e "require('bcryptjs').hash('admin123', 12).then(console.log)"
# or bcrypt instead of bcryptjs – use whatever your project uses
```

## 6. Restart API

```bash
npm run dev
```

You should see routes under `/api/admin/*` working.

## Endpoints (all require Bearer token + admin role)

| Method | Path                              | Description              |
|--------|-----------------------------------|--------------------------|
| GET    | /api/admin/stats                  | Dashboard stats          |
| GET    | /api/admin/chart?days=14          | Chart data               |
| GET    | /api/admin/users                  | List users (paginated)   |
| PATCH  | /api/admin/users/:id/status       | `{ "status": "active" \| "suspended" }` |
| GET    | /api/admin/accounts               | List accounts            |
| PATCH  | /api/admin/accounts/:id/status    | `{ "status": "active" \| "suspended" \| "closed" }` |
| GET    | /api/admin/transactions           | List transactions        |
| POST   | /api/admin/transactions/:id/reverse | Reverse a completed txn |
| GET    | /api/admin/payments               | List payments            |

## 7. Admin panel env

In the React admin project `.env`:

```
VITE_USE_MOCK=false
VITE_API_URL=http://localhost:5000/api
```

Or use the Vite proxy (`VITE_API_URL` unset → requests go to `/api` and are proxied to port 5000) — then CORS is less of an issue for same-machine dev.
