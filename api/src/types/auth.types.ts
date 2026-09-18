export type UserRole = "user" | "admin";
export type UserStatus = "active" | "suspended";
export type Gender = "Male" | "Female" | "Other";

export interface IUser {
  id: string;
  fullName: string;
  email: string;
  password: string; // bcrypt hash, never the raw password
  phone: string;
  dateOfBirth: string; // ISO date (YYYY-MM-DD), as returned by MySQL
  gender: Gender;
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
  phone: string;
  dateOfBirth: string; // ISO 8601 string, matches what the client sends
  gender: Gender;
}

export interface LoginInput {
  email: string;
  password: string;
}

// What we return to the client - password and refreshTokenHash stripped.
export type SafeUser = Omit<IUser, "password" | "refreshTokenHash">;
