import User from "../models/User";
import AppError from "../utils/AppError";
import { hashPassword, comparePassword } from "../utils/password";
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  hashToken,
} from "../utils/tokens";
import {
  RegisterInput,
  LoginInput,
  SafeUser,
  IUser,
} from "../types/auth.types";

const toSafeUser = (user: IUser): SafeUser => ({
  id: user.id,
  fullName: user.fullName,
  email: user.email,
  phone: user.phone,
  dateOfBirth: user.dateOfBirth,
  gender: user.gender,
  role: user.role,
  status: user.status,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const issueTokens = async (user: Pick<IUser, "id" | "role">) => {
  const accessToken = generateAccessToken({ id: user.id, role: user.role });
  const refreshToken = generateRefreshToken({ id: user.id });
  // Store only the hash - if the DB ever leaks, the tokens in it are useless.
  await User.setRefreshTokenHash(user.id, hashToken(refreshToken));
  return { accessToken, refreshToken };
};

const register = async ({
  fullName,
  email,
  password,
  phone,
  dateOfBirth,
  gender,
}: RegisterInput) => {
  const existing = await User.findByEmail(email);
  if (existing) throw new AppError("Email is already registered", 409);

  const passwordHash = await hashPassword(password);
  const user = await User.createUser({
    fullName,
    email,
    passwordHash,
    phone,
    dateOfBirth,
    gender,
  });
  const tokens = await issueTokens(user);

  return { user: toSafeUser(user), ...tokens };
};

const login = async ({ email, password }: LoginInput) => {
  const user = await User.findByEmail(email);
  // Same generic message whether the email doesn't exist or the password is
  // wrong - never tell an attacker which half of the pair was incorrect.
  if (!user) throw new AppError("Invalid email or password", 401);
  if (user.status !== "active") {
    throw new AppError("This account is suspended", 403);
  }

  const valid = await comparePassword(password, user.password);
  if (!valid) throw new AppError("Invalid email or password", 401);

  const tokens = await issueTokens(user);
  return { user: toSafeUser(user), ...tokens };
};

const refresh = async (token: string | undefined) => {
  if (!token) throw new AppError("Missing refresh token", 401);

  let payload;
  try {
    payload = verifyRefreshToken(token);
  } catch {
    throw new AppError("Invalid or expired refresh token", 401);
  }

  const user = await User.findById(payload.id);
  if (!user || !user.refreshTokenHash) {
    throw new AppError("Invalid or expired refresh token", 401);
  }

  // Guards against a stolen/replayed old token: only the *most recently
  // issued* refresh token for this user will match the stored hash.
  if (user.refreshTokenHash !== hashToken(token)) {
    throw new AppError("Invalid or expired refresh token", 401);
  }

  // Rotate on every use - the token just spent is now invalid.
  return issueTokens(user);
};

const logout = async (userId: string) => {
  await User.setRefreshTokenHash(userId, null);
};

const getMe = async (userId: string) => {
  const user = await User.findById(userId);
  if (!user) throw new AppError("User not found", 404);
  return toSafeUser(user);
};

export default { register, login, refresh, logout, getMe };
