FROM ciscocloud/consul-cli:0.3.1 AS consul-cli



FROM alpine

RUN apk --no-cache add inotify-tools jq openssl util-linux bash
COPY --from=consul-cli /bin/consul-cli /bin/consul-cli
RUN wget https://raw.githubusercontent.com/containous/traefik/master/contrib/scripts/dumpcerts.sh -O dumpcerts.sh
RUN mkdir -p /traefik/ssl/

ENV CERTDUMPER_MODE=default
ENV CERTDUMPER_CONSUL_PREFIX=traefik

COPY *.sh /
ENTRYPOINT ["/run.sh"]