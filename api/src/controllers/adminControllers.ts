import { Response, NextFunction } from "express";
import { AuthRequest } from "../middlewares/auth/auth"; // adjust path to your auth middleware
import * as adminService from "../services/adminService";

const handle = async (
  res: Response,
  next: NextFunction,
  fn: () => Promise<unknown>,
) => {
  try {
    const data = await fn();
    res.json(data);
  } catch (error) {
    next(error);
  }
};

export const getStats = (req: AuthRequest, res: Response, next: NextFunction) =>
  handle(res, next, () => adminService.getStats());

export const getChart = (req: AuthRequest, res: Response, next: NextFunction) =>
  handle(res, next, () =>
    adminService.getChart(Number(req.query.days) || 14),
  );

export const getUsers = (req: AuthRequest, res: Response, next: NextFunction) =>
  handle(res, next, () =>
    adminService.getUsers({
      page: Number(req.query.page) || 1,
      limit: Number(req.query.limit) || 10,
      search: (req.query.search as string) || undefined,
      status: (req.query.status as string) || undefined,
      role: (req.query.role as string) || undefined,
    }),
  );

export const updateUserStatus = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) =>
  handle(res, next, () => {
    const status = req.body.status as "active" | "suspended";
    if (!["active", "suspended"].includes(status)) {
      throw Object.assign(new Error("Invalid status"), { statusCode: 400 });
    }
    return adminService.setUserStatus(req.params.id, status);
  });

export const getAccounts = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) =>
  handle(res, next, () =>
    adminService.getAccounts({
      page: Number(req.query.page) || 1,
      limit: Number(req.query.limit) || 10,
      search: (req.query.search as string) || undefined,
      status: (req.query.status as string) || undefined,
      type: (req.query.type as string) || undefined,
    }),
  );

export const updateAccountStatus = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) =>
  handle(res, next, () => {
    const status = req.body.status as "active" | "suspended" | "closed";
    if (!["active", "suspended", "closed"].includes(status)) {
      throw Object.assign(new Error("Invalid status"), { statusCode: 400 });
    }
    return adminService.setAccountStatus(req.params.id, status);
  });

export const getTransactions = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) =>
  handle(res, next, () =>
    adminService.getTransactions({
      page: Number(req.query.page) || 1,
      limit: Number(req.query.limit) || 10,
      search: (req.query.search as string) || undefined,
      status: (req.query.status as string) || undefined,
      type: (req.query.type as string) || undefined,
      startDate: (req.query.startDate as string) || undefined,
      endDate: (req.query.endDate as string) || undefined,
    }),
  );

export const reverseTransaction = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) =>
  handle(res, next, () => adminService.reverseTxn(req.params.id));

export const getPayments = (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
) =>
  handle(res, next, () =>
    adminService.getPayments({
      page: Number(req.query.page) || 1,
      limit: Number(req.query.limit) || 10,
      search: (req.query.search as string) || undefined,
      status: (req.query.status as string) || undefined,
      type: (req.query.type as string) || undefined,
    }),
  );
