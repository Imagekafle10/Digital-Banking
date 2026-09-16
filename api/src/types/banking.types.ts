export type AccountType = "savings" | "checking" | "wallet";
export type AccountStatus = "active" | "suspended" | "closed";
export type TransactionType =
  | "deposit"
  | "withdrawal"
  | "transfer_in"
  | "transfer_out";
export type TransactionStatus = "pending" | "completed" | "failed" | "reversed";

export interface IAccount {
  id: string;
  userId: string;
  accountNumber: string;
  accountType: AccountType;
  balance: number;
  currency: string;
  status: AccountStatus;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface ITransaction {
  id: string;
  accountId: string;
  type: TransactionType;
  amount: number;
  balanceAfter: number;
  reference: string;
  relatedAccountId?: string | null;
  status: TransactionStatus;
  remarks?: string;
  createdAt?: Date;
  /** Present on history / enriched responses */
  relatedAccountNumber?: string | null;
  counterpartyName?: string | null;
}

export interface CreateAccountInput {
  userId: string;
  accountType: AccountType;
  currency?: string;
}

export interface DepositInput {
  accountId: string;
  amount: number;
  remarks?: string;
}

export interface WithdrawInput {
  accountId: string;
  amount: number;
  remarks?: string;
}

export interface TransferInput {
  fromAccountId: string;
  toAccountNumber: string;
  amount: number;
  remarks?: string;
}

export interface TransactionHistoryQuery {
  accountId: string;
  type?: TransactionType;
  startDate?: string;
  endDate?: string;
  page?: number;
  limit?: number;
}
