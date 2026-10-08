# COOP Backend API

Express + MySQL API used by both the member app and the admin website.

## Setup

1. Copy `.env.example` to `.env` and update the MySQL credentials if needed.
2. Install dependencies with `npm install`.
3. Create and seed the database with `npm run init-db`.
4. Start the API with `npm run dev`.

The API runs at `http://localhost:5000` by default.

## Connection Points

- Admin website: `coop_frontend_admin/.env.local` uses `NEXT_PUBLIC_API_URL=http://localhost:5000`.
- Member app: `coop_frontend/index.html` uses `http://localhost:5000` by default.
- Database: configured through `DB_*` values in `coop_backend/.env`.

## Endpoints

- `GET /health`
- `GET /api/loan-applications`
- `GET /api/loan-applications/:id`
- `POST /api/loan-applications`
- `PATCH /api/loan-applications/:id`
