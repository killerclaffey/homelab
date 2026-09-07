#!/usr/bin/env bash
# ==============================================================================
# Script: setup-vault-paperless-ngx.sh
# Purpose: Pre-populate HashiCorp Vault with paperless-ngx app secrets required by ExternalSecret
# Vault Path: secret/homelab/paperless-ngx (kv v2 engine)
# Note: PostgreSQL database & credentials are managed 100% locally in-cluster by CloudNative-PG (CNPG)
# ==============================================================================

set -euo pipefail

# External Vault URL for local vault CLI
export VAULT_ADDR="${VAULT_ADDR:-https://vault.apps.okd.claffey.cloud}"
VAULT_PATH="secret/homelab/paperless-ngx"

echo "=================================================================="
echo "          Paperless-ngx Vault Secrets Setup Helper               "
echo "=================================================================="
echo "Target Secret Path : ${VAULT_PATH}"
echo "------------------------------------------------------------------"

# Function to generate a secure random string
generate_secret() {
  length="${1:-32}"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$((length / 2))"
  else
    tr -dc 'a-zA-Z0-9' </dev/urandom | head -c "$length"
  fi
}

SECRET_KEY="${SECRET_KEY:-}"
if [ -z "${SECRET_KEY}" ]; then
  GENERATED_KEY=$(generate_secret 50)
  read -rp "Enter App Secret Key (press Enter to use auto-generated key): " INPUT_KEY
  SECRET_KEY="${INPUT_KEY:-$GENERATED_KEY}"
fi

ADMIN_USER="${ADMIN_USER:-}"
if [ -z "${ADMIN_USER}" ]; then
  read -rp "Enter Admin Username [admin]: " ADMIN_USER
  ADMIN_USER="${ADMIN_USER:-admin}"
fi

ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
if [ -z "${ADMIN_PASSWORD}" ]; then
  GENERATED_PASS=$(generate_secret 24)
  read -rsp "Enter Admin Password (press Enter to use auto-generated pass): " INPUT_ADMIN_PASS
  echo ""
  ADMIN_PASSWORD="${INPUT_ADMIN_PASS:-$GENERATED_PASS}"
fi

ADMIN_EMAIL="${ADMIN_EMAIL:-}"
if [ -z "${ADMIN_EMAIL}" ]; then
  read -rp "Enter Admin Email [admin@claffey.cloud]: " ADMIN_EMAIL
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@claffey.cloud}"
fi

echo "------------------------------------------------------------------"
echo "Writing secrets to Vault path: ${VAULT_PATH}..."

# Method 1: Fallback to oc exec if cluster-authenticated
if command -v oc >/dev/null 2>&1 && oc whoami >/dev/null 2>&1; then
  echo "Using 'oc exec' into Vault pod (vault-0)..."
  
  # Try reading root token from vault-unseal-keys secret if VAULT_TOKEN not set
  VAULT_TOKEN="${VAULT_TOKEN:-}"
  if [ -z "${VAULT_TOKEN}" ]; then
    VAULT_TOKEN=$(oc get secret -n vault vault-unseal-keys -o jsonpath='{.data.VAULT_DEV_ROOT_TOKEN_ID}' 2>/dev/null | base64 -d 2>/dev/null || true)
  fi
  if [ -z "${VAULT_TOKEN}" ]; then
    VAULT_TOKEN=$(oc get secret -n vault vault-unseal-keys -o jsonpath='{.data.vault-root-token}' 2>/dev/null | base64 -d 2>/dev/null || true)
  fi

  if [ -n "${VAULT_TOKEN}" ]; then
    oc exec -i -n vault vault-0 -c vault -- env VAULT_ADDR="http://127.0.0.1:8200" VAULT_TOKEN="${VAULT_TOKEN}" vault kv put "${VAULT_PATH}" \
      secret-key="${SECRET_KEY}" \
      admin-user="${ADMIN_USER}" \
      admin-password="${ADMIN_PASSWORD}" \
      admin-email="${ADMIN_EMAIL}"
  else
    read -rsp "Enter Vault Token (or Root Token): " VAULT_TOKEN
    echo ""
    oc exec -i -n vault vault-0 -c vault -- env VAULT_ADDR="http://127.0.0.1:8200" VAULT_TOKEN="${VAULT_TOKEN}" vault kv put "${VAULT_PATH}" \
      secret-key="${SECRET_KEY}" \
      admin-user="${ADMIN_USER}" \
      admin-password="${ADMIN_PASSWORD}" \
      admin-email="${ADMIN_EMAIL}"
  fi

# Method 2: Use vault CLI if logged in locally
elif command -v vault >/dev/null 2>&1 && vault token lookup >/dev/null 2>&1; then
  echo "Using local 'vault' CLI against ${VAULT_ADDR}..."
  vault kv put "${VAULT_PATH}" \
    secret-key="${SECRET_KEY}" \
    admin-user="${ADMIN_USER}" \
    admin-password="${ADMIN_PASSWORD}" \
    admin-email="${ADMIN_EMAIL}"

# Method 3: Instruct user how to authenticate
else
  echo ""
  echo "⚠️  Neither 'oc' CLI nor 'vault' CLI is currently authenticated."
  echo "Please authenticate using one of the following:"
  echo ""
  echo "Option A: OpenShift CLI"
  echo "  oc login https://api.okd.claffey.cloud:6443"
  echo "  ./scripts/setup-vault-paperless-ngx.sh"
  echo ""
  echo "Option B: Vault CLI"
  echo "  export VAULT_ADDR='https://vault.apps.okd.claffey.cloud'"
  echo "  vault login"
  echo "  ./scripts/setup-vault-paperless-ngx.sh"
  exit 1
fi

echo ""
echo "✅ Vault secrets for paperless-ngx successfully configured!"
echo "ArgoCD / ExternalSecrets operator will now be able to resolve all keys."
