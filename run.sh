#!/bin/bash

function dump() {
    bash dumpcerts.sh /traefik/acme.json /traefik/ssl/
    ln -f /traefik/ssl/certs/* /traefik/ssl/
    ln -f /traefik/ssl/private/* /traefik/ssl/
    for crt_file in $(ls certs); do
        pem_file=$(echo $crt_file | sed 's/.crt/.pem/g' | sed 's/certs/pem/g')
        openssl x509 -inform PEM -in $crt_file > $pem_file
    done 
    for key_file in $(ls private); do
        pem_file=$(echo $key_file | sed 's/.key/.pem/g' | sed 's/private/pem/g')
        openssl rsa -in $key_file -text > $pem_file
    done
}

mkdir -p /traefik/pem/
# run once on start to make sure we have any old certs
dump

while true; do
    inotifywait -e modify /traefik/acme.json
    dump
done