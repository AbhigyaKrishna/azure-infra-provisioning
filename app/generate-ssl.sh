#!/bin/bash

set -e
CERT_PATH="${1:-/etc/nginx/certs}"

mkdir -p "$CERT_PATH"

openssl genrsa -out "$CERT_PATH/ssl.key" 2048

openssl req -new -key "$CERT_PATH/ssl.key" -out "$CERT_PATH/ssl.csr" -subj "/C=IN/ST=Delhi/L=Delhi/O=Devops/OU=IT/CN=nginx-app"

openssl x509 -req -days 365 -in "$CERT_PATH/ssl.csr" -signkey "$CERT_PATH/ssl.key" -out "$CERT_PATH/ssl.crt"

chmod 644 "$CERT_PATH/ssl.crt"
chmod 600 "$CERT_PATH/ssl.key"

echo "Self-signed SSL certificate and key have been generated in $CERT_PATH"
echo "Certificate: $CERT_PATH/ssl.crt"
echo "Key: $CERT_PATH/ssl.key"