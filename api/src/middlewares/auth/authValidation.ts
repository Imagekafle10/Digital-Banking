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

export const registerValidation = validate(
  Joi.object({
    fullName: Joi.string().min(2).max(100).required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(8).required(),
    phone: Joi.string().min(7).max(20).required(),
    dateOfBirth: Joi.string().isoDate().required(),
    gender: Joi.string().valid("Male", "Female", "Other").required(),
  }),
);

export const loginValidation = validate(
  Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),
  }),
);
