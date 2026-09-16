import axios from "axios";
import { khaltiConfig } from "../config/paymentGateways";
import {
  KhaltiInitiateResponse,
  KhaltiLookupResponse,
} from "../types/payment.types";

const client = axios.create({
  headers: { Authorization: `Key ${khaltiConfig.secretKey}` },
});

export const initiateKhaltiPayment = async ({
  amount,
  purchaseOrderId,
  purchaseOrderName,
}: {
  amount: number; // NPR
  purchaseOrderId: string;
  purchaseOrderName: string;
}): Promise<KhaltiInitiateResponse> => {
  const { data } = await client.post<KhaltiInitiateResponse>(
    khaltiConfig.initiateUrl,
    {
      amount: Math.round(amount * 100), // Khalti expects paisa (1 NPR = 100 paisa)
      purchase_order_id: purchaseOrderId,
      purchase_order_name: purchaseOrderName,
      return_url: khaltiConfig.returnUrl,
      website_url: khaltiConfig.websiteUrl,
    }
  );
  return data;
};

export const lookupKhaltiPayment = async (
  pidx: string
): Promise<KhaltiLookupResponse> => {
  const { data } = await client.post<KhaltiLookupResponse>(
    khaltiConfig.lookupUrl,
    { pidx }
  );
  return data;
};
