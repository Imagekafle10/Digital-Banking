import app from "./app";
import pool from "./config/database";
import { PORT } from "./config";

const start = async () => {
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    console.log("Database connected");
  } catch (error) {
    console.error("Database connection failed:", error);
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`Server is listening at ${PORT}`);
  });
};

start();
