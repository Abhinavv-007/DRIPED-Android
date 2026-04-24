#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="$ROOT_DIR/android/app/src/main/assets/models"
DEST_FILE="$DEST_DIR/local_mail_extractor.litertlm"
MODEL_URL="${MODEL_URL:-https://huggingface.co/litert-community/functiongemma-mobile-actions_q8_ekv1024.litertlm/resolve/main/mobile-actions_q8_ekv1024.litertlm}"

mkdir -p "$DEST_DIR"

curl_args=(-fL --retry 3 --retry-delay 2)
if [[ -n "${HF_TOKEN:-}" ]]; then
  curl_args+=(-H "Authorization: Bearer ${HF_TOKEN}")
fi

tmp_file="${DEST_FILE}.tmp"
echo "Downloading offline AI model to: $DEST_FILE"
curl "${curl_args[@]}" "$MODEL_URL" -o "$tmp_file"

if [[ -n "${LOCAL_AI_MODEL_SHA256:-}" ]]; then
  actual="$(shasum -a 256 "$tmp_file" | awk '{print $1}')"
  if [[ "$actual" != "$LOCAL_AI_MODEL_SHA256" ]]; then
    rm -f "$tmp_file"
    echo "Checksum mismatch."
    echo "Expected: $LOCAL_AI_MODEL_SHA256"
    echo "Actual:   $actual"
    exit 1
  fi
fi

mv "$tmp_file" "$DEST_FILE"
echo "Model ready."
