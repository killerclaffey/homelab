#!/usr/bin/env bash
# ==============================================================================
# Script: setup-vault-cnpg-minio.sh
# Purpose: Create the MinIO `cnpg-backups` bucket + least-privilege IAM user on
#          external TrueNAS MinIO (https://minio.claffey.cloud:9000) and seed
#          HashiCorp Vault with the S3 credentials consumed by CNPG ExternalSecrets.
# Vault Path: secret/homelab/cnpg/minio (KV v2)
# Keys:       access-key-id, secret-access-key
# Usage:
#   ./scripts/setup-vault-cnpg-minio.sh              # Full MinIO + Vault setup
#   ./scripts/setup-vault-cnpg-minio.sh --vault-only # Only write existing keys to Vault
# ==============================================================================

set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-https://vault.apps.okd.claffey.cloud}"
VAULT_PATH="${VAULT_PATH:-secret/homelab/cnpg/minio}"
MINIO_ENDPOINT="${MINIO_ENDPOINT:-https://minio.claffey.cloud:9000}"
MINIO_BUCKET="${MINIO_BUCKET:-cnpg-backups}"
MINIO_POLICY_NAME="${MINIO_POLICY_NAME:-cnpg-backups-rw}"
MINIO_IAM_USER="${MINIO_IAM_USER:-cnpg-backups}"
MC_IMAGE="${MC_IMAGE:-quay.io/minio/mc:RELEASE.2025-08-13T08-35-41Z}"

VAULT_ONLY=false
if [ "${1:-}" = "--vault-only" ]; then
  VAULT_ONLY=true
fi

TMPDIR_WORK="$(mktemp -d)"
chmod 700 "${TMPDIR_WORK}"
trap 'rm -rf "${TMPDIR_WORK}"' EXIT

generate_secret() {
  local length="${1:-40}"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c "${length}"
  else
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${length}"
  fi
}

run_mc() {
  local env_file="$1"
  shift
  if command -v mc >/dev/null 2>&1; then
    (
      set -a
      # shellcheck disable=SC1090
      . "${env_file}"
      set +a
      mc "$@"
    )
  elif command -v podman >/dev/null 2>&1; then
    podman run --rm --env-file "${env_file}" -v "${TMPDIR_WORK}:/work:ro,Z" "${MC_IMAGE}" "$@"
  else
    echo "Error: neither 'mc' nor 'podman' is installed." >&2
    exit 1
  fi
}

echo "=================================================================="
echo "     CNPG External MinIO Bucket & Vault Secrets Seeding Helper    "
echo "=================================================================="
echo "MinIO Endpoint : ${MINIO_ENDPOINT}"
echo "MinIO Bucket   : ${MINIO_BUCKET}"
echo "MinIO IAM User : ${MINIO_IAM_USER}"
echo "Vault Path     : ${VAULT_PATH}"
echo "------------------------------------------------------------------"

ACCESS_KEY_ID="${ACCESS_KEY_ID:-}"
SECRET_ACCESS_KEY="${SECRET_ACCESS_KEY:-}"

if [ "${VAULT_ONLY}" = false ]; then
  MINIO_ROOT_USER="${MINIO_ROOT_USER:-}"
  if [ -z "${MINIO_ROOT_USER}" ]; then
    read -rp "Enter MinIO Admin Username: " MINIO_ROOT_USER
  fi
  MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-}"
  if [ -z "${MINIO_ROOT_PASSWORD}" ]; then
    read -rsp "Enter MinIO Admin Password: " MINIO_ROOT_PASSWORD
    echo ""
  fi

  if [ -z "${ACCESS_KEY_ID}" ]; then
    ACCESS_KEY_ID="${MINIO_IAM_USER}"
  fi
  if [ -z "${SECRET_ACCESS_KEY}" ]; then
    SECRET_ACCESS_KEY="$(generate_secret 40)"
  fi

  # URL-encode admin credentials safely in Python without leaking to argv/ps
  ADMIN_ENV_FILE="${TMPDIR_WORK}/admin.env"
  (
    umask 077
    MINIO_U="${MINIO_ROOT_USER}" MINIO_P="${MINIO_ROOT_PASSWORD}" MINIO_EP="${MINIO_ENDPOINT}" \
      python3 -c '
import os, urllib.parse
ep = os.environ["MINIO_EP"]
scheme, rest = ep.split("://", 1)
u = urllib.parse.quote(os.environ["MINIO_U"], safe="")
p = urllib.parse.quote(os.environ["MINIO_P"], safe="")
print(f"MC_HOST_nas={scheme}://{u}:{p}@{rest}")
' > "${ADMIN_ENV_FILE}"
  )

  POLICY_FILE="${TMPDIR_WORK}/policy.json"
  cat > "${POLICY_FILE}" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": [
        "arn:aws:s3:::${MINIO_BUCKET}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListMultipartUploadParts",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${MINIO_BUCKET}/*"
      ]
    }
  ]
}
EOF

  POLICY_ARG="${POLICY_FILE}"
  if ! command -v mc >/dev/null 2>&1; then
    POLICY_ARG="/work/policy.json"
  fi

  echo "1. Ensuring MinIO bucket '${MINIO_BUCKET}' exists..."
  run_mc "${ADMIN_ENV_FILE}" mb --ignore-existing "nas/${MINIO_BUCKET}"

  echo "2. Creating/updating least-privilege IAM policy '${MINIO_POLICY_NAME}'..."
  run_mc "${ADMIN_ENV_FILE}" admin policy create nas "${MINIO_POLICY_NAME}" "${POLICY_ARG}"

  echo "3. Creating/updating IAM user '${ACCESS_KEY_ID}'..."
  run_mc "${ADMIN_ENV_FILE}" admin user add nas "${ACCESS_KEY_ID}" "${SECRET_ACCESS_KEY}"

  echo "4. Attaching policy '${MINIO_POLICY_NAME}' to user '${ACCESS_KEY_ID}'..."
  run_mc "${ADMIN_ENV_FILE}" admin policy attach nas "${MINIO_POLICY_NAME}" --user "${ACCESS_KEY_ID}" || true

  echo "5. Verifying S3 access with the new least-privilege credentials..."
  USER_ENV_FILE="${TMPDIR_WORK}/user.env"
  (
    umask 077
    MINIO_U="${ACCESS_KEY_ID}" MINIO_P="${SECRET_ACCESS_KEY}" MINIO_EP="${MINIO_ENDPOINT}" \
      python3 -c '
import os, urllib.parse
ep = os.environ["MINIO_EP"]
scheme, rest = ep.split("://", 1)
u = urllib.parse.quote(os.environ["MINIO_U"], safe="")
p = urllib.parse.quote(os.environ["MINIO_P"], safe="")
print(f"MC_HOST_cnpg={scheme}://{u}:{p}@{rest}")
' > "${USER_ENV_FILE}"
  )
  run_mc "${USER_ENV_FILE}" ls "cnpg/${MINIO_BUCKET}" >/dev/null
  echo "✅ MinIO bucket & least-privilege credentials verified!"
else
  if [ -z "${ACCESS_KEY_ID}" ]; then
    read -rp "Enter MinIO Access Key ID [${MINIO_IAM_USER}]: " INPUT_AK
    ACCESS_KEY_ID="${INPUT_AK:-${MINIO_IAM_USER}}"
  fi
  if [ -z "${SECRET_ACCESS_KEY}" ]; then
    read -rsp "Enter MinIO Secret Access Key: " SECRET_ACCESS_KEY
    echo ""
  fi
fi

# Build JSON payload for stdin-only Vault write (never exposes secrets in CLI argv)
PAYLOAD_FILE="${TMPDIR_WORK}/vault-payload.json"
(
  umask 077
  AK="${ACCESS_KEY_ID}" SK="${SECRET_ACCESS_KEY}" python3 -c '
import json, os
print(json.dumps({"access-key-id": os.environ["AK"], "secret-access-key": os.environ["SK"]}))
' > "${PAYLOAD_FILE}"
)

echo "------------------------------------------------------------------"
echo "6. Writing credentials to Vault path: ${VAULT_PATH}..."

if command -v oc >/dev/null 2>&1 && oc whoami >/dev/null 2>&1; then
  echo "Using 'oc exec' into Vault pod (vault-0)..."
  VAULT_TOKEN="${VAULT_TOKEN:-}"
  if [ -z "${VAULT_TOKEN}" ]; then
    VAULT_TOKEN="$(oc get secret -n vault vault-unseal-keys -o jsonpath='{.data.VAULT_DEV_ROOT_TOKEN_ID}' 2>/dev/null | base64 -d 2>/dev/null || true)"
  fi
  if [ -z "${VAULT_TOKEN}" ]; then
    VAULT_TOKEN="$(oc get secret -n vault vault-unseal-keys -o jsonpath='{.data.vault-root-token}' 2>/dev/null | base64 -d 2>/dev/null || true)"
  fi
  if [ -z "${VAULT_TOKEN}" ]; then
    read -rsp "Enter Vault Token (or Root Token): " VAULT_TOKEN
    echo ""
  fi

  oc exec -i -n vault vault-0 -c vault -- env VAULT_ADDR="http://127.0.0.1:8200" VAULT_TOKEN="${VAULT_TOKEN}" \
    vault kv put "${VAULT_PATH}" - < "${PAYLOAD_FILE}"

elif command -v vault >/dev/null 2>&1 && vault token lookup >/dev/null 2>&1; then
  echo "Using local 'vault' CLI against ${VAULT_ADDR}..."
  vault kv put "${VAULT_PATH}" - < "${PAYLOAD_FILE}"

else
  echo "Error: neither 'oc' nor 'vault' is authenticated." >&2
  echo "Run 'oc login' or 'vault login' and re-run with --vault-only." >&2
  exit 1
fi

echo ""
echo "✅ Done! MinIO bucket '${MINIO_BUCKET}' and Vault secret '${VAULT_PATH}' are ready."
echo "ExternalSecrets in 'bikely-dev' and 'bikely' can now sync 'cnpg-minio-credentials'."
