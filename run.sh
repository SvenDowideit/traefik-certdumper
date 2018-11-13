#!/bin/bash

function dump() {
    bash dumpcerts.sh /traefik/acme.json /traefik/ssl/
    ln -f /traefik/ssl/certs/* /traefik/ssl/
    ln -f /traefik/ssl/private/* /traefik/ssl/
    for crt_file in $(ls /traefik/ssl/certs/*); do
        pem_file=$(echo $crt_file | sed 's/certs/pem/g' | sed 's/.crt/-public.pem/g')
        echo "openssl x509 -inform PEM -in $crt_file > $pem_file"
        openssl x509 -inform PEM -in $crt_file > $pem_file
    done 
    for key_file in $(ls /traefik/ssl/private/*); do
        pem_file=$(echo $key_file | sed 's/private/pem/g' | sed 's/.key/-private.pem/g')
        echo "openssl rsa -in $key_file -text > $pem_file"
        openssl rsa -in $key_file -text > $pem_file
    done
}

mkdir -p /traefik/ssl/pem/
# run once on start to make sure we have any old certs
dump

while true; do
    inotifywait -e modify /traefik/acme.json
    dump
done