import mysql, { Pool } from "mysql2/promise";
import { DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, DB_PORT } from "./index";

// If your project already has a config/database.ts exporting a mysql2 pool,
// use that one instead - the models below just expect a default-exported
// `Pool` with the standard mysql2/promise interface (query, getConnection).
const pool: Pool = mysql.createPool({
  host: DB_HOST,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  port: DB_PORT ? Number(DB_PORT) : 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  decimalNumbers: true, // return DECIMAL columns as JS numbers, not strings
});

export default pool;
