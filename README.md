# Vault JKS
[![Docker Repository on Quay](https://quay.io/repository/ukhomeofficedigital/vaultjks/status "Docker Repository on Quay")](https://quay.io/repository/ukhomeofficedigital/vaultjks)

A simple script to fetch a CA and request certificates from vault and stick
them into JAVA keystore files.

### Requirements
A working vault server and PKI backend mounted with long enough TTLs.

### Configuration
- `VAULT_ADDR` - Vault address. Required.
- `VAULT_AUTH_FILE` - If specified, this file will be sourced. This file can
  contain VAULT_TOKEN or VAULT_USER and VAULT_PASSWORD.
- `VAULT_TOKEN` - If specified, the token will be used for auth.
- `VAULT_USER` - If `VAULT_TOKEN` is unset, then this needs to be set.
- `VAULT_PASSWORD` - Required if `VAULT_TOKEN` is not being used.
- `VAULT_PKI_PATH` - Vault pki backend mount path. Default: `shared/pki`.
- `VAULT_ROLE_NAME` - Vault pki backend role for requesting a new cert. Default: `cert-request`.
- `CERT_COMMON_NAME` - Certificate request CN. Default: `localhost`.
- `IP_SAN` - IP address to add to ip_sans. Default: `$(hostname -i)`.
- `IMPORT_SYSTEM_TRUSTSTORE`: If `true`, import `/etc/pki/java/cacerts` into a `TRUSTSTORE_FILE`. Default: `true`.
- `TRUSTSTORE_FILE` - Where to write truststore file. Default: `truststore.jks`.
- `KEYSTORE_FILE` - Where to write keystore file. Default: `keystore.jks`.


### Running
```bash
$ docker run -ti \
  -e VAULT_ADDR=https://vault:8200 \
  -e VAULT_TOKEN=44eecf54-5b01-4bd5-a8c4-f4032b9e7e10 \
  -v /keystore:/data \
  quay.io/ukhomeofficedigital/vaultjks:v0.0.2
```
