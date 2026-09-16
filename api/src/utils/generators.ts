import { randomBytes, randomInt } from "crypto";

/**
 * 16-digit numeric account number.
 * Uses crypto randomness; uniqueness is also enforced by the DB UNIQUE index.
 * First digit is 1–9 so the number never has a leading zero.
 */
export const generateAccountNumber = (): string => {
  // 1–9 for the first digit
  let number = String(randomInt(1, 10));
  // remaining 15 digits 0–9
  for (let i = 0; i < 15; i++) {
    number += String(randomInt(0, 10));
  }
  return number;
};

export const generateReference = (prefix: string): string => {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = randomBytes(3).toString("hex").toUpperCase();
  return `${prefix}-${timestamp}-${random}`;
};
