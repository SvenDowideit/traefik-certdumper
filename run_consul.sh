#!/bin/bash
# Extracts certs and keys from Traefik ACME Consul configuration
# Author: @thomvaill
#
# Special thanks to @camilb (https://github.com/containous/traefik/issues/3847#issuecomment-425386416) for the Consul commands
#
set -e

###
# dump_consul_acme_json($json)
#  string $json: JSON ACME configuration from Consul
# 
# This function reproduces the behavior of https://github.com/containous/traefik/blob/master/contrib/scripts/dumpcerts.sh
# It extracts the private key and cert for each domain to /traefik/ssl/{certs,private}
#
function dump_consul_acme_json() {
    json=$1

    cert_urls=$(echo $json | jq -r '.DomainsCertificate.Certs[].Certificate.CertURL')
    for cert_url in $cert_urls; do
        log "Dumping $cert_url..."

        domain=$(echo $json | jq -r --arg cert_url "$cert_url" '.DomainsCertificate.Certs[] | select (.Certificate.CertURL == $cert_url) | .Certificate.Domain')
        log "-> main domain: $domain"

        log "Extracting cert bundle..."
        cert=$(echo $json | jq -r --arg cert_url "$cert_url" '.DomainsCertificate.Certs[] | select (.Certificate.CertURL == $cert_url) | .Certificate.Certificate')
        echo $cert | base64 -d > /traefik/ssl/certs/$domain.crt
        
        log "Extracting private key..."
        key=$(echo $json | jq -r --arg cert_url "$cert_url" '.DomainsCertificate.Certs[] | select (.Certificate.CertURL == $cert_url) | .Certificate.PrivateKey')
        echo $key | base64 -d > /traefik/ssl/private/$domain.key
    done
}

###
# convert_to_pem()
#
# Same function as dump() from run_default.sh, to have the same behavior between the 2 modes:
# - copy .crt and .key files to /traefik/ssl root
# - generate .pem files into /traefik/ssl/pem
#
function convert_to_pem() {
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

###
# log()
#
function log() {
    echo "[$(date)] $@"
}




mkdir -p "/traefik/ssl/"{certs,private}
mkdir -p /traefik/ssl/pem/

if [ -z $CERTDUMPER_CONSUL_ADDR ]; then
    log "Please set CERTDUMPER_CONSUL_ADDR environment variable!"
    exit 1
fi

# Test consul key existence by retreiving its ModifyIndex
# We will use this index later for watching changes
acme_modify_index=$(consul-cli kv read \
                    --consul=$CERTDUMPER_CONSUL_ADDR \
                    --format=text \
                    --fields=ModifyIndex \
                    $CERTDUMPER_CONSUL_PREFIX/acme/account/object)

while true; do
    if [ -z $acme_modify_index ]; then
        log "No entry found in $CERTDUMPER_CONSUL_ADDR/$CERTDUMPER_CONSUL_PREFIX/acme/account/object"
        exit 1
    fi

    # Decompress consul value
    # We have to fetch it again because bash does not handle binary variables :(
    log "Retreiving $CERTDUMPER_CONSUL_ADDR/$CERTDUMPER_CONSUL_PREFIX/acme/account/object..."
    acme_json=$(consul-cli kv read \
                --consul=$CERTDUMPER_CONSUL_ADDR \
                --format=text \
                --fields=Value \
                $CERTDUMPER_CONSUL_PREFIX/acme/account/object | gzip -dc)

    # Dump certs
    log "Dumping certs..."
    dump_consul_acme_json $acme_json
    convert_to_pem
    log "Done"

    # Wait for a value change
    log "Waiting for an update of $CERTDUMPER_CONSUL_ADDR/$CERTDUMPER_CONSUL_PREFIX/acme/account/object (ModifyIndex $acme_modify_index)..."
    acme_modify_index=$(consul-cli kv watch \
                        --consul=$CERTDUMPER_CONSUL_ADDR \
                        --wait-index=$acme_modify_index \
                        --format=text \
                        --fields=ModifyIndex \
                        $CERTDUMPER_CONSUL_PREFIX/acme/account/object)
    log "Value has been updated, dumping again..."
done
