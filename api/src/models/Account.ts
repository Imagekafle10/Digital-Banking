import { randomUUID } from "crypto";
import { PoolConnection, RowDataPacket, ResultSetHeader } from "mysql2/promise";
import pool from "../config/database";
import { AccountType, IAccount } from "../types/banking.types";

interface AccountRow extends RowDataPacket, IAccount {}

class Account {
  static async findByUserId(userId: string): Promise<IAccount | null> {
    const [rows] = await pool.query<AccountRow[]>(
      "SELECT * FROM accounts WHERE userId = ? LIMIT 1",
      [userId],
    );
    return rows[0] ?? null;
  }

  static async findByAccountNumber(
    accountNumber: string,
  ): Promise<IAccount | null> {
    const [rows] = await pool.query<AccountRow[]>(
      "SELECT * FROM accounts WHERE accountNumber = ? LIMIT 1",
      [accountNumber],
    );
    return rows[0] ?? null;
  }

  static async findById(id: string): Promise<IAccount | null> {
    const [rows] = await pool.query<AccountRow[]>(
      "SELECT * FROM accounts WHERE id = ? LIMIT 1",
      [id],
    );
    return rows[0] ?? null;
  }

  // Row-locking reads used inside an open DB transaction (deposit/withdraw/transfer).
  // MySQL's SELECT ... FOR UPDATE blocks concurrent writers to the same row
  // until the surrounding transaction commits or rolls back.
  static async findByIdForUpdate(
    id: string,
    connection: PoolConnection,
  ): Promise<IAccount | null> {
    const [rows] = await connection.query<AccountRow[]>(
      "SELECT * FROM accounts WHERE id = ? FOR UPDATE",
      [id],
    );
    return rows[0] ?? null;
  }

  static async findByAccountNumberForUpdate(
    accountNumber: string,
    connection: PoolConnection,
  ): Promise<IAccount | null> {
    const [rows] = await connection.query<AccountRow[]>(
      "SELECT * FROM accounts WHERE accountNumber = ? FOR UPDATE",
      [accountNumber],
    );
    return rows[0] ?? null;
  }

  static async createAccount(data: {
    userId: string;
    accountNumber: string;
    accountType: AccountType;
    currency: string;
  }): Promise<IAccount> {
    const id = randomUUID();
    await pool.query<ResultSetHeader>(
      `INSERT INTO accounts (id, userId, accountNumber, accountType, balance, currency, status)
       VALUES (?, ?, ?, ?, 0, ?, 'active')`,
      [id, data.userId, data.accountNumber, data.accountType, data.currency],
    );
    return (await Account.findById(id)) as IAccount;
  }

  static async updateBalance(
    id: string,
    newBalance: number,
    connection: PoolConnection,
  ): Promise<void> {
    await connection.query("UPDATE accounts SET balance = ? WHERE id = ?", [
      newBalance,
      id,
    ]);
  }
}

export default Account;
