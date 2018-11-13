FROM alpine

RUN apk --no-cache add inotify-tools jq openssl util-linux bash
RUN wget https://raw.githubusercontent.com/containous/traefik/master/contrib/scripts/dumpcerts.sh -O dumpcerts.sh
RUN mkdir -p /traefik/ssl/

COPY run.sh /
ENTRYPOINT ["/run.sh"]