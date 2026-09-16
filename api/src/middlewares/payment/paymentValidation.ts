import { Request, Response, NextFunction } from "express";
import Joi from "joi";

const validate =
  (schema: Joi.ObjectSchema) =>
  (req: Request, res: Response, next: NextFunction) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        message: "Validation error",
        errors: error.details.map((d) => d.message),
      });
    }
    next();
  };

export const initiatePaymentValidation = validate(
  Joi.object({
    accountId: Joi.string().uuid().required(),
    provider: Joi.string().valid("khalti", "esewa").required(),
    amount: Joi.number().positive().required(),
    remarks: Joi.string().max(255).optional(),
  })
);
