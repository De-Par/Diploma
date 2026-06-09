#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LATEX_ARTEFACTS_DIR="${ROOT_DIR}/artefacts"
PDF_DIR="${ROOT_DIR}/docs"
TARGET="${1:-diploma}"

cd "${ROOT_DIR}"

usage() {
  cat <<'USAGE'
Usage: ./build.sh [target]

Targets:
  diploma                 Build docs/diploma.pdf and docs/diploma_compressed.pdf (default).
  diploma-pdf             Build docs/diploma.pdf without compression.
  diploma-compressed      Build docs/diploma.pdf and docs/diploma_compressed.pdf.
  presentation            Build docs/presentation.pdf.
  presentation-compressed Build docs/presentation.pdf and docs/presentation_compressed.pdf.
  all                     Build diploma with compression and docs/presentation.pdf.
  all-compressed          Build diploma and presentation, both with compressed copies.
  help                    Show this message.

Set COMPRESS_PDF=0 to skip compression even for compressed targets.
LaTeX auxiliary files are written to artefacts/.
Ready PDFs are written to docs/.
USAGE
}

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

mkdir -p "${LATEX_ARTEFACTS_DIR}" "${PDF_DIR}"

validate_pdf() {
  local pdf_path="$1"
  local pdf_label="$2"
  local pages_var="${3:-}"
  local pdf_size
  local pages

  if [[ ! -s "${pdf_path}" ]]; then
    echo "ERROR: ${pdf_label} is missing or empty." >&2
    exit 1
  fi

  pdf_size="$(wc -c < "${pdf_path}" | tr -d '[:space:]')"
  if [[ "${pdf_size}" -lt 1024 ]]; then
    echo "ERROR: ${pdf_label} is too small (${pdf_size} bytes), likely empty or corrupted." >&2
    exit 1
  fi

  if command -v pdfinfo >/dev/null 2>&1; then
    pages="$(pdfinfo "${pdf_path}" | awk '/^Pages:/ {print $2}')"
    if [[ ! "${pages}" =~ ^[0-9]+$ ]] || [[ "${pages}" -le 0 ]]; then
      echo "ERROR: ${pdf_label} has invalid page count: ${pages:-unknown}." >&2
      exit 1
    fi
    echo "OK: built ${pdf_label} (${pages} pages, ${pdf_size} bytes)."
  else
    if [[ "$(head -c 5 "${pdf_path}")" != "%PDF-" ]]; then
      echo "ERROR: ${pdf_label} does not look like a PDF file." >&2
      exit 1
    fi
    pages=""
    echo "OK: built ${pdf_label} (${pdf_size} bytes). Install pdfinfo for page-count validation."
  fi

  if [[ -n "${pages_var}" ]]; then
    printf -v "${pages_var}" '%s' "${pages}"
  fi
}

compress_pdf() {
  local doc_name="$1"
  local pages="$2"
  local pdf_file="${doc_name}.pdf"
  local compressed_pdf_file="${doc_name}_compressed.pdf"
  local source_pdf="${PDF_DIR}/${pdf_file}"
  local compressed_tmp="${LATEX_ARTEFACTS_DIR}/${compressed_pdf_file}.tmp"
  local compressed_out="${PDF_DIR}/${compressed_pdf_file}"
  local compressed_pages
  local compressed_size

  if [[ "${COMPRESS_PDF:-1}" != "1" ]]; then
    echo "Skipping PDF compression because COMPRESS_PDF=${COMPRESS_PDF}."
    return
  fi

  if ! command -v gs >/dev/null 2>&1; then
    echo "WARN: Ghostscript is not installed; skipping ${compressed_pdf_file}."
    echo "      Install 'ghostscript' on Linux or 'brew install ghostscript' on macOS."
    return
  fi

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
    -sColorConversionStrategy=RGB \
    -dProcessColorModel=/DeviceRGB \
    -dOverrideICC=true \
    -sOutputFile="${compressed_tmp}" \
    "${source_pdf}"

  if [[ ! -s "${compressed_tmp}" ]]; then
    echo "ERROR: Ghostscript did not produce ${compressed_pdf_file}." >&2
    exit 1
  fi

  if command -v pdfinfo >/dev/null 2>&1; then
    compressed_pages="$(pdfinfo "${compressed_tmp}" | awk '/^Pages:/ {print $2}')"
    if [[ -n "${pages}" && "${compressed_pages}" != "${pages}" ]]; then
      echo "ERROR: compressed PDF page count (${compressed_pages:-unknown}) differs from ${pdf_file} (${pages})." >&2
      exit 1
    fi
  elif [[ "$(head -c 5 "${compressed_tmp}")" != "%PDF-" ]]; then
    echo "ERROR: ${compressed_pdf_file} does not look like a PDF file." >&2
    exit 1
  fi

  mv -f "${compressed_tmp}" "${compressed_out}"
  compressed_size="$(wc -c < "${compressed_out}" | tr -d '[:space:]')"
  echo "OK: compressed ${compressed_pdf_file} (${compressed_size} bytes)."
}

build_doc() {
  local doc_name="$1"
  local with_compression="$2"
  local tex_file="${doc_name}.tex"
  local pdf_file="${doc_name}.pdf"
  local artefact_pdf="${LATEX_ARTEFACTS_DIR}/${pdf_file}"
  local published_pdf="${PDF_DIR}/${pdf_file}"
  local pages=""

  if [[ ! -f "${tex_file}" ]]; then
    echo "ERROR: ${tex_file} not found in ${ROOT_DIR}" >&2
    exit 1
  fi

  latexmk \
    -xelatex \
    -g \
    -synctex=1 \
    -interaction=nonstopmode \
    -file-line-error \
    -outdir="${LATEX_ARTEFACTS_DIR}" \
    "${tex_file}"

  if [[ ! -s "${artefact_pdf}" ]]; then
    echo "ERROR: ${artefact_pdf} was not produced." >&2
    exit 1
  fi

  cp -f "${artefact_pdf}" "${published_pdf}"
  validate_pdf "${published_pdf}" "${pdf_file}" pages

  if [[ "${with_compression}" == "1" ]]; then
    compress_pdf "${doc_name}" "${pages}"
  fi
}

case "${TARGET}" in
  diploma|default)
    build_doc "diploma" "1"
    ;;
  diploma-pdf)
    build_doc "diploma" "0"
    ;;
  diploma-compressed|compressed)
    build_doc "diploma" "1"
    ;;
  presentation)
    build_doc "presentation" "0"
    ;;
  presentation-compressed)
    build_doc "presentation" "1"
    ;;
  all)
    build_doc "diploma" "1"
    build_doc "presentation" "0"
    ;;
  all-compressed)
    build_doc "diploma" "1"
    build_doc "presentation" "1"
    ;;
  help|-h|--help)
    usage
    exit 0
    ;;
  *)
    echo "ERROR: unknown target '${TARGET}'." >&2
    usage >&2
    exit 1
    ;;
esac

echo "Ready PDFs are in ${PDF_DIR}."
echo "LaTeX artefacts are in ${LATEX_ARTEFACTS_DIR}."
