# ==============================
# ETAPA 1: CONSTRUCCIÓN (BUILDER)
# ==============================
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar los package.json de ambos proyectos para instalar dependencias
COPY prx-backend/package*.json ./prx-backend/
COPY prx-frontend/package*.json ./prx-frontend/

# Instalar dependencias del backend
RUN cd prx-backend && npm install

# Instalar dependencias del frontend
RUN cd prx-frontend && npm install

# Copiar TODO el código fuente
COPY . .

# Construir el backend (NestJS)
RUN cd prx-backend && npm run build

# Construir el frontend
# 🔥 IMPORTANTE: Si tu frontend usa "Create React App", la carpeta de salida se llama "build".
# Si usa Vite, se llama "dist". Ajusta la línea de abajo según corresponda.
RUN cd prx-frontend && npm run build

# ==============================
# ETAPA 2: IMAGEN DE PRODUCCIÓN
# ==============================
FROM node:20-alpine

WORKDIR /app

# Copiar los artefactos construidos desde la etapa anterior
COPY --from=builder /app/prx-backend/dist ./prx-backend/dist
COPY --from=builder /app/prx-backend/node_modules ./prx-backend/node_modules
COPY --from=builder /app/prx-backend/package.json ./prx-backend/package.json
COPY --from=builder /app/prx-backend/prisma ./prx-backend/prisma

# Copiar los archivos estáticos del frontend (ajusta 'dist' o 'build' según tu caso)
# Esto los dejará en /app/prx-frontend-static dentro del contenedor
COPY --from=builder /app/prx-frontend/dist ./prx-frontend-static

# Moverse a la carpeta del backend para ejecutarlo
WORKDIR /app/prx-backend

# Generar el cliente de Prisma (necesario para producción)
RUN npx prisma generate

# Exponer el puerto que usa NestJS (normalmente 3000)
EXPOSE 3000

# Comando para iniciar el servidor
CMD ["node", "dist/main"]