import { Response, NextFunction } from "express";
import { AuthRequest } from "./auth/auth"; // adjust path if your auth middleware lives elsewhere

/**
 * Must be used AFTER the existing `auth` middleware.
 * Rejects any authenticated user who is not role === 'admin'.
 */
const requireAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (!req.user) {
    return res.status(401).json({ message: "Unauthorized" });
  }
  if (req.user.role !== "admin") {
    return res.status(403).json({ message: "Admin access required" });
  }
  next();
};

export default requireAdmin;
