/**
 * Banking Admin API layer.
 * Set VITE_USE_MOCK=false and VITE_API_URL=http://localhost:5000/api in .env
 */
import type {
  User,
  Account,
  Transaction,
  Payment,
  DashboardStats,
  ChartPoint,
  LoginResponse,
  PaginatedResult,
  ListParams,
  UserStatus,
  AccountStatus,
} from "../types";
import {
  mockUsers,
  mockAccounts,
  mockTransactions,
  mockPayments,
  getDashboardStats,
  getChartData,
} from "../data/mockData";

const USE_MOCK = import.meta.env.VITE_USE_MOCK !== "false";
const BASE = import.meta.env.VITE_API_URL || "/api";

function getToken(): string | null {
  return localStorage.getItem("admin_token");
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const res = await fetch(`${BASE}${path}`, {
    ...options,
    headers,
    credentials: "include",
  });

  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as { message?: string };
    if (res.status === 401) {
      localStorage.removeItem("admin_token");
      localStorage.removeItem("admin_user");
      if (!window.location.pathname.includes("/login")) {
        window.location.href = "/login";
      }
    }
    throw new Error(body.message || `Request failed (${res.status})`);
  }
  return res.json();
}

function paginate<T>(items: T[], params: ListParams = {}): PaginatedResult<T> {
  const page = params.page ?? 1;
  const limit = params.limit ?? 10;
  const start = (page - 1) * limit;
  return {
    data: items.slice(start, start + limit),
    total: items.length,
    page,
    limit,
    totalPages: Math.ceil(items.length / limit) || 1,
  };
}

function filterBySearch<T extends Record<string, unknown>>(
  items: T[],
  search: string | undefined,
  fields: (keyof T)[],
): T[] {
  if (!search?.trim()) return items;
  const q = search.toLowerCase();
  return items.filter((item) =>
    fields.some((f) =>
      String(item[f] ?? "")
        .toLowerCase()
        .includes(q),
    ),
  );
}

function delay(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

// ─── Auth ───────────────────────────────────────────────────────────────────

export async function login(
  email: string,
  password: string,
): Promise<LoginResponse> {
  if (USE_MOCK) {
    await delay(600);
    if (email === "admin@bank.com" && password === "admin123") {
      const user = mockUsers.find((u) => u.role === "admin")!;
      const token = "mock-admin-jwt-token";
      const safe = {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
      };
      localStorage.setItem("admin_token", token);
      localStorage.setItem("admin_user", JSON.stringify(safe));
      return { user: safe, accessToken: token };
    }
    throw new Error("Invalid email or password");
  }

  // Your backend returns: { message, data: { user, accessToken } }
  const raw = await request<{
    message?: string;
    data?: { user?: LoginResponse["user"]; accessToken?: string };
    user?: LoginResponse["user"];
    accessToken?: string;
  }>("/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });

  const accessToken = raw.data?.accessToken || raw.accessToken;
  const userRaw = raw.data?.user || raw.user;

  if (!accessToken) {
    throw new Error("Login succeeded but no accessToken was returned");
  }
  if (!userRaw) {
    throw new Error("Login succeeded but no user was returned");
  }
  if (String(userRaw.role).toLowerCase() !== "admin") {
    throw new Error("This account is not an admin");
  }

  const safeUser = {
    id: userRaw.id,
    fullName: userRaw.fullName,
    email: userRaw.email,
    role: userRaw.role,
  };

  localStorage.setItem("admin_token", accessToken);
  localStorage.setItem("admin_user", JSON.stringify(safeUser));
  return { user: safeUser, accessToken };
}

export function logout(): void {
  localStorage.removeItem("admin_token");
  localStorage.removeItem("admin_user");
}

export function getStoredUser() {
  try {
    const raw = localStorage.getItem("admin_user");
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function isAuthenticated(): boolean {
  return !!getToken() && !!getStoredUser();
}

// ─── Dashboard ──────────────────────────────────────────────────────────────

export async function fetchDashboardStats(): Promise<DashboardStats> {
  if (USE_MOCK) {
    await delay(300);
    return getDashboardStats();
  }
  return request<DashboardStats>("/admin/stats");
}

export async function fetchChartData(days = 14): Promise<ChartPoint[]> {
  if (USE_MOCK) {
    await delay(200);
    return getChartData(days);
  }
  return request<ChartPoint[]>(`/admin/chart?days=${days}`);
}

// ─── Users ──────────────────────────────────────────────────────────────────

export async function fetchUsers(
  params: ListParams = {},
): Promise<PaginatedResult<User>> {
  if (USE_MOCK) {
    await delay(350);
    let items = [...mockUsers];
    items = filterBySearch(
      items as unknown as Record<string, unknown>[],
      params.search,
      ["fullName", "email", "phone"],
    ) as unknown as User[];
    if (params.status) items = items.filter((u) => u.status === params.status);
    if (params.role) items = items.filter((u) => u.role === params.role);
    return paginate(items, params);
  }
  const q = new URLSearchParams(
    Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== "")
      .map(([k, v]) => [k, String(v)]),
  ).toString();
  return request(`/admin/users?${q}`);
}

export async function updateUserStatus(
  id: string,
  status: UserStatus,
): Promise<User> {
  if (USE_MOCK) {
    await delay(400);
    const u = mockUsers.find((x) => x.id === id);
    if (!u) throw new Error("User not found");
    u.status = status;
    u.updatedAt = new Date().toISOString();
    return { ...u };
  }
  return request(`/admin/users/${id}/status`, {
    method: "PATCH",
    body: JSON.stringify({ status }),
  });
}

// ─── Accounts ───────────────────────────────────────────────────────────────

export async function fetchAccounts(
  params: ListParams = {},
): Promise<PaginatedResult<Account>> {
  if (USE_MOCK) {
    await delay(350);
    let items = [...mockAccounts];
    items = filterBySearch(
      items as unknown as Record<string, unknown>[],
      params.search,
      ["accountNumber", "userName", "userEmail"],
    ) as unknown as Account[];
    if (params.status) items = items.filter((a) => a.status === params.status);
    if (params.type) items = items.filter((a) => a.accountType === params.type);
    return paginate(items, params);
  }
  const q = new URLSearchParams(
    Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== "")
      .map(([k, v]) => [k, String(v)]),
  ).toString();
  return request(`/admin/accounts?${q}`);
}

export async function updateAccountStatus(
  id: string,
  status: AccountStatus,
): Promise<Account> {
  if (USE_MOCK) {
    await delay(400);
    const a = mockAccounts.find((x) => x.id === id);
    if (!a) throw new Error("Account not found");
    a.status = status;
    a.updatedAt = new Date().toISOString();
    return { ...a };
  }
  return request(`/admin/accounts/${id}/status`, {
    method: "PATCH",
    body: JSON.stringify({ status }),
  });
}

// ─── Transactions ───────────────────────────────────────────────────────────

export async function fetchTransactions(
  params: ListParams = {},
): Promise<PaginatedResult<Transaction>> {
  if (USE_MOCK) {
    await delay(350);
    let items = [...mockTransactions];
    items = filterBySearch(
      items as unknown as Record<string, unknown>[],
      params.search,
      ["reference", "accountNumber", "userName", "counterpartyName"],
    ) as unknown as Transaction[];
    if (params.status) items = items.filter((t) => t.status === params.status);
    if (params.type) items = items.filter((t) => t.type === params.type);
    if (params.startDate)
      items = items.filter((t) => t.createdAt >= params.startDate!);
    if (params.endDate) {
      items = items.filter((t) => t.createdAt <= params.endDate! + "T23:59:59");
    }
    return paginate(items, params);
  }
  const q = new URLSearchParams(
    Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== "")
      .map(([k, v]) => [k, String(v)]),
  ).toString();
  return request(`/admin/transactions?${q}`);
}

export async function reverseTransaction(id: string): Promise<Transaction> {
  if (USE_MOCK) {
    await delay(500);
    const t = mockTransactions.find((x) => x.id === id);
    if (!t) throw new Error("Transaction not found");
    if (t.status !== "completed") {
      throw new Error("Only completed transactions can be reversed");
    }
    t.status = "reversed";
    return { ...t };
  }
  return request(`/admin/transactions/${id}/reverse`, { method: "POST" });
}

// ─── Payments ───────────────────────────────────────────────────────────────

export async function fetchPayments(
  params: ListParams = {},
): Promise<PaginatedResult<Payment>> {
  if (USE_MOCK) {
    await delay(300);
    let items = [...mockPayments];
    items = filterBySearch(
      items as unknown as Record<string, unknown>[],
      params.search,
      ["providerReference", "accountNumber", "userName"],
    ) as unknown as Payment[];
    if (params.status) items = items.filter((p) => p.status === params.status);
    if (params.type) items = items.filter((p) => p.provider === params.type);
    return paginate(items, params);
  }
  const q = new URLSearchParams(
    Object.entries(params)
      .filter(([, v]) => v !== undefined && v !== "")
      .map(([k, v]) => [k, String(v)]),
  ).toString();
  return request(`/admin/payments?${q}`);
}
