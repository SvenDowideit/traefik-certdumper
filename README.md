# traefik-certdumper
dump the Lets Encrypt certs that Traefik stores in acme.json - to .crt, .key and .pem

pretty much to solve https://github.com/containous/traefik/issues/2418 using @flesser's
compose-file script and https://github.com/containous/traefik/blob/master/contrib/scripts/dumpcerts.sh
with a few little mods

I use Docker Swarm, so my additional compose file service is:

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
