#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_NAME="diploma"
TEX_FILE="${DOC_NAME}.tex"
PDF_FILE="${DOC_NAME}.pdf"
COMPRESSED_PDF_FILE="${DOC_NAME}_compressed.pdf"
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
  -g \
  -synctex=1 \
  -interaction=nonstopmode \
  -file-line-error \
  -outdir="${ARTEFACTS_DIR}" \
  "${TEX_FILE}"

if [[ ! -s "${ARTEFACTS_DIR}/${PDF_FILE}" ]]; then
  echo "ERROR: ${ARTEFACTS_DIR}/${PDF_FILE} was not produced." >&2
  exit 1
fi

cp -f "${ARTEFACTS_DIR}/${PDF_FILE}" "${ROOT_DIR}/${PDF_FILE}"

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

if [[ "${COMPRESS_PDF:-1}" == "1" ]]; then
  if command -v gs >/dev/null 2>&1; then
    compressed_tmp="${ARTEFACTS_DIR}/${COMPRESSED_PDF_FILE}.tmp"
    compressed_out="${ROOT_DIR}/${COMPRESSED_PDF_FILE}"
    rm -f "${compressed_tmp}"

    gs \
      -sDEVICE=pdfwrite \
      -dCompatibilityLevel=1.5 \
      -dNOPAUSE \
      -dQUIET \
      -dBATCH \
      -dDetectDuplicateImages=true \
      -dCompressFonts=true \
      -dSubsetFonts=true \
      -dDownsampleColorImages=false \
      -dDownsampleGrayImages=false \
      -dDownsampleMonoImages=false \
      -sOutputFile="${compressed_tmp}" \
      "${ROOT_DIR}/${PDF_FILE}"

    if [[ ! -s "${compressed_tmp}" ]]; then
      echo "ERROR: Ghostscript did not produce ${COMPRESSED_PDF_FILE}." >&2
      exit 1
    fi

    if command -v pdfinfo >/dev/null 2>&1; then
      compressed_pages="$(pdfinfo "${compressed_tmp}" | awk '/^Pages:/ {print $2}')"
      if [[ "${compressed_pages}" != "${pages:-}" ]]; then
        echo "ERROR: compressed PDF page count (${compressed_pages:-unknown}) differs from ${PDF_FILE} (${pages:-unknown})." >&2
        exit 1
      fi
    elif [[ "$(head -c 5 "${compressed_tmp}")" != "%PDF-" ]]; then
      echo "ERROR: ${COMPRESSED_PDF_FILE} does not look like a PDF file." >&2
      exit 1
    fi

    mv -f "${compressed_tmp}" "${compressed_out}"
    compressed_size="$(wc -c < "${compressed_out}" | tr -d '[:space:]')"
    echo "OK: compressed ${COMPRESSED_PDF_FILE} (${compressed_size} bytes)."
  else
    echo "WARN: Ghostscript is not installed; skipping ${COMPRESSED_PDF_FILE}."
    echo "      Install 'ghostscript' on Linux or 'brew install ghostscript' on macOS."
  fi
else
  echo "Skipping PDF compression because COMPRESS_PDF=${COMPRESS_PDF}."
fi
