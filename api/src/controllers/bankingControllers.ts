import { Request, Response, NextFunction } from "express";
import bankingService from "../services/bankingService";
import { TransactionType } from "../types/banking.types";

interface AuthRequest extends Request {
  user?: { id: string; [key: string]: unknown };
}

const createAccount = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const userId = req.user!.id as string;
    const { accountType, currency } = req.body;
    const account = await bankingService.createAccount({
      userId,
      accountType,
      currency,
    });
    return res
      .status(201)
      .json({ message: "Account created", data: account });
  } catch (error) {
    next(error);
  }
};

const getMyAccount = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const userId = req.user!.id as string;
    const account = await bankingService.getAccountByUserId(userId);
    if (!account) {
      return res.status(404).json({ message: "Account not found" });
    }
    return res.status(200).json({ data: account });
  } catch (error) {
    next(error);
  }
};

// Lets the sender verify who they're sending to before confirming a
// transfer - returns just { accountNumber, name }, nothing sensitive.
const lookupAccount = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const { accountNumber } = req.params;
    const result = await bankingService.lookupAccountByNumber(accountNumber);
    if (!result) {
      return res.status(404).json({ message: "Account not found" });
    }
    return res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
};

const deposit = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const { accountId, amount, remarks } = req.body;
    const transaction = await bankingService.deposit({
      accountId,
      amount,
      remarks,
    });
    return res
      .status(200)
      .json({ message: "Deposit successful", data: transaction });
  } catch (error) {
    next(error);
  }
};

const withdraw = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const { accountId, amount, remarks } = req.body;
    const transaction = await bankingService.withdraw({
      accountId,
      amount,
      remarks,
    });
    return res
      .status(200)
      .json({ message: "Withdrawal successful", data: transaction });
  } catch (error) {
    next(error);
  }
};

const transfer = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const { fromAccountId, toAccountNumber, amount, remarks } = req.body;
    const transaction = await bankingService.transfer({
      fromAccountId,
      toAccountNumber,
      amount,
      remarks,
    });
    return res
      .status(200)
      .json({ message: "Transfer successful", data: transaction });
  } catch (error) {
    next(error);
  }
};

const getTransactionHistory = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const { accountId } = req.params;
    const { type, startDate, endDate, page, limit } = req.query;
    const result = await bankingService.getTransactionHistory({
      accountId,
      type: type as TransactionType | undefined,
      startDate: startDate as string | undefined,
      endDate: endDate as string | undefined,
      page: page ? Number(page) : undefined,
      limit: limit ? Number(limit) : undefined,
    });
    return res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
};

export default {
  createAccount,
  getMyAccount,
  lookupAccount,
  deposit,
  withdraw,
  transfer,
  getTransactionHistory,
};
