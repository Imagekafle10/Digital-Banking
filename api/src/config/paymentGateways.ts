export const khaltiConfig = {
  secretKey: process.env.KHALTI_SECRET_KEY as string,
  initiateUrl:
    process.env.KHALTI_INITIATE_URL ||
    "https://dev.khalti.com/api/v2/epayment/initiate/",
  lookupUrl:
    process.env.KHALTI_LOOKUP_URL ||
    "https://dev.khalti.com/api/v2/epayment/lookup/",
  returnUrl: process.env.KHALTI_RETURN_URL as string,
  websiteUrl: process.env.WEBSITE_URL as string,
};

export const esewaConfig = {
  // EPAYTEST / this secret are eSewa's published sandbox test credentials
  productCode: process.env.ESEWA_PRODUCT_CODE || "EPAYTEST",
  secretKey: process.env.ESEWA_SECRET_KEY || "8gBm/:&EnhH.1/q",
  formUrl:
    process.env.ESEWA_FORM_URL ||
    "https://rc-epay.esewa.com.np/api/epay/main/v2/form",
  statusUrl:
    process.env.ESEWA_STATUS_URL ||
    "https://rc.esewa.com.np/api/epay/transaction/status",
  successUrl: process.env.ESEWA_SUCCESS_URL as string,
  failureUrl: process.env.ESEWA_FAILURE_URL as string,
};
