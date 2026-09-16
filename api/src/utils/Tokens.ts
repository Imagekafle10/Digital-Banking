import jwt from "jsonwebtoken";
import { createHash } from "crypto";
import {
  JWT_SECRET,
  JWT_REFRESH_SECRET,
  JWT_ACCESS_EXPIRES,
  JWT_REFRESH_EXPIRES,
} from "../config";
import { UserRole } from "../types/auth.types";

export interface AccessTokenPayload {
  id: string;
  role: UserRole;
}

export interface RefreshTokenPayload {
  id: string;
}

// Short-lived - sent in the JSON response body, kept in memory on the client.
export const generateAccessToken = (payload: AccessTokenPayload): string =>
  jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_ACCESS_EXPIRES });

// Long-lived - sent only as an httpOnly cookie, never readable by client JS.
export const generateRefreshToken = (payload: RefreshTokenPayload): string =>
  jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRES });

export const verifyAccessToken = (token: string): AccessTokenPayload =>
  jwt.verify(token, JWT_SECRET) as AccessTokenPayload;

export const verifyRefreshToken = (token: string): RefreshTokenPayload =>
  jwt.verify(token, JWT_REFRESH_SECRET) as RefreshTokenPayload;

// Refresh tokens are already high-entropy signed JWTs (not user-chosen
// passwords), so a fast SHA-256 digest is enough for "is this the token we
// last issued" comparisons - no need for bcrypt's deliberate slowness here.
export const hashToken = (token: string): string =>
  createHash("sha256").update(token).digest("hex");
