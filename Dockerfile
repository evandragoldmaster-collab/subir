# ==============================
# ETAPA 1: CONSTRUCCIÓN (BUILDER)
# ==============================
FROM node:24-alpine AS builder

WORKDIR /app

# ✅ DATABASE_URL ficticio solo para que prisma generate no falle en build
ARG DATABASE_URL="postgresql://build:build@localhost:5432/build"
ENV DATABASE_URL=$DATABASE_URL

# --- Dependencias Backend ---
COPY prx-backend/package*.json ./prx-backend/
RUN cd prx-backend && npm ci

# --- Dependencias Frontend ---
COPY prx-frontend/package*.json ./prx-frontend/
RUN cd prx-frontend && npm ci

# Copiar TODO el código fuente
COPY . .

# Build Backend (NestJS) — prisma generate usa DATABASE_URL ficticio
RUN cd prx-backend && npm run build

# Build Frontend (Angular)
RUN cd prx-frontend && npm run build

# ==============================
# ETAPA 2: IMAGEN DE PRODUCCIÓN
# ==============================
FROM node:24-alpine

WORKDIR /app

# Backend
COPY --from=builder /app/prx-backend/dist          ./prx-backend/dist
COPY --from=builder /app/prx-backend/node_modules  ./prx-backend/node_modules
COPY --from=builder /app/prx-backend/package.json  ./prx-backend/package.json
COPY --from=builder /app/prx-backend/prisma        ./prx-backend/prisma

# Frontend
COPY --from=builder /app/prx-frontend/dist/prx-frontend/browser ./prx-frontend-static

WORKDIR /app/prx-backend

# ✅ En producción, Railway inyecta el DATABASE_URL real
RUN npx prisma generate

EXPOSE 3000

CMD ["node", "dist/main"]