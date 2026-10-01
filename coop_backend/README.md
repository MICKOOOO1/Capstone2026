# COOP Backend API

Express.js backend for the COOP application with MySQL database integration.

## Prerequisites

- Node.js (v14 or higher)
- MySQL Server (v5.7 or higher)
- npm or yarn

## Installation

1. Install dependencies:
```bash
npm install
```

2. Set up MySQL database:
```bash
npm run init-db
```

This will create the database and tables with sample data.

## Environment Variables

Create a `.env` file in the root directory:

```
PORT=5000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=coop_db
```

Update the database credentials according to your MySQL setup.

## Database Setup

The system uses MySQL with the following tables:
- `members` - Member information
- `loan_applications` - Loan application records
- `loan_payments` - Payment tracking
- `savings_accounts` - Member savings accounts

### Manual Database Setup

If you prefer to set up the database manually:

1. Create a MySQL database named `coop_db`
2. Run the SQL schema:
```bash
mysql -u root -p coop_db < schema.sql
```

## Running the Server

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

The server will start on port 5000 by default.

## API Endpoints

### Root
- `GET /` - Welcome message

### Health Check
- `GET /health` - Server health status

### Loan Applications
- `GET /api/loan-applications` - Get all loan applications
- `GET /api/loan-applications/:id` - Get single loan application
- `POST /api/loan-applications` - Create new loan application
- `PATCH /api/loan-applications/:id` - Update loan application status

## Project Structure

```
coop_backend/
├── index.js                 # Main server file
├── config/
│   └── database.js          # MySQL connection configuration
├── routes/                  # API route handlers
│   └── loanApplications.js  # Loan application routes
├── scripts/
│   └── initDb.js            # Database initialization script
├── schema.sql               # Database schema definition
├── .env                     # Environment variables
├── .gitignore              # Git ignore file
├── package.json            # Dependencies and scripts
└── README.md               # This file
```