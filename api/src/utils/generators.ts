import { randomBytes } from "crypto";

export const generateAccountNumber = (): string => {
  const prefix = "NP";
  const random = randomBytes(5).toString("hex").toUpperCase().slice(0, 10);
  return `${prefix}${random}`;
};

export const generateReference = (prefix: string): string => {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = randomBytes(3).toString("hex").toUpperCase();
  return `${prefix}-${timestamp}-${random}`;
};
