import { Router } from "express";
import auth from "../middlewares/auth/auth"; // your existing auth middleware
import requireAdmin from "../middlewares/requireAdmin";
import * as adminControllers from "../controllers/adminControllers";

const router = Router();

// All admin routes require a valid JWT + role === 'admin'
router.use(auth, requireAdmin);

router.get("/stats", adminControllers.getStats);
router.get("/chart", adminControllers.getChart);

router.get("/users", adminControllers.getUsers);
router.patch("/users/:id/status", adminControllers.updateUserStatus);

router.get("/accounts", adminControllers.getAccounts);
router.patch("/accounts/:id/status", adminControllers.updateAccountStatus);

router.get("/transactions", adminControllers.getTransactions);
router.post("/transactions/:id/reverse", adminControllers.reverseTransaction);

router.get("/payments", adminControllers.getPayments);

export default router;
