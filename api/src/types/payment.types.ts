export type PaymentProvider = "khalti" | "esewa";
export type PaymentStatus =
  | "initiated"
  | "pending"
  | "completed"
  | "failed"
  | "expired"
  | "refunded";

export interface IPayment {
  id: string;
  accountId: string;
  provider: PaymentProvider;
  amount: number; // stored in NPR (rupees), not paisa
  providerReference: string; // pidx for Khalti, transaction_uuid for eSewa
  status: PaymentStatus;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface InitiatePaymentInput {
  accountId: string;
  provider: PaymentProvider;
  amount: number;
  remarks?: string;
}

export interface InitiatePaymentResult {
  provider: PaymentProvider;
  providerReference: string;
  paymentUrl?: string; // Khalti: open this URL/webview
  formAction?: string; // eSewa: form POST target
  formFields?: Record<string, string>; // eSewa: signed form fields
}

export interface KhaltiInitiateResponse {
  pidx: string;
  payment_url: string;
  expires_at: string;
  expires_in: number;
}

export interface KhaltiLookupResponse {
  pidx: string;
  total_amount: number;
  status:
    | "Completed"
    | "Pending"
    | "Initiated"
    | "Refunded"
    | "Expired"
    | "User canceled";
  transaction_id: string | null;
  fee: number;
  refunded: boolean;
}

export interface EsewaStatusResponse {
  product_code: string;
  transaction_uuid: string;
  total_amount: number;
  status:
    | "COMPLETE"
    | "PENDING"
    | "FULL_REFUND"
    | "PARTIAL_REFUND"
    | "AMBIGUOUS"
    | "NOT_FOUND"
    | "CANCELED";
  ref_id: string;
}
