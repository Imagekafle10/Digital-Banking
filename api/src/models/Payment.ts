import { randomUUID } from "crypto";
import { RowDataPacket, ResultSetHeader } from "mysql2/promise";
import pool from "../config/database";
import { PaymentProvider, PaymentStatus, IPayment } from "../types/payment.types";

interface PaymentRow extends RowDataPacket, IPayment {}

class Payment {
  static async createPayment(data: {
    accountId: string;
    provider: PaymentProvider;
    amount: number;
    providerReference: string;
    status: PaymentStatus;
  }): Promise<IPayment> {
    const id = randomUUID();
    await pool.query<ResultSetHeader>(
      `INSERT INTO payments (id, accountId, provider, amount, providerReference, status)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        id,
        data.accountId,
        data.provider,
        data.amount,
        data.providerReference,
        data.status,
      ]
    );
    return (await Payment.findById(id)) as IPayment;
  }

  static async findById(id: string): Promise<IPayment | null> {
    const [rows] = await pool.query<PaymentRow[]>(
      "SELECT * FROM payments WHERE id = ? LIMIT 1",
      [id]
    );
    return rows[0] ?? null;
  }

  static async findByReference(
    providerReference: string
  ): Promise<IPayment | null> {
    const [rows] = await pool.query<PaymentRow[]>(
      "SELECT * FROM payments WHERE providerReference = ? LIMIT 1",
      [providerReference]
    );
    return rows[0] ?? null;
  }

  static async updateStatus(id: string, status: PaymentStatus): Promise<void> {
    await pool.query("UPDATE payments SET status = ? WHERE id = ?", [
      status,
      id,
    ]);
  }
}

export default Payment;
