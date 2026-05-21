#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_NAME="main"
TEX_FILE="${DOC_NAME}.tex"
PDF_FILE="${DOC_NAME}.pdf"
ARTEFACTS_DIR="${ROOT_DIR}/artefacts"

cd "${ROOT_DIR}"

if [[ ! -f "${TEX_FILE}" ]]; then
  echo "ERROR: ${TEX_FILE} not found in ${ROOT_DIR}" >&2
  exit 1
fi

if ! command -v latexmk >/dev/null 2>&1; then
  echo "ERROR: latexmk is not installed or is not available in PATH." >&2
  exit 1
fi

if ! command -v xelatex >/dev/null 2>&1; then
  echo "ERROR: xelatex is not installed or is not available in PATH." >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    ;;
  *)
    if locale -a 2>/dev/null | grep -Eiq '^(C|c)\.UTF-?8$'; then
      export LANG="C.UTF-8"
      export LC_ALL="C.UTF-8"
    else
      export LANG="${LANG:-en_US.UTF-8}"
      export LC_ALL="${LC_ALL:-en_US.UTF-8}"
    fi
    ;;
esac

mkdir -p "${ARTEFACTS_DIR}"

latexmk \
  -xelatex \
  -synctex=1 \
  -interaction=nonstopmode \
  -file-line-error \
  -outdir="${ARTEFACTS_DIR}" \
  "${TEX_FILE}"

if [[ ! -s "${ARTEFACTS_DIR}/${PDF_FILE}" ]]; then
  echo "ERROR: ${ARTEFACTS_DIR}/${PDF_FILE} was not produced." >&2
  exit 1
fi

mv -f "${ARTEFACTS_DIR}/${PDF_FILE}" "${ROOT_DIR}/${PDF_FILE}"

shopt -s nullglob
for file in "${ROOT_DIR}/${DOC_NAME}".*; do
  base="$(basename "${file}")"
  case "${base}" in
    "${TEX_FILE}"|"${PDF_FILE}"|"${DOC_NAME}.bib")
      continue
      ;;
  esac
  if [[ -f "${file}" ]]; then
    mv -f "${file}" "${ARTEFACTS_DIR}/${base}"
  fi
done
shopt -u nullglob

if [[ ! -s "${ROOT_DIR}/${PDF_FILE}" ]]; then
  echo "ERROR: ${PDF_FILE} is missing or empty after build." >&2
  exit 1
fi

pdf_size="$(wc -c < "${ROOT_DIR}/${PDF_FILE}" | tr -d '[:space:]')"
if [[ "${pdf_size}" -lt 1024 ]]; then
  echo "ERROR: ${PDF_FILE} is too small (${pdf_size} bytes), likely empty or corrupted." >&2
  exit 1
fi

if command -v pdfinfo >/dev/null 2>&1; then
  pages="$(pdfinfo "${ROOT_DIR}/${PDF_FILE}" | awk '/^Pages:/ {print $2}')"
  if [[ ! "${pages}" =~ ^[0-9]+$ ]] || [[ "${pages}" -le 0 ]]; then
    echo "ERROR: ${PDF_FILE} has invalid page count: ${pages:-unknown}." >&2
    exit 1
  fi
  echo "OK: built ${PDF_FILE} (${pages} pages, ${pdf_size} bytes)."
else
  if [[ "$(head -c 5 "${ROOT_DIR}/${PDF_FILE}")" != "%PDF-" ]]; then
    echo "ERROR: ${PDF_FILE} does not look like a PDF file." >&2
    exit 1
  fi
  echo "OK: built ${PDF_FILE} (${pdf_size} bytes). Install pdfinfo for page-count validation."
fi

echo "Build artefacts are in ${ARTEFACTS_DIR}."
