import { randomUUID } from "crypto";
import Payment from "../models/Payment";
import bankingService from "./bankingService";
import {
  initiateKhaltiPayment,
  lookupKhaltiPayment,
} from "../providers/khaltiProvider";
import {
  buildEsewaFormPayload,
  checkEsewaStatus,
} from "../providers/esewaProvider";
import {
  InitiatePaymentInput,
  InitiatePaymentResult,
} from "../types/payment.types";

const initiatePayment = async (
  input: InitiatePaymentInput,
): Promise<InitiatePaymentResult> => {
  try {
    if (input.provider === "khalti") {
      const orderId = `DEP-${randomUUID()}`;
      const khaltiResponse = await initiateKhaltiPayment({
        amount: input.amount,
        purchaseOrderId: orderId,
        purchaseOrderName: `Wallet top-up - ${input.accountId}`,
      });

      await Payment.createPayment({
        accountId: input.accountId,
        provider: "khalti",
        amount: input.amount,
        providerReference: khaltiResponse.pidx,
        status: "initiated",
      });

      return {
        provider: "khalti",
        providerReference: khaltiResponse.pidx,
        paymentUrl: khaltiResponse.payment_url,
      };
    }

    // eSewa: no server-to-server initiate call - we just build the signed
    // form the client will POST to eSewa directly.
    const transactionUuid = randomUUID();
    const { formAction, formFields } = buildEsewaFormPayload(
      input.amount,
      transactionUuid,
    );

    await Payment.createPayment({
      accountId: input.accountId,
      provider: "esewa",
      amount: input.amount,
      providerReference: transactionUuid,
      status: "initiated",
    });

    return {
      provider: "esewa",
      providerReference: transactionUuid,
      formAction,
      formFields,
    };
  } catch (error) {
    throw new Error(error as string);
  }
};

const verifyPayment = async (providerReference: string) => {
  try {
    const payment = await Payment.findByReference(providerReference);
    if (!payment) throw new Error("Payment record not found");
    if (payment.status === "completed") return payment;

    if (payment.provider === "khalti") {
      const lookup = await lookupKhaltiPayment(providerReference);
      if (lookup.status !== "Completed") {
        await Payment.updateStatus(payment.id, "pending");
        return payment;
      }
    } else {
      const status = await checkEsewaStatus(
        Number(payment.amount),
        providerReference,
      );
      if (status.status !== "COMPLETE") {
        await Payment.updateStatus(payment.id, "pending");
        return payment;
      }
    }

    await Payment.updateStatus(payment.id, "completed");

    // Only after independent server-side verification do we touch the ledger.
    await bankingService.deposit({
      accountId: payment.accountId,
      amount: Number(payment.amount),
      remarks: `${payment.provider} payment ${providerReference}`,
    });

    return payment;
  } catch (error) {
    throw new Error(error as string);
  }
};

export default { initiatePayment, verifyPayment };
