import { randomUUID } from "crypto";
import { PoolConnection, RowDataPacket, ResultSetHeader } from "mysql2/promise";
import pool from "../config/database";
import {
  TransactionType,
  TransactionStatus,
  ITransaction,
  TransactionHistoryQuery,
} from "../types/banking.types";

interface TransactionRow extends RowDataPacket, ITransaction {}

/** Row shape when history is joined with the related account + user. */
interface HistoryRow extends TransactionRow {
  relatedAccountNumber: string | null;
  counterpartyName: string | null;
}

class Transaction {
  // Created on the same connection/transaction as the balance update it
  // belongs to, so a rollback undoes both together.
  static async createTransaction(
    data: {
      accountId: string;
      type: TransactionType;
      amount: number;
      balanceAfter: number;
      reference: string;
      relatedAccountId?: string | null;
      status: TransactionStatus;
      remarks?: string;
    },
    connection: PoolConnection,
  ): Promise<ITransaction> {
    const id = randomUUID();
    await connection.query<ResultSetHeader>(
      `INSERT INTO transactions
        (id, accountId, type, amount, balanceAfter, reference, relatedAccountId, status, remarks)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        data.accountId,
        data.type,
        data.amount,
        data.balanceAfter,
        data.reference,
        data.relatedAccountId ?? null,
        data.status,
        data.remarks ?? null,
      ],
    );
    const [rows] = await connection.query<TransactionRow[]>(
      "SELECT * FROM transactions WHERE id = ? LIMIT 1",
      [id],
    );
    return rows[0];
  }

  static async findByReference(
    reference: string,
  ): Promise<ITransaction | null> {
    const [rows] = await pool.query<TransactionRow[]>(
      "SELECT * FROM transactions WHERE reference = ? LIMIT 1",
      [reference],
    );
    return rows[0] ?? null;
  }

  /**
   * History with counterparty details so the app can show:
   * other user name, related account number, date, amount (Rs).
   *
   * Joins:
   *   transactions.relatedAccountId → accounts.id → users.id
   */
  static async findHistory(query: TransactionHistoryQuery) {
    const { accountId, type, startDate, endDate, page = 1, limit = 20 } = query;

    const conditions: string[] = ["t.accountId = ?"];
    const params: unknown[] = [accountId];

    if (type) {
      conditions.push("t.type = ?");
      params.push(type);
    }
    if (startDate) {
      conditions.push("t.createdAt >= ?");
      params.push(new Date(startDate));
    }
    if (endDate) {
      conditions.push("t.createdAt <= ?");
      params.push(new Date(endDate));
    }

    const whereClause = conditions.join(" AND ");
    const offset = (page - 1) * limit;

    const [rows] = await pool.query<HistoryRow[]>(
      `SELECT
         t.id,
         t.accountId,
         t.type,
         t.amount,
         t.balanceAfter,
         t.reference,
         t.relatedAccountId,
         t.status,
         t.remarks,
         t.createdAt,
         ra.accountNumber AS relatedAccountNumber,
         ru.fullName AS counterpartyName
       FROM transactions t
       LEFT JOIN accounts ra ON ra.id = t.relatedAccountId
       LEFT JOIN users ru ON ru.id = ra.userId
       WHERE ${whereClause}
       ORDER BY t.createdAt DESC
       LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    );

    const [countRows] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) AS total FROM transactions t WHERE ${whereClause}`,
      params,
    );

    // Normalize numeric fields (mysql DECIMAL often comes back as string)
    const normalized = rows.map((row) => ({
      ...row,
      amount: Number(row.amount),
      balanceAfter: Number(row.balanceAfter),
      relatedAccountNumber: row.relatedAccountNumber ?? null,
      counterpartyName: row.counterpartyName ?? null,
    }));

    return { rows: normalized, count: Number(countRows[0].total) };
  }
}

export default Transaction;
