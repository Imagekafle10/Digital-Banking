import { Request, Response, NextFunction } from "express";
import authService from "../services/authService";
import { NODE_ENV, JWT_REFRESH_EXPIRES_MS } from "../config";
import { AuthRequest } from "../middlewares/auth/auth";

const REFRESH_COOKIE_NAME = "refreshToken";

// httpOnly => client JS can never read this token (XSS protection).
// path scoped to /api/auth => the cookie isn't sent on every request, only
// to the auth routes that actually need it.
const refreshCookieOptions = {
  httpOnly: true,
  secure: NODE_ENV === "production",
  sameSite: "lax" as const,
  maxAge: JWT_REFRESH_EXPIRES_MS,
  path: "/api/auth",
};

const register = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user, accessToken, refreshToken } = await authService.register(
      req.body,
    );
    res.cookie(REFRESH_COOKIE_NAME, refreshToken, refreshCookieOptions);
    return res
      .status(201)
      .json({ message: "Account created", data: { user, accessToken } });
  } catch (error) {
    next(error);
  }
};

const login = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user, accessToken, refreshToken } = await authService.login(
      req.body,
    );
    res.cookie(REFRESH_COOKIE_NAME, refreshToken, refreshCookieOptions);
    return res
      .status(200)
      .json({ message: "Login successful", data: { user, accessToken } });
  } catch (error) {
    next(error);
  }
};

const refresh = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const token = req.cookies?.[REFRESH_COOKIE_NAME];
    const { accessToken, refreshToken } = await authService.refresh(token);
    res.cookie(REFRESH_COOKIE_NAME, refreshToken, refreshCookieOptions);
    return res.status(200).json({ data: { accessToken } });
  } catch (error) {
    next(error);
  }
};

const logout = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    if (req.user?.id) await authService.logout(req.user.id);
    res.clearCookie(REFRESH_COOKIE_NAME, { path: "/api/auth" });
    return res.status(200).json({ message: "Logged out" });
  } catch (error) {
    next(error);
  }
};

const getMe = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user?.id) {
      return res.status(401).json({ message: "Unauthorized" });
    }
    const user = await authService.getMe(req.user.id);
    return res.status(200).json({ data: { user } });
  } catch (error) {
    next(error);
  }
};

export default { register, login, refresh, logout, getMe };
