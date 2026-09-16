-- Add this table to sql/schema.sql (put it before the `accounts` table,
-- since accounts.userId conceptually references it).
CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) PRIMARY KEY,
  fullName VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('user', 'admin') NOT NULL DEFAULT 'user',
  status ENUM('active', 'suspended') NOT NULL DEFAULT 'active',
  refreshTokenHash VARCHAR(64) NULL,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_email (email)
);

-- Optional but recommended once you've confirmed existing `accounts` rows
-- (if any) all have a valid userId - this was not enforced before:
-- ALTER TABLE accounts
--   ADD CONSTRAINT fk_accounts_user FOREIGN KEY (userId) REFERENCES users(id);
CREATE TABLE IF NOT EXISTS accounts (
  id CHAR(36) PRIMARY KEY,
  userId CHAR(36) NOT NULL,
  accountNumber VARCHAR(20) NOT NULL UNIQUE,
  accountType ENUM('savings', 'checking', 'wallet') NOT NULL,
  balance DECIMAL(18, 2) NOT NULL DEFAULT 0,
  currency VARCHAR(3) NOT NULL DEFAULT 'NPR',
  status ENUM('active', 'suspended', 'closed') NOT NULL DEFAULT 'active',
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_accounts_userId (userId)
);

CREATE TABLE IF NOT EXISTS transactions (
  id CHAR(36) PRIMARY KEY,
  accountId CHAR(36) NOT NULL,
  type ENUM('deposit', 'withdrawal', 'transfer_in', 'transfer_out') NOT NULL,
  amount DECIMAL(18, 2) NOT NULL,
  balanceAfter DECIMAL(18, 2) NOT NULL,
  reference VARCHAR(64) NOT NULL UNIQUE,
  relatedAccountId CHAR(36) NULL,
  status ENUM('pending', 'completed', 'failed', 'reversed') NOT NULL DEFAULT 'completed',
  remarks VARCHAR(255) NULL,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_transactions_accountId (accountId),
  CONSTRAINT fk_transactions_account FOREIGN KEY (accountId) REFERENCES accounts(id)
);

CREATE TABLE IF NOT EXISTS payments (
  id CHAR(36) PRIMARY KEY,
  accountId CHAR(36) NOT NULL,
  provider ENUM('khalti', 'esewa') NOT NULL,
  amount DECIMAL(18, 2) NOT NULL,
  providerReference VARCHAR(128) NOT NULL UNIQUE,
  status ENUM('initiated', 'pending', 'completed', 'failed', 'expired', 'refunded') NOT NULL DEFAULT 'initiated',
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_payments_accountId (accountId),
  CONSTRAINT fk_payments_account FOREIGN KEY (accountId) REFERENCES accounts(id)
);
