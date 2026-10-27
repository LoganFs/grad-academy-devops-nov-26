# Image for the Social Hub app container(s).
# Build context is the app directory (server.js + package.json alongside).
FROM node:18-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./

EXPOSE 80
CMD ["node", "server.js"]
