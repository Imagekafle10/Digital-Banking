import { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../../utils/tokens";
import { UserRole } from "../../types/auth.types";

export interface AuthRequest extends Request {
  user?: { id: string; role: UserRole };
}

const auth = (req: AuthRequest, res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Missing or invalid token" });
  }

  const token = header.split(" ")[1];
  try {
    const decoded = verifyAccessToken(token);
    req.user = { id: decoded.id, role: decoded.role };
    next();
  } catch {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
};

export default auth;
