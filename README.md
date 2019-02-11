# traefik-certdumper
Dump the Lets Encrypt certs that Traefik stores in acme.json or in Consul - to .crt, .key and .pem.

Pretty much to solve https://github.com/containous/traefik/issues/2418 using @flesser's
compose-file script and https://github.com/containous/traefik/blob/master/contrib/scripts/dumpcerts.sh
with a few little mods.

## Default mode: acme.json
This is the default mode. In this case, you just have to mount `acme.json` on `/traefik/acme.json`.
The certs will be dumped to `/traefik/ssl`.

Here is a Docker Swarm stack configuration example:

```
  # Watch acme.json and dump certificates to files
  # https://github.com/containous/traefik/issues/2418#issuecomment-369225856
  certdumper:
    image: svendowideit/traefik-certdumper:latest
    volumes:
      - traefikdata:/traefik
    deploy:
      mode: replicated
      replicas: 1
```

## Consul mode
When you run multiple Traefik instances, it usually uses a KV store to store Lets Encrypt certs, instead of `acme.json`.
Consul is currently the [recommanded KV store](https://docs.traefik.io/user-guide/cluster/).

To enable this mode, you have to:
* set the environment variable `CERTDUMPER_MODE` to `consul`
* set the environment variable `CONSUL_HTTP_ADDR` (`host:port`)
* override the environment variable `CERTDUMPER_CONSUL_PREFIX` if needed (defaults to `traefik`)

Here is a Docker Swarm stack configuration example:

```
  # Watch acme configuration from Consul and dump certificates to files
  certdumper:
    image: svendowideit/traefik-certdumper:latest
    environment:
      - CERTDUMPER_MODE=consul
      - CERTDUMPER_CONSUL_ADDR=traefik_consul:8500
    volumes:
      - traefikcerts:/traefik/ssl
    networks:
      - traefik
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 60s
```
