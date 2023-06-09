ARG NATS_VERSION
FROM nats:${NATS_VERSION}

COPY ./nats/standalone.conf /standalone.conf

CMD ["-c", "/standalone.conf"]