#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env"
TARGET_DIR="."

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ .env file not found!"
  exit 1
fi

# Ensure LF line endings
sed -i 's/\r$//' "$ENV_FILE"

# Load .env safely into associative array
declare -A ENV_VARS
while IFS="=" read -r key value; do
  value="${value%\"}"
  value="${value#\"}"
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  ENV_VARS["$key"]="$value"
done < "$ENV_FILE"

# Define placeholders
declare -a PLACEHOLDERS=("CLOUDFLARESECRET" "DOMAINNAME" "GITREPO" "HOSTIP" "CILIUMLBCIDR")

echo "🔄 Restoring placeholders in repo..."

for PH in "${PLACEHOLDERS[@]}"; do
  VALUE="${ENV_VARS[$PH]-}"  # Use default empty string if not set
  if [[ -z "$VALUE" ]]; then
    echo "⚠️  Placeholder $PH not found in .env, skipping..."
    continue
  fi

  echo "  → $VALUE → $PH"

  # Find all files except shell scripts, .env, and ignored directories
  find "$TARGET_DIR" -type f \
    ! -name "*.sh" \
    ! -name ".env" \
    ! -path "*/.git/*" \
    ! -path "*/.terraform/*" \
    ! -path "*/node_modules/*" \
    -print0 | while IFS= read -r -d '' file; do
        sed -i "s|$VALUE|$PH|g" "$file"
      done
done

echo "✅ Placeholders restored successfully!"