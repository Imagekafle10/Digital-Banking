import express from "express";
import bankingControllers from "../controllers/bankingControllers";
import auth from "../middlewares/auth/auth";
import {
  createAccountValidation,
  depositValidation,
  withdrawValidation,
  transferValidation,
} from "../middlewares/banking/bankingValidation";

const router = express.Router();

router.post(
  "/account",
  auth,
  createAccountValidation,
  bankingControllers.createAccount
);
router.get("/account/me", auth, bankingControllers.getMyAccount);
router.get(
  "/account/lookup/:accountNumber",
  auth,
  bankingControllers.lookupAccount
);

router.post("/deposit", auth, depositValidation, bankingControllers.deposit);
router.post(
  "/withdraw",
  auth,
  withdrawValidation,
  bankingControllers.withdraw
);
router.post(
  "/transfer",
  auth,
  transferValidation,
  bankingControllers.transfer
);

router.get(
  "/transactions/:accountId",
  auth,
  bankingControllers.getTransactionHistory
);

export default router;
