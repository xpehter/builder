FROM node:12.16.1-alpine3.9
WORKDIR /app

ARG arg_REPO_LOCAL_DIR
COPY ${arg_REPO_LOCAL_DIR}/index.js .
RUN npm install
CMD node index.js
EXPOSE 80
