

FROM ghcr.io/gleam-lang/gleam:v1.2.1-erlang-alpine

# Add project code
COPY . /build/

RUN apk add --update tar curl git bash make libc-dev gcc g++ vim && \
  rm -rf /var/cache/apk/*

RUN set -xe \
  && curl -fSL -o rebar3 "https://s3.amazonaws.com/rebar3-nightly/rebar3" \
  && chmod +x ./rebar3 \
  && ./rebar3 local install \
  && rm ./rebar3

ENV PATH "$PATH:/root/.cache/rebar3/bin"

# Compile the project
RUN cd /build && gleam export erlang-shipment
RUN cd /build && mv build/erlang-shipment /app

RUN mv build/.env /app
RUN mv build/db.sql /app
RUN mv build/views /app
RUN mv build/priv /app

RUN rm -r /build

# Run the server
WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]