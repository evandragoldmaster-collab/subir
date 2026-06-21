# ==============================
# ETAPA 1: CONSTRUCCIÓN (BUILDER)
# ==============================
FROM node:24-alpine AS builder

WORKDIR /app

# --- Backend ---
COPY prx-backend/package*.json ./prx-backend/
RUN cd prx-backend && npm ci

# --- Frontend ---
COPY prx-frontend/package*.json ./prx-frontend/
RUN cd prx-frontend && npm ci

# Copiar todo el código fuente
COPY . .

# Construir el backend (NestJS)
RUN cd prx-backend && npm run build

# Construir el frontend (Angular)
# Angular 17+ genera en dist/prx-frontend/browser/
RUN cd prx-frontend && npm run build

# ==============================
# ETAPA 2: IMAGEN DE PRODUCCIÓN
# ==============================
FROM node:24-alpine

WORKDIR /app

# Backend: dist, node_modules, package.json y schema de Prisma
COPY --from=builder /app/prx-backend/dist           ./prx-backend/dist
COPY --from=builder /app/prx-backend/node_modules   ./prx-backend/node_modules
COPY --from=builder /app/prx-backend/package.json   ./prx-backend/package.json
COPY --from=builder /app/prx-backend/prisma         ./prx-backend/prisma

# Frontend: Angular 17+ usa dist/<nombre-proyecto>/browser/
# ⚠️ Ajusta "prx-frontend" al nombre real de tu proyecto Angular
COPY --from=builder /app/prx-frontend/dist/prx-frontend/browser ./prx-frontend-static

WORKDIR /app/prx-backend

# Generar cliente Prisma (el schema ya está copiado arriba)
RUN npx prisma generate

EXPOSE 3000

CMD ["node", "dist/main"]