import { randomUUID } from "crypto";
import { RowDataPacket, ResultSetHeader } from "mysql2/promise";
import pool from "../config/database";
import { IUser } from "../types/auth.types";

interface UserRow extends RowDataPacket, IUser {}

class User {
  static async findByEmail(email: string): Promise<IUser | null> {
    const [rows] = await pool.query<UserRow[]>(
      "SELECT * FROM users WHERE email = ? LIMIT 1",
      [email],
    );
    return rows[0] ?? null;
  }

  static async findById(id: string): Promise<IUser | null> {
    const [rows] = await pool.query<UserRow[]>(
      "SELECT * FROM users WHERE id = ? LIMIT 1",
      [id],
    );
    return rows[0] ?? null;
  }

  static async createUser(data: {
    fullName: string;
    email: string;
    passwordHash: string;
  }): Promise<IUser> {
    const id = randomUUID();
    await pool.query<ResultSetHeader>(
      `INSERT INTO users (id, fullName, email, password, role, status)
       VALUES (?, ?, ?, ?, 'user', 'active')`,
      [id, data.fullName, data.email, data.passwordHash],
    );
    return (await User.findById(id)) as IUser;
  }

  static async setRefreshTokenHash(
    id: string,
    refreshTokenHash: string | null,
  ): Promise<void> {
    await pool.query("UPDATE users SET refreshTokenHash = ? WHERE id = ?", [
      refreshTokenHash,
      id,
    ]);
  }
}

export default User;
