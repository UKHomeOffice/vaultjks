#!/bin/env bash

[[ -n ${DEBUG} ]] && set -o xtrace
set -o pipefail

if [[ ! -n ${VAULT_TOKEN} ]]; then
  : ${VAULT_USER:?}
  : ${VAULT_PASSWORD:?}
fi
: ${VAULT_ADDR:?}
: ${VAULT_PKI_PATH:=shared/pki}
: ${VAULT_ROLE_NAME:=cert-request}
: ${CERT_COMMON_NAME:=localhost}
: ${IP_SAN:=$(hostname -i)}

: ${IMPORT_SYSTEM_TRUSTSTORE:=true}
: ${TRUSTSTORE_FILE:=truststore.jks}
: ${KEYSTORE_FILE:=keystore.jks}


# Uses username and password pair to get an auth token from vault
function get_token() {
  echo 'Authenticating and getting a token.'
  VAULT_TOKEN=$(curl -L -f -s -k ${VAULT_ADDR}/v1/auth/userpass/login/${VAULT_USER} \
          -d "{\"password\": \"${VAULT_PASSWORD}\"}" | jq .auth.client_token -r)
  if [[ ${?} != 0 ]]; then
    echo 'Unable to authenticate and get a token.'
    exit 1
  fi
  export VAULT_TOKEN
}


function fetch_ca_cert() {
  echo 'Fetching CA certificate.'
  curl -L -f -s -k ${VAULT_ADDR}/v1/${VAULT_PKI_PATH}/ca/pem > ca.pem
  if [[ $? != 0 ]]; then
    echo 'Unable to fetch CA certificate. Check VAULT_PKI_PATH.'
    exit 1
  fi
}


function request_cert() {
  echo 'Requesting a certificate.'
  curl -L -f -s -k -H "X-Vault-Token: ${VAULT_TOKEN}" \
    ${VAULT_ADDR}/v1/${VAULT_PKI_PATH}/issue/${VAULT_ROLE_NAME} \
    -d "{\"common_name\": \"${CERT_COMMON_NAME}\", \"ip_sans\": \"${IP_SAN},127.0.0.1\"}" > response.json
  if [[ $? != 0 ]]; then
    echo 'Unable to fetch a certificate.'
    exit 1
  fi

  jq .data.certificate -r < response.json > cert.pem
  jq .data.issuing_ca -r < response.json > ca.pem
  jq .data.private_key -r < response.json > key.pem
}


function create_truststore() {
  echo "Creating a JAVA truststore as ${TRUSTSTORE_FILE}."
  keytool -import -alias ca -file ca.pem -keystore ${TRUSTSTORE_FILE} \
    -noprompt -storepass changeit -trustcacerts

  if [[ ${IMPORT_SYSTEM_TRUSTSTORE} == 'true' ]]; then
    echo "Importing /etc/pki/java/cacerts into ${TRUSTSTORE_FILE}."
    keytool -importkeystore -destkeystore ${TRUSTSTORE_FILE} \
      -srckeystore /etc/pki/java/cacerts -srcstorepass changeit \
      -noprompt -storepass changeit &> /dev/null
  fi
}


function create_keystore() {
  echo 'Creating a temporary pkcs12 keystore.'
  cat ca.pem cert.pem > bundle.pem
  openssl pkcs12 -export -name cert -in bundle.pem -inkey key.pem -nodes \
    -CAfile ca.pem -out keystore.p12 -passout pass:

  echo "Creating a JAVA keystore as ${KEYSTORE_FILE}."
  keytool -importkeystore -destkeystore ${KEYSTORE_FILE} \
    -srckeystore keystore.p12 -srcstoretype pkcs12 \
    -alias cert -srcstorepass '' -noprompt -storepass changeit

  # Change private key password from '' to changeit
  # FIXME: Maybe there is a better way to do that in the above steps
  keytool -keypasswd -new changeit -keystore ${KEYSTORE_FILE} -storepass changeit -alias cert -keypass ''
}


if [[ ! -n ${VAULT_TOKEN} ]]; then
  get_token
fi

fetch_ca_cert
request_cert
create_truststore
create_keystore
