FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
RUN apt-get update && apt-get install -y python3 python3-pip wget
COPY . /app
WORKDIR /app

FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
ENV NODE_OPTIONS=--max_old_space_size=4096
RUN pnpm run build

FROM base
ARG PUBLIC_POCKETBASE_URL
ARG ROOT_ADMIN_EMAIL
ARG ROOT_ADMIN_PASSWORD
ARG ORIGIN="http://localhost:5173"
ARG PORT=5173
ARG PUBLIC_HTTPS_ONLY="false"
ARG PUBLIC_SIGNUP_DISABLED="false"

ENV PUBLIC_POCKETBASE_URL=$PUBLIC_POCKETBASE_URL
ENV ROOT_ADMIN_EMAIL=$ROOT_ADMIN_EMAIL
ENV ROOT_ADMIN_PASSWORD=$ROOT_ADMIN_PASSWORD
ENV ORIGIN=$ORIGIN
ENV PORT=$PORT
ENV PUBLIC_HTTPS_ONLY=$PUBLIC_HTTPS_ONLY
ENV PUBLIC_SIGNUP_DISABLED=$PUBLIC_SIGNUP_DISABLED

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/build /app/build
COPY --from=build /app/package.json /app/package.json
COPY --from=base /app/pb_migrations /app/pb_migrations
ENV NODE_ENV=production
EXPOSE $PORT
CMD [ "node", "-r", "dotenv/config", "build" ]