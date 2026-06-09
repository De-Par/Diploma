# Bachelor's Thesis

This repository contains the LaTeX sources, figures, HSE Beamer theme assets, and publication-ready PDFs for the bachelor's thesis:

> **“Optimization of Cloud Video Streaming Quality Under Limited Computational Resources Using Classical Heuristic Methods and Machine Learning Approaches”**

The thesis studies an ROI-aware approach to cloud video streaming quality. The main idea is to detect visually important regions before encoding and pass them to the encoder-side policy, so that quality is redistributed toward text, faces, and textured regions without materially increasing the output size.

## Practical Basis

The thesis is based on two engineering projects:

- [IDet](https://github.com/De-Par/IDet) — a CPU-first C++ ROI detection library built on top of ONNX Runtime.
- [yolo-training-pipeline](https://github.com/De-Par/yolo-training-pipeline) — a pipeline for dataset preparation, YOLO training, metric analysis, ONNX export, and model optimization.

The thesis explicitly separates:

- the implemented public IDet contract: `VecQuad`;
- implemented text/face ROI modes and the prepared textured ROI detector;
- the downstream contract with ROI type, priority, area budget, and `qoffset`;
- the frame-level baseline vs ROI-aware HEVC evaluation and the limits of extending it to full video.

## Repository Layout

```text
.
├── diploma.tex               # main LaTeX source
├── presentation.tex          # 8-minute defense presentation source
├── build.sh                  # reproducible XeLaTeX/latexmk build script
├── docs/                     # publication-ready PDFs, committed to Git
├── artefacts/                # ignored LaTeX auxiliary files and temporary PDFs
├── hse-theme/                # official HSE Beamer theme files with normalized names
├── figures/                  # figures, diagrams, and plots used by the thesis
├── .latexmkrc
└── .gitignore
```

The local `data/` directory with raw experimental materials is not part of the public repository. The repository includes only the derived figures and tables required to build the current thesis version.

`docs/` is the publishable output directory and is intentionally not ignored. `artefacts/` is ignored and contains only LaTeX build products, temporary Ghostscript outputs, logs, and intermediate files.

## Defense Presentation

`presentation.tex` uses the official HSE Beamer theme from the HSE brandbook page and is structured for an 8-minute student defense:

1. problem;
2. concrete task and constraints;
3. brief review of solution approaches;
4. proposed ROI-aware approach;
5. experimental results and limitations.

The slide deck is intentionally short and concrete: it focuses on the detector-to-encoder path, the YOLO26n deployment choice, the HEVC `match_baseline` experiment, and the measured ROI quality gains.

## Building the PDFs

The documents must be built with XeLaTeX because `diploma.tex` and `presentation.tex` use `fontspec` and system fonts. Building with `pdflatex` is not supported.

Quick start:

```bash
chmod +x ./build.sh
./build.sh
```

Default output:

```text
docs/diploma.pdf
docs/diploma_compressed.pdf
```

Build targets:

```bash
./build.sh                         # docs/diploma.pdf + docs/diploma_compressed.pdf
./build.sh diploma-pdf             # docs/diploma.pdf only
./build.sh diploma-compressed      # docs/diploma.pdf + docs/diploma_compressed.pdf
./build.sh presentation            # docs/presentation.pdf
./build.sh presentation-compressed # docs/presentation.pdf + docs/presentation_compressed.pdf
./build.sh all                     # diploma with compression + docs/presentation.pdf
./build.sh all-compressed          # diploma and presentation, both with compressed copies
```

If Ghostscript is unavailable, compressed targets still build the regular PDF and print a warning. Disable compression explicitly with:

```bash
COMPRESS_PDF=0 ./build.sh
```

## Dependencies

Required tools:

- `xelatex`;
- `latexmk`;
- TeX Live packages for standard LaTeX, Cyrillic support, tables, graphics, and `fontspec`;
- Times New Roman, Arial, and Courier New system fonts;
- HSE Sans is recommended for `presentation.tex`; the source falls back to Arial when it is not installed;
- `pdfinfo` from `poppler` is recommended for page-count validation in `build.sh`;
- `ghostscript` is optional and is used for compressed PDFs.

### macOS

```bash
brew install --cask mactex-no-gui
brew install poppler ghostscript
```

If TeX Live is not visible in `PATH`:

```bash
export PATH="/Library/TeX/texbin:$PATH"
```

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y \
  latexmk \
  texlive-xetex \
  texlive-lang-cyrillic \
  texlive-latex-recommended \
  texlive-latex-extra \
  texlive-fonts-recommended \
  poppler-utils \
  ghostscript \
  fontconfig
```

For Times New Roman, Arial, and Courier New:

```bash
sudo apt install -y ttf-mscorefonts-installer
```

Font check:

```bash
fc-match "Times New Roman"
fc-match "Arial"
fc-match "Courier New"
```

## Manual Build

Equivalent manual build command for the thesis:

```bash
mkdir -p artefacts docs
latexmk -xelatex -g -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts diploma.tex
cp artefacts/diploma.pdf docs/diploma.pdf
```

Equivalent manual build command for the defense presentation:

```bash
mkdir -p artefacts docs
latexmk -xelatex -g -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts presentation.tex
cp artefacts/presentation.pdf docs/presentation.pdf
```

Optional Ghostscript compression, matching `build.sh`:

```bash
gs -sDEVICE=pdfwrite \
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
  -sOutputFile=docs/diploma_compressed.pdf \
  docs/diploma.pdf
```

On macOS, if locale issues occur:

```bash
env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts diploma.tex
```

On Linux, `C.UTF-8` is usually suitable:

```bash
env LANG=C.UTF-8 LC_ALL=C.UTF-8 latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts diploma.tex
```

## Publication Status

This repository is prepared as a public thesis repository:

- `diploma.tex`, `presentation.tex`, `hse-theme/`, and `figures/` are sufficient to rebuild the documents;
- ready PDFs are committed under `docs/`;
- local experimental data, editor settings, and LaTeX build artefacts are excluded from Git;
- experimental claims in the thesis are based on available summary data, training reports, benchmark tables, profiling artifacts, and the frame-level ROI-aware encoding experiment;
- the baseline vs ROI-aware video quality section reports frame-level results and explicitly limits the conclusion to that setting.

## Authorship and Usage

The thesis text, figures, presentation, and compiled PDFs are published as educational and research material. All rights to the text and formatting are reserved by the author.
