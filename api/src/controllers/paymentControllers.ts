import { Request, Response, NextFunction } from "express";
import paymentService from "../services/paymentService";

const initiate = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { accountId, provider, amount, remarks } = req.body;
    const result = await paymentService.initiatePayment({
      accountId,
      provider,
      amount,
      remarks,
    });
    return res.status(200).json({ data: result });
  } catch (error) {
    next(error);
  }
};

// Khalti redirects the browser/webview here with ?pidx=...&status=...
const khaltiReturn = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const pidx = req.query.pidx as string;
    const payment = await paymentService.verifyPayment(pidx);
    return res.status(200).json({ data: payment });
  } catch (error) {
    next(error);
  }
};

// eSewa's v2 success_url receives a base64-encoded `data` query param -
// verify this shape against the current eSewa docs before going live.
const esewaReturn = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const encoded = req.query.data as string;
    const decoded = JSON.parse(
      Buffer.from(encoded, "base64").toString("utf-8")
    );
    const payment = await paymentService.verifyPayment(
      decoded.transaction_uuid
    );
    return res.status(200).json({ data: payment });
  } catch (error) {
    next(error);
  }
};

export default { initiate, khaltiReturn, esewaReturn };
