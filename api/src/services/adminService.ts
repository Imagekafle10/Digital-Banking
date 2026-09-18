import * as AdminQueries from "../models/AdminQueries";
import { AdminListQuery } from "../types/admin.types";

export const getStats = () => AdminQueries.getDashboardStats();
export const getChart = (days?: number) => AdminQueries.getChartData(days ?? 14);
export const getUsers = (q: AdminListQuery) => AdminQueries.listUsers(q);
export const setUserStatus = (id: string, status: "active" | "suspended") =>
  AdminQueries.updateUserStatus(id, status);
export const getAccounts = (q: AdminListQuery) => AdminQueries.listAccounts(q);
export const setAccountStatus = (
  id: string,
  status: "active" | "suspended" | "closed",
) => AdminQueries.updateAccountStatus(id, status);
export const getTransactions = (q: AdminListQuery) =>
  AdminQueries.listTransactions(q);
export const reverseTxn = (id: string) => AdminQueries.reverseTransaction(id);
export const getPayments = (q: AdminListQuery) => AdminQueries.listPayments(q);
