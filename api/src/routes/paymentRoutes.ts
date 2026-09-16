import express from "express";
import paymentControllers from "../controllers/paymentControllers";
import auth from "../middlewares/auth/auth";
import { initiatePaymentValidation } from "../middlewares/payment/paymentValidation";

const router = express.Router();

router.post(
  "/initiate",
  auth,
  initiatePaymentValidation,
  paymentControllers.initiate
);

// Public callback endpoints hit by the gateway/browser redirect - not
// behind `auth`, since the gateway (not your logged-in user) calls these.
router.get("/khalti/return", paymentControllers.khaltiReturn);
router.get("/esewa/return", paymentControllers.esewaReturn);

export default router;
