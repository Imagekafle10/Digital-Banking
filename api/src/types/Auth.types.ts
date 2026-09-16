export type UserRole = "user" | "admin";
export type UserStatus = "active" | "suspended";

export interface IUser {
  id: string;
  fullName: string;
  email: string;
  password: string; // bcrypt hash, never the raw password
  role: UserRole;
  status: UserStatus;
  refreshTokenHash: string | null;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface RegisterInput {
  fullName: string;
  email: string;
  password: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

// What we return to the client - password and refreshTokenHash stripped.
export type SafeUser = Omit<IUser, "password" | "refreshTokenHash">;
