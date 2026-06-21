# ==============================
# ETAPA 1: CONSTRUCCIÓN (BUILDER)
# ==============================
FROM node:24-alpine AS builder

WORKDIR /app

ARG DATABASE_URL="postgresql://build:build@localhost:5432/build"
ENV DATABASE_URL=$DATABASE_URL

COPY prx-backend/package*.json ./prx-backend/
RUN cd prx-backend && npm ci

COPY prx-frontend/package*.json ./prx-frontend/
RUN cd prx-frontend && npm ci

COPY . .

RUN cd prx-backend && npm run build
RUN cd prx-frontend && npm run build

# ==============================
# ETAPA 2: IMAGEN DE PRODUCCIÓN
# ==============================
FROM node:24-alpine

WORKDIR /app

COPY --from=builder /app/prx-backend/dist          ./prx-backend/dist
COPY --from=builder /app/prx-backend/node_modules  ./prx-backend/node_modules
COPY --from=builder /app/prx-backend/package.json  ./prx-backend/package.json
COPY --from=builder /app/prx-backend/prisma        ./prx-backend/prisma

# Copiar también el cliente generado de Prisma
COPY --from=builder /app/prx-backend/generated     ./prx-backend/generated

COPY --from=builder /app/prx-frontend/dist/prx-frontend/browser ./prx-frontend-static

WORKDIR /app/prx-backend

ARG DATABASE_URL="postgresql://build:build@localhost:5432/build"
ENV DATABASE_URL=$DATABASE_URL

RUN npx prisma generate

# ✅ Muestra qué archivos .js hay en dist (visible en los Build Logs)
RUN echo "=== ARCHIVOS EN DIST ===" && find dist -name "*.js" | sort

EXPOSE 3000

# ✅ Intenta dist/main primero, si falla prueba dist/src/main
CMD ["sh", "-c", "if [ -f dist/main.js ]; then node dist/main; elif [ -f dist/src/main.js ]; then node dist/src/main; else echo 'ERROR: main.js no encontrado' && find dist -name '*.js' && exit 1; fi"]