import { PoolConnection } from "mysql2/promise";
import pool from "../config/database";
import Account from "../models/Account";
import Transaction from "../models/Transaction";
import User from "../models/User";
import {
  CreateAccountInput,
  DepositInput,
  WithdrawInput,
  TransferInput,
  TransactionHistoryQuery,
} from "../types/banking.types";
import { generateAccountNumber, generateReference } from "../utils/generators";

const createAccount = async (input: CreateAccountInput) => {
  // Retry a few times if the rare UNIQUE collision on accountNumber happens
  const maxAttempts = 5;
  let lastError: unknown;
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      const accountNumber = generateAccountNumber();
      return await Account.createAccount({
        userId: input.userId,
        accountNumber,
        accountType: input.accountType,
        currency: input.currency || "NPR",
      });
    } catch (error) {
      lastError = error;
      const message = String(error);
      // MySQL duplicate key → try another number
      if (message.includes("Duplicate") || message.includes("ER_DUP_ENTRY")) {
        continue;
      }
      throw new Error(message);
    }
  }
  throw new Error(
    lastError
      ? String(lastError)
      : "Could not generate a unique account number",
  );
};

const getAccountByUserId = async (userId: string) => {
  try {
    return await Account.findByUserId(userId);
  } catch (error) {
    throw new Error(error as string);
  }
};

const getAccountByNumber = async (accountNumber: string) => {
  try {
    return await Account.findByAccountNumber(accountNumber);
  } catch (error) {
    throw new Error(error as string);
  }
};

const deposit = async ({ accountId, amount, remarks }: DepositInput) => {
  if (amount <= 0) throw new Error("Deposit amount must be greater than zero");

  const connection: PoolConnection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const account = await Account.findByIdForUpdate(accountId, connection);
    if (!account) throw new Error("Account not found");
    if (account.status !== "active") throw new Error("Account is not active");

    const newBalance = Number(account.balance) + Number(amount);
    await Account.updateBalance(accountId, newBalance, connection);

    const transaction = await Transaction.createTransaction(
      {
        accountId,
        type: "deposit",
        amount,
        balanceAfter: newBalance,
        reference: generateReference("DEP"),
        relatedAccountId: null,
        status: "completed",
        remarks,
      },
      connection,
    );

    await connection.commit();
    return transaction;
  } catch (error) {
    await connection.rollback();
    throw new Error(error as string);
  } finally {
    connection.release();
  }
};

const withdraw = async ({ accountId, amount, remarks }: WithdrawInput) => {
  if (amount <= 0)
    throw new Error("Withdrawal amount must be greater than zero");

  const connection: PoolConnection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const account = await Account.findByIdForUpdate(accountId, connection);
    if (!account) throw new Error("Account not found");
    if (account.status !== "active") throw new Error("Account is not active");
    if (Number(account.balance) < amount)
      throw new Error("Insufficient balance");

    const newBalance = Number(account.balance) - Number(amount);
    await Account.updateBalance(accountId, newBalance, connection);

    const transaction = await Transaction.createTransaction(
      {
        accountId,
        type: "withdrawal",
        amount,
        balanceAfter: newBalance,
        reference: generateReference("WDR"),
        relatedAccountId: null,
        status: "completed",
        remarks,
      },
      connection,
    );

    await connection.commit();
    return transaction;
  } catch (error) {
    await connection.rollback();
    throw new Error(error as string);
  } finally {
    connection.release();
  }
};

const transfer = async ({
  fromAccountId,
  toAccountNumber,
  amount,
  remarks,
}: TransferInput) => {
  if (amount <= 0) throw new Error("Transfer amount must be greater than zero");

  const connection: PoolConnection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const fromAccount = await Account.findByIdForUpdate(
      fromAccountId,
      connection,
    );
    if (!fromAccount) throw new Error("Source account not found");
    if (fromAccount.status !== "active")
      throw new Error("Source account is not active");

    const toAccount = await Account.findByAccountNumberForUpdate(
      toAccountNumber,
      connection,
    );
    if (!toAccount) throw new Error("Destination account not found");
    if (toAccount.status !== "active")
      throw new Error("Destination account is not active");
    if (fromAccount.id === toAccount.id)
      throw new Error("Cannot transfer to the same account");
    if (Number(fromAccount.balance) < amount)
      throw new Error("Insufficient balance");

    const newFromBalance = Number(fromAccount.balance) - Number(amount);
    const newToBalance = Number(toAccount.balance) + Number(amount);

    await Account.updateBalance(fromAccount.id, newFromBalance, connection);
    await Account.updateBalance(toAccount.id, newToBalance, connection);

    const outReference = generateReference("TRF");
    const inReference = generateReference("TRF");

    const outTransaction = await Transaction.createTransaction(
      {
        accountId: fromAccount.id,
        type: "transfer_out",
        amount,
        balanceAfter: newFromBalance,
        reference: outReference,
        relatedAccountId: toAccount.id,
        status: "completed",
        remarks,
      },
      connection,
    );

    await Transaction.createTransaction(
      {
        accountId: toAccount.id,
        type: "transfer_in",
        amount,
        balanceAfter: newToBalance,
        reference: inReference,
        relatedAccountId: fromAccount.id,
        status: "completed",
        remarks,
      },
      connection,
    );

    await connection.commit();

    // Enrich so the app can show other user name + account number immediately
    const toUser = await User.findById(toAccount.userId);
    return {
      ...outTransaction,
      amount: Number(outTransaction.amount),
      balanceAfter: Number(outTransaction.balanceAfter),
      relatedAccountNumber: toAccount.accountNumber,
      counterpartyName: toUser?.fullName ?? null,
    };
  } catch (error) {
    await connection.rollback();
    throw new Error(error as string);
  } finally {
    connection.release();
  }
};

const getTransactionHistory = async (query: TransactionHistoryQuery) => {
  try {
    return await Transaction.findHistory(query);
  } catch (error) {
    throw new Error(error as string);
  }
};

export default {
  createAccount,
  getAccountByUserId,
  getAccountByNumber,
  deposit,
  withdraw,
  transfer,
  getTransactionHistory,
};
