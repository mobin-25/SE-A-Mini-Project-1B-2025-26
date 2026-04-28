# Canteen Admin Web (React)

Admin dashboard UI for your existing Spring Boot backend.

## Run

1. Open terminal in `admin-web`
2. Install dependencies: `npm install`
3. Start dev server: `npm run dev`

Default API base URL: `/api/v1` (proxied to `http://localhost:8080` via Vite).

If needed, create `.env` and set:

`VITE_API_BASE_URL=/api/v1`

## Auth Notes

- Recommended login endpoint for admin accounts with refresh token support: `POST /auth/login` with a user whose role is `ADMIN`.
- Legacy endpoint `POST /auth/admin-login` exists in backend but does not issue refresh token.

This UI is configured for refreshable JWT flow using:
- `POST /auth/login`
- `POST /auth/refresh-jwt`
