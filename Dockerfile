
FROM node:12.16.1-alpine3.9
WORKDIR /app
COPY dirik/index.js .
RUN npm install
CMD node index.js
EXPOSE 80
