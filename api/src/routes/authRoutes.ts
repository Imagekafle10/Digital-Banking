import express from "express";
import authControllers from "../controllers/authControllers";
import auth from "../middlewares/auth/auth";
import {
  registerValidation,
  loginValidation,
} from "../middlewares/auth/authValidation";

const router = express.Router();

router.post("/register", registerValidation, authControllers.register);
router.post("/login", loginValidation, authControllers.login);

// No `auth` guard here - the whole point is to get a new access token once
// the old one has expired, using the httpOnly refresh cookie instead.
router.post("/refresh", authControllers.refresh);

router.post("/logout", auth, authControllers.logout);
router.get("/me", auth, authControllers.getMe);

export default router;
