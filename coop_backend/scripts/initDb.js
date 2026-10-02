const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

async function initializeDatabase() {
  try {
    // Connect to MySQL without specifying a database first
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || ''
    });

    console.log('Connected to MySQL server');

    // Read the schema file
    const schemaPath = path.join(__dirname, '..', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Split schema into individual statements
    const statements = schema
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    // Execute each statement
    for (const statement of statements) {
      try {
        await connection.execute(statement);
        console.log('✓ Executed:', statement.substring(0, 50) + '...');
      } catch (error) {
        if (error.code !== 'ER_TABLE_EXISTS_ERROR' && error.code !== 'ER_DB_CREATE_EXISTS') {
          console.error('✗ Error executing statement:', error.message);
          console.error('Statement:', statement.substring(0, 100));
        }
      }
    }

    await connection.end();
    console.log('\n✓ Database initialization completed successfully!');
    console.log(`✓ Database '${process.env.DB_NAME || 'coop_db'}' is ready to use`);

  } catch (error) {
    console.error('✗ Database initialization failed:', error.message);
    process.exit(1);
  }
}

initializeDatabase();