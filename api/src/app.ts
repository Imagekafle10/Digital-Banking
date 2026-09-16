import express, { Request, Response, NextFunction } from "express";
import cookieParser from "cookie-parser";
import cors from "cors";
import helmet from "helmet";
import authRoutes from "./routes/authRoutes";
import bankingRoutes from "./routes/bankingRoutes";
import paymentRoutes from "./routes/paymentRoutes";
import { REACT_APP_URL, NODE_ENV } from "./config";

const app = express();

const allowedOrigins = ["http://localhost:8888", "http://192.168.18.201:8888"];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
  }),
);
app.use(helmet());
app.use(cookieParser());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/banking", bankingRoutes);
app.use("/api/payment", paymentRoutes);

app.use((req, res) => {
  res.status(404).json({ message: "Page not found" });
});

// Centralized error handler - every controller's `next(error)` lands here.
// This didn't exist before, so unhandled errors (including the banking and
// payment controllers' `next(error)` calls) were falling through to
// Express's default HTML error page. AppError instances (thrown from
// authService) carry a real statusCode; anything else - like the plain
// `throw new Error(...)` used in bankingService/paymentService - still
// falls back to 500, same behavior as before, just returned as JSON now.
app.use(
  (
    err: Error & { statusCode?: number },
    req: Request,
    res: Response,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    next: NextFunction,
  ) => {
    if (NODE_ENV !== "production") console.error(err);
    const statusCode = err.statusCode || 500;
    res
      .status(statusCode)
      .json({ message: err.message || "Internal server error" });
  },
);

export default app;
