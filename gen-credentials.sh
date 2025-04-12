#!/bin/bash

# Create output directory
mkdir -p credentials

# Generate CA key and certificate
openssl genrsa -out credentials/ca_key.pem 2048
openssl req -new -x509 -days 3650 -key credentials/ca_key.pem -out credentials/ca_cert.pem -subj "/CN=SnackSync CA"
openssl x509 -outform der -in credentials/ca_cert.pem -out credentials/ca_cert.der

# Generate client key and certificate
openssl genrsa -out credentials/client_key.pem 2048
openssl req -new -key credentials/client_key.pem -out credentials/client.csr -subj "/CN=SnackSync Client"
openssl x509 -req -days 3650 -in credentials/client.csr -CA credentials/ca_cert.pem -CAkey credentials/ca_key.pem -CAcreateserial -out credentials/client_cert.pem

# Create P12 file from client key and certificate
openssl pkcs12 -export -out credentials/client_identity.p12 -inkey credentials/client_key.pem -in credentials/client_cert.pem -passout pass: