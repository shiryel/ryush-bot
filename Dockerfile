###############
# Build stage #
###############
FROM elixir:1.13-alpine as build

RUN mix local.hex --force
RUN mix local.rebar --force

COPY mix.lock mix.lock
COPY mix.exs mix.exs
RUN mix deps.get

COPY assets assets
COPY lib lib
COPY priv priv
COPY config config

ARG MIX_ENV="prod"

RUN mix release core --path /export/app

####################
# Deployment Stage #
####################
FROM erlang:24-alpine

USER nobody
COPY --from=build --chown=nobody:nogroup /export/app /app

EXPOSE 4000

ARG SECRET_KEY_BASE
ARG BOT_CLIENT_ID
ARG BOT_TOKEN

ENV PHX_SERVER=true
ENV RELEASE_NAME=core

WORKDIR /app
ENTRYPOINT ["/app/bin/core"]
CMD ["start"]
