# Build SvelteKit App
FROM node:25-alpine AS build
ENV DATABASE_URL="postgresql://user:password@localhost:5432/app"
ENV VERSION=1
ENV PUBLIC_PAGE_SIZE=30
ENV DASHBOARD_APP_PATH=.
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm prune --production

# Build OCaml App
FROM ocaml/opam:alpine-3.22-ocaml-4.14-afl AS dashboard
WORKDIR /dashboard
USER root
RUN apk add --no-cache git openssh-client pcre-dev m4
USER root
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh \
    git clone git@github.com:sws-lab/open-verification-dashboard.git
RUN chown -R opam:opam /dashboard/open-verification-dashboard
USER opam
WORKDIR /dashboard/open-verification-dashboard
RUN opam install . --deps-only -y
RUN opam exec -- dune exec dashboard -- --help


# Final Production Image
FROM node:25-alpine AS prod
WORKDIR /app
RUN addgroup -S dashboardGui && adduser -S app -G dashboardGui && \
    mkdir projects && \
	chown app:dashboardGui projects
USER app
COPY --from=build /app/build build/
COPY --from=build /app/node_modules node_modules/
COPY --from=dashboard /dashboard/open-verification-dashboard/_build/default/bin/main.exe ./dashboard.exe
RUN ./dashboard.exe --help
COPY package.json .
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "build"]
