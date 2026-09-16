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
    connection: PoolConnection
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
      ]
    );
    const [rows] = await connection.query<TransactionRow[]>(
      "SELECT * FROM transactions WHERE id = ? LIMIT 1",
      [id]
    );
    return rows[0];
  }

  static async findByReference(
    reference: string
  ): Promise<ITransaction | null> {
    const [rows] = await pool.query<TransactionRow[]>(
      "SELECT * FROM transactions WHERE reference = ? LIMIT 1",
      [reference]
    );
    return rows[0] ?? null;
  }

  static async findHistory(query: TransactionHistoryQuery) {
    const { accountId, type, startDate, endDate, page = 1, limit = 20 } = query;

    const conditions: string[] = ["accountId = ?"];
    const params: unknown[] = [accountId];

    if (type) {
      conditions.push("type = ?");
      params.push(type);
    }
    if (startDate) {
      conditions.push("createdAt >= ?");
      params.push(new Date(startDate));
    }
    if (endDate) {
      conditions.push("createdAt <= ?");
      params.push(new Date(endDate));
    }

    const whereClause = conditions.join(" AND ");
    const offset = (page - 1) * limit;

    const [rows] = await pool.query<TransactionRow[]>(
      `SELECT * FROM transactions WHERE ${whereClause}
       ORDER BY createdAt DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    const [countRows] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) AS total FROM transactions WHERE ${whereClause}`,
      params
    );

    return { rows, count: Number(countRows[0].total) };
  }
}

export default Transaction;
