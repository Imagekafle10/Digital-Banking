import axios from "axios";
import { createHmac } from "crypto";
import { esewaConfig } from "../config/paymentGateways";
import { EsewaStatusResponse } from "../types/payment.types";

// eSewa signs the literal string it's given - build the message from the
// exact same string values you send as form fields, don't round-trip
// through Number() first or the signature won't match.
const buildSignature = (totalAmount: string, transactionUuid: string): string => {
  const message = `total_amount=${totalAmount},transaction_uuid=${transactionUuid},product_code=${esewaConfig.productCode}`;
  return createHmac("sha256", esewaConfig.secretKey)
    .update(message)
    .digest("base64");
};

export const buildEsewaFormPayload = (
  amount: number,
  transactionUuid: string
) => {
  const totalAmount = amount.toString();
  const signature = buildSignature(totalAmount, transactionUuid);

  return {
    formAction: esewaConfig.formUrl,
    formFields: {
      amount: totalAmount,
      tax_amount: "0",
      total_amount: totalAmount,
      transaction_uuid: transactionUuid,
      product_code: esewaConfig.productCode,
      product_service_charge: "0",
      product_delivery_charge: "0",
      success_url: esewaConfig.successUrl,
      failure_url: esewaConfig.failureUrl,
      signed_field_names: "total_amount,transaction_uuid,product_code",
      signature,
    },
  };
};

export const checkEsewaStatus = async (
  amount: number,
  transactionUuid: string
): Promise<EsewaStatusResponse> => {
  const { data } = await axios.get<EsewaStatusResponse>(
    esewaConfig.statusUrl,
    {
      params: {
        product_code: esewaConfig.productCode,
        total_amount: amount,
        transaction_uuid: transactionUuid,
      },
    }
  );
  return data;
};
