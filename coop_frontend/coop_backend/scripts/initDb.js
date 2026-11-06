const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

async function initDb() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
  });

  try {
    const schema = fs.readFileSync(path.join(__dirname, '..', 'schema.sql'), 'utf8');
    await connection.query(schema);
    console.log(`Database '${process.env.DB_NAME || 'coop_db'}' is ready.`);
  } finally {
    await connection.end();
  }
}

initDb().catch((error) => {
  console.error('Database initialization failed:', error.message);
  process.exit(1);
});
