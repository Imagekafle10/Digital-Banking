// A plain `throw new Error(...)` (as used elsewhere in this project) always
// maps to a 500 in the error handler, since Error has no concept of an HTTP
// status. AppError lets auth code throw the *right* status (400/401/403/409)
// while everything else keeps working exactly as it did before.
class AppError extends Error {
  statusCode: number;

  constructor(message: string, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export default AppError;
