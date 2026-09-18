/**
 * Admin-only DB queries. Uses the same mysql2 pool as the rest of the app.
 * Path: src/models/AdminQueries.ts
 */
import { RowDataPacket, ResultSetHeader } from "mysql2/promise";
import pool from "../config/database";
import {
  AdminListQuery,
  DashboardStats,
  ChartPoint,
} from "../types/admin.types";

function paginateParams(query: AdminListQuery) {
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 10));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const [userRows] = await pool.query<RowDataPacket[]>(
    `SELECT
       COUNT(*) AS totalUsers,
       SUM(status = 'active') AS activeUsers,
       SUM(status = 'suspended') AS suspendedUsers
     FROM users`,
  );
  const [accRows] = await pool.query<RowDataPacket[]>(
    `SELECT
       COUNT(*) AS totalAccounts,
       SUM(status = 'active') AS activeAccounts,
       COALESCE(SUM(balance), 0) AS totalBalance
     FROM accounts`,
  );
  const [txnRows] = await pool.query<RowDataPacket[]>(
    `SELECT
       COUNT(*) AS totalTransactions,
       SUM(DATE(createdAt) = CURDATE()) AS todayTransactions,
       COALESCE(SUM(CASE WHEN DATE(createdAt) = CURDATE() THEN amount ELSE 0 END), 0) AS volumeToday,
       COALESCE(SUM(CASE WHEN createdAt >= DATE_FORMAT(NOW(), '%Y-%m-01') THEN amount ELSE 0 END), 0) AS volumeMonth
     FROM transactions`,
  );
  const [payRows] = await pool.query<RowDataPacket[]>(
    `SELECT
       COUNT(*) AS totalPayments,
       SUM(status IN ('pending', 'initiated')) AS pendingPayments
     FROM payments`,
  );

  const u = userRows[0];
  const a = accRows[0];
  const t = txnRows[0];
  const p = payRows[0];

  return {
    totalUsers: Number(u.totalUsers),
    activeUsers: Number(u.activeUsers),
    suspendedUsers: Number(u.suspendedUsers),
    totalAccounts: Number(a.totalAccounts),
    activeAccounts: Number(a.activeAccounts),
    totalBalance: Number(a.totalBalance),
    totalTransactions: Number(t.totalTransactions),
    todayTransactions: Number(t.todayTransactions),
    totalPayments: Number(p.totalPayments),
    pendingPayments: Number(p.pendingPayments),
    volumeToday: Number(t.volumeToday),
    volumeMonth: Number(t.volumeMonth),
  };
}

function toDateKey(value: unknown): string {
  if (value instanceof Date && !isNaN(value.getTime())) {
    const y = value.getFullYear();
    const m = String(value.getMonth() + 1).padStart(2, "0");
    const d = String(value.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }
  const s = String(value ?? "");
  if (/^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10);
  const parsed = new Date(s);
  if (!isNaN(parsed.getTime())) {
    const y = parsed.getFullYear();
    const m = String(parsed.getMonth() + 1).padStart(2, "0");
    const d = String(parsed.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }
  return s.slice(0, 10);
}

export async function getChartData(days = 14): Promise<ChartPoint[]> {
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT
       DATE_FORMAT(createdAt, '%Y-%m-%d') AS date,
       COALESCE(SUM(CASE WHEN type = 'deposit' THEN amount ELSE 0 END), 0) AS deposits,
       COALESCE(SUM(CASE WHEN type = 'withdrawal' THEN amount ELSE 0 END), 0) AS withdrawals,
       COALESCE(SUM(CASE WHEN type IN ('transfer_in', 'transfer_out') THEN amount ELSE 0 END), 0) AS transfers,
       COUNT(*) AS count
     FROM transactions
     WHERE createdAt >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
     GROUP BY DATE_FORMAT(createdAt, '%Y-%m-%d')
     ORDER BY date ASC`,
    [days],
  );

  const map = new Map<string, ChartPoint>();
  for (const r of rows) {
    const key = toDateKey(r.date);
    map.set(key, {
      date: key,
      deposits: Number(r.deposits) || 0,
      withdrawals: Number(r.withdrawals) || 0,
      transfers: Number(r.transfers) || 0,
      count: Number(r.count) || 0,
    });
  }

  const points: ChartPoint[] = [];
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    const key = toDateKey(d);
    points.push(
      map.get(key) ?? {
        date: key,
        deposits: 0,
        withdrawals: 0,
        transfers: 0,
        count: 0,
      },
    );
  }
  return points;
}

export async function listUsers(query: AdminListQuery) {
  const { page, limit, offset } = paginateParams(query);
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (query.search?.trim()) {
    conditions.push(`(fullName LIKE ? OR email LIKE ? OR phone LIKE ?)`);
    const s = `%${query.search.trim()}%`;
    params.push(s, s, s);
  }
  if (query.status) {
    conditions.push(`status = ?`);
    params.push(query.status);
  }
  if (query.role) {
    conditions.push(`role = ?`);
    params.push(query.role);
  }

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

  const [countRows] = await pool.query<RowDataPacket[]>(
    `SELECT COUNT(*) AS total FROM users ${where}`,
    params,
  );
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT id, fullName, email, phone, dateOfBirth, gender, role, status, createdAt, updatedAt
     FROM users ${where}
     ORDER BY createdAt DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );

  const total = Number(countRows[0].total);
  return {
    data: rows,
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit) || 1,
  };
}

export async function updateUserStatus(
  id: string,
  status: "active" | "suspended",
) {
  const [result] = await pool.query<ResultSetHeader>(
    `UPDATE users SET status = ? WHERE id = ? AND role != 'admin'`,
    [status, id],
  );
  if (result.affectedRows === 0) {
    throw Object.assign(new Error("User not found or cannot modify admin"), {
      statusCode: 404,
    });
  }
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT id, fullName, email, phone, dateOfBirth, gender, role, status, createdAt, updatedAt
     FROM users WHERE id = ?`,
    [id],
  );
  return rows[0];
}

export async function listAccounts(query: AdminListQuery) {
  const { page, limit, offset } = paginateParams(query);
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (query.search?.trim()) {
    conditions.push(
      `(a.accountNumber LIKE ? OR u.fullName LIKE ? OR u.email LIKE ?)`,
    );
    const s = `%${query.search.trim()}%`;
    params.push(s, s, s);
  }
  if (query.status) {
    conditions.push(`a.status = ?`);
    params.push(query.status);
  }
  if (query.type) {
    conditions.push(`a.accountType = ?`);
    params.push(query.type);
  }

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

  const [countRows] = await pool.query<RowDataPacket[]>(
    `SELECT COUNT(*) AS total
     FROM accounts a
     LEFT JOIN users u ON u.id = a.userId
     ${where}`,
    params,
  );
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT a.*, u.fullName AS userName, u.email AS userEmail
     FROM accounts a
     LEFT JOIN users u ON u.id = a.userId
     ${where}
     ORDER BY a.createdAt DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );

  const total = Number(countRows[0].total);
  return {
    data: rows.map((r) => ({
      ...r,
      balance: Number(r.balance),
    })),
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit) || 1,
  };
}

export async function updateAccountStatus(
  id: string,
  status: "active" | "suspended" | "closed",
) {
  const [result] = await pool.query<ResultSetHeader>(
    `UPDATE accounts SET status = ? WHERE id = ?`,
    [status, id],
  );
  if (result.affectedRows === 0) {
    throw Object.assign(new Error("Account not found"), { statusCode: 404 });
  }
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT a.*, u.fullName AS userName, u.email AS userEmail
     FROM accounts a
     LEFT JOIN users u ON u.id = a.userId
     WHERE a.id = ?`,
    [id],
  );
  return { ...rows[0], balance: Number(rows[0].balance) };
}

export async function listTransactions(query: AdminListQuery) {
  const { page, limit, offset } = paginateParams(query);
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (query.search?.trim()) {
    conditions.push(
      `(t.reference LIKE ? OR a.accountNumber LIKE ? OR u.fullName LIKE ? OR ru.fullName LIKE ?)`,
    );
    const s = `%${query.search.trim()}%`;
    params.push(s, s, s, s);
  }
  if (query.status) {
    conditions.push(`t.status = ?`);
    params.push(query.status);
  }
  if (query.type) {
    conditions.push(`t.type = ?`);
    params.push(query.type);
  }
  if (query.startDate) {
    conditions.push(`t.createdAt >= ?`);
    params.push(query.startDate);
  }
  if (query.endDate) {
    conditions.push(`t.createdAt <= ?`);
    params.push(query.endDate + " 23:59:59");
  }

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

  const [countRows] = await pool.query<RowDataPacket[]>(
    `SELECT COUNT(*) AS total
     FROM transactions t
     LEFT JOIN accounts a ON a.id = t.accountId
     LEFT JOIN users u ON u.id = a.userId
     LEFT JOIN accounts ra ON ra.id = t.relatedAccountId
     LEFT JOIN users ru ON ru.id = ra.userId
     ${where}`,
    params,
  );
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT
       t.*,
       a.accountNumber,
       u.fullName AS userName,
       ra.accountNumber AS relatedAccountNumber,
       ru.fullName AS counterpartyName
     FROM transactions t
     LEFT JOIN accounts a ON a.id = t.accountId
     LEFT JOIN users u ON u.id = a.userId
     LEFT JOIN accounts ra ON ra.id = t.relatedAccountId
     LEFT JOIN users ru ON ru.id = ra.userId
     ${where}
     ORDER BY t.createdAt DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );

  const total = Number(countRows[0].total);
  return {
    data: rows.map((r) => ({
      ...r,
      amount: Number(r.amount),
      balanceAfter: Number(r.balanceAfter),
    })),
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit) || 1,
  };
}

export async function reverseTransaction(id: string) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [rows] = await connection.query<RowDataPacket[]>(
      `SELECT * FROM transactions WHERE id = ? FOR UPDATE`,
      [id],
    );
    const txn = rows[0];
    if (!txn) {
      throw Object.assign(new Error("Transaction not found"), {
        statusCode: 404,
      });
    }
    if (txn.status !== "completed") {
      throw Object.assign(
        new Error("Only completed transactions can be reversed"),
        { statusCode: 400 },
      );
    }

    await connection.query(
      `UPDATE transactions SET status = 'reversed' WHERE id = ?`,
      [id],
    );

    const [accRows] = await connection.query<RowDataPacket[]>(
      `SELECT * FROM accounts WHERE id = ? FOR UPDATE`,
      [txn.accountId],
    );
    const account = accRows[0];
    if (account) {
      let newBalance = Number(account.balance);
      if (txn.type === "deposit" || txn.type === "transfer_in") {
        newBalance -= Number(txn.amount);
      } else if (txn.type === "withdrawal" || txn.type === "transfer_out") {
        newBalance += Number(txn.amount);
      }
      if (newBalance < 0) newBalance = 0;
      await connection.query(`UPDATE accounts SET balance = ? WHERE id = ?`, [
        newBalance,
        txn.accountId,
      ]);
    }

    await connection.commit();

    const [updated] = await pool.query<RowDataPacket[]>(
      `SELECT t.*, a.accountNumber, u.fullName AS userName
       FROM transactions t
       LEFT JOIN accounts a ON a.id = t.accountId
       LEFT JOIN users u ON u.id = a.userId
       WHERE t.id = ?`,
      [id],
    );
    return {
      ...updated[0],
      amount: Number(updated[0].amount),
      balanceAfter: Number(updated[0].balanceAfter),
    };
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }
}

export async function listPayments(query: AdminListQuery) {
  const { page, limit, offset } = paginateParams(query);
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (query.search?.trim()) {
    conditions.push(
      `(p.providerReference LIKE ? OR a.accountNumber LIKE ? OR u.fullName LIKE ?)`,
    );
    const s = `%${query.search.trim()}%`;
    params.push(s, s, s);
  }
  if (query.status) {
    conditions.push(`p.status = ?`);
    params.push(query.status);
  }
  if (query.type) {
    conditions.push(`p.provider = ?`);
    params.push(query.type);
  }

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

  const [countRows] = await pool.query<RowDataPacket[]>(
    `SELECT COUNT(*) AS total
     FROM payments p
     LEFT JOIN accounts a ON a.id = p.accountId
     LEFT JOIN users u ON u.id = a.userId
     ${where}`,
    params,
  );
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT
       p.*,
       a.accountNumber,
       u.fullName AS userName
     FROM payments p
     LEFT JOIN accounts a ON a.id = p.accountId
     LEFT JOIN users u ON u.id = a.userId
     ${where}
     ORDER BY p.createdAt DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );

  const total = Number(countRows[0].total);
  return {
    data: rows.map((r) => ({
      ...r,
      amount: Number(r.amount),
    })),
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit) || 1,
  };
}
