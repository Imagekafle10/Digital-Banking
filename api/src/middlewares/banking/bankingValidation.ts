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

export const createAccountValidation = validate(
  Joi.object({
    accountType: Joi.string().valid("savings", "checking", "wallet").required(),
    currency: Joi.string().length(3).optional(),
  }),
);

export const depositValidation = validate(
  Joi.object({
    accountId: Joi.string().uuid().required(),
    amount: Joi.number().positive().required(),
    remarks: Joi.string().max(255).optional(),
  }),
);

export const withdrawValidation = validate(
  Joi.object({
    accountId: Joi.string().uuid().required(),
    amount: Joi.number().positive().required(),
    remarks: Joi.string().max(255).optional(),
  }),
);

export const transferValidation = validate(
  Joi.object({
    fromAccountId: Joi.string().uuid().required(),
    // Exactly 16 digits, numbers only
    toAccountNumber: Joi.string()
      .pattern(/^\d{16}$/)
      .required()
      .messages({
        "string.pattern.base": "Account number must be exactly 16 digits",
      }),
    amount: Joi.number().positive().required(),
    remarks: Joi.string().max(255).optional(),
  }),
);
