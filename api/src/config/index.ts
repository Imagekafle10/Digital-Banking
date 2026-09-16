import dotenv from "dotenv";
dotenv.config();

export const PORT = process.env.PORT || 5000;
export const NODE_ENV = process.env.NODE_ENV || "development";

export const DB_HOST = process.env.DB_HOST || "localhost";
export const DB_USER = process.env.DB_USER || "root";
export const DB_PASSWORD = process.env.DB_PASSWORD || "";
export const DB_NAME = process.env.DB_NAME || "banking_app";
export const DB_PORT = process.env.DB_PORT || "3306";

export const JWT_SECRET = process.env.JWT_SECRET || "change_this_secret";

// Separate secret from the access token - if one leaks, the other still
// holds. Access tokens are short-lived; refresh tokens are long-lived and
// only ever sent as an httpOnly cookie, never exposed to client JS.
export const JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET || "change_this_refresh_secret";
export const JWT_ACCESS_EXPIRES = process.env.JWT_ACCESS_EXPIRES || "15m";

// Single source of truth for refresh token lifetime - derives both the JWT
// "expiresIn" string and the cookie's maxAge (ms) from one env var, so they
// can't drift out of sync.
const REFRESH_DAYS = Number(process.env.JWT_REFRESH_EXPIRES_DAYS || 7);
export const JWT_REFRESH_EXPIRES = `${REFRESH_DAYS}d`;
export const JWT_REFRESH_EXPIRES_MS = REFRESH_DAYS * 24 * 60 * 60 * 1000;

export const REACT_APP_URL =
  process.env.REACT_APP_URL || "http://localhost:3000";
export const WEBSITE_URL = process.env.WEBSITE_URL || "http://localhost:5000";
