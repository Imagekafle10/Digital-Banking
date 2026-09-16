# Image Bank — Flutter Frontend

A blue & white Flutter client for the included Node/Express mobile-banking
backend, covering the full flow:

**Login / Register → Dashboard (balance, quick actions, recent activity) → Deposit / Withdraw / Transfer → Pay (Khalti / eSewa) → Transaction history**

## What's wired up to the backend

| Screen                                   | Endpoint(s)                                                                                                                                                                                                                                                            |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Login / Register                         | `POST /api/auth/login`, `POST /api/auth/register`                                                                                                                                                                                                                      |
| Silent session restore on launch         | `POST /api/auth/refresh` (uses the httpOnly `refreshToken` cookie)                                                                                                                                                                                                     |
| Logout                                   | `POST /api/auth/logout`                                                                                                                                                                                                                                                |
| Dashboard / open account                 | `GET /api/banking/account/me`, `POST /api/banking/account`                                                                                                                                                                                                             |
| Deposit / Withdraw / Transfer            | `POST /api/banking/deposit`, `/withdraw`, `/transfer`                                                                                                                                                                                                                  |
| Transaction history (paged + filterable) | `GET /api/banking/transactions/:accountId`                                                                                                                                                                                                                             |
| Pay                                      | `POST /api/payment/initiate`, then a WebView completes checkout with **Khalti** (direct URL) or **eSewa** (auto-submitted signed form), and the app reads the result straight from the backend's own `/api/payment/khalti/return` / `/api/payment/esewa/return` routes |

The access token is kept in memory + `shared_preferences`; the refresh
token cookie is kept in a persisted cookie jar (`cookie_jar` +
`dio_cookie_manager`), so a 401 triggers one silent refresh-and-retry
(see `lib/services/api_client.dart`).

## 1. Point the app at your backend

Open `lib/core/constants/api_constants.dart`. By default it targets:

- Android emulator: `http://10.0.2.2:5000/api`
- iOS simulator / desktop / web: `http://localhost:5000/api`

For a **physical device**, replace the host with your computer's LAN IP
(e.g. `http://192.168.1.20:5000/api`), and make sure your backend's
`.env` → `REACT_APP_URL` (used for CORS) allows that origin, or just
`*`/your dev origin while testing.

## 2. Set up the Flutter project

This folder is `lib/` + `pubspec.yaml` only — no `android/`, `ios/`, etc.
Generate those with Flutter itself so they match your installed SDK:

```bash
cd nepal_bank            # this folder
flutter create .         # adds android/ ios/ etc. without touching lib/ or pubspec.yaml
flutter pub get
flutter run
```

## 3. Run the backend

From the backend project (the uploaded zip):

```bash
npm install
npm run dev   # or however package.json defines it
```

Make sure the MySQL database from `sql/schema.sql` is set up and your
`.env` is filled in (DB credentials, JWT secrets, Khalti/eSewa keys).

## Design

- Primary blue `#1652F0` with a soft blue-tinted background and pure
  white cards — see `lib/core/theme/app_theme.dart` for the full palette
  and component theming (buttons, inputs, cards, snackbars).
- A gradient hero **balance card**, rounded quick-action buttons, and a
  clean transaction list drive the dashboard.

## Notes / things to double check before shipping

- `AppUser`/`BankAccount`/`BankTransaction`/`PaymentResult` mirror the
  backend's `SafeUser`, `IAccount`, `ITransaction`, `IPayment` shapes
  (see `src/types/*.types.ts` in the backend).
- The eSewa return-URL interception matches on the substring
  `/api/payment/esewa/return`; confirm your `ESEWA_SUCCESS_URL` /
  `ESEWA_FAILURE_URL` in the backend `.env` actually point back to that
  route (that's what the backend controller expects) before testing a
  live payment.
- `withdraw`/`transfer` validate `amount <= balance` client-side for a
  faster error, but the backend is the source of truth.
