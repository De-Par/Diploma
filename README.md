# Bachelor's Thesis

This repository contains the LaTeX source code and the final PDF version of the bachelor's thesis:

> **“Optimization of Cloud Video Streaming Quality Under Limited Computational Resources Using Classical Heuristic Methods and Machine Learning Approaches”**

The thesis studies an ROI-aware approach to improving perceived video streaming quality. The central idea is to detect visually important regions in video frames and expose them to a downstream encoder-side policy, so that quality can be redistributed toward text, faces, and textured regions.

## Practical Basis

The thesis is based on two engineering projects:

- [IDet](https://github.com/De-Par/IDet) — a CPU-first C++ ROI detection library built on top of ONNX Runtime.
- [yolo-training-pipeline](https://github.com/De-Par/yolo-training-pipeline) — a pipeline for dataset preparation, YOLO training, metric analysis, ONNX export, and model optimization.

The thesis explicitly separates:

- the implemented public IDet contract: `VecQuad`;
- implemented text/face ROI modes and the prepared textured ROI detector;
- the downstream contract with ROI type, priority, and `qoffset`;
- the methodology for future baseline vs ROI-aware encoded stream evaluation.

The final quantitative evaluation of encoded video quality with and without ROI is intentionally left as a methodology section without fabricated numbers.

## Repository Layout

```text
.
├── main.tex                  # main LaTeX source
├── main.pdf                  # compiled thesis PDF
├── build.sh                  # reproducible XeLaTeX/latexmk build script
├── figures/                  # figures, diagrams, and plots used by the thesis
│   ├── appendix/
│   ├── architecture/
│   ├── datasets/
│   ├── performance/
│   ├── profiling/
│   ├── video-quality/
│   └── yolo/
├── .latexmkrc
└── .gitignore
```

The local `data/` directory with raw experimental materials is not part of the public repository. The repository includes only the derived figures and tables required to build the current thesis version.

## Thesis Structure

1. Introduction and problem statement.
2. Cloud video streaming and ROI-aware video coding.
3. Formal ROI-aware quality optimization.
4. IDet architecture and the three-mode ROI pipeline.
5. Textured ROI detector training with YOLO.
6. ONNX / ONNX Runtime deployment and quantization.
7. Experimental methodology.
8. YOLO model results and confusion matrix analysis.
9. Text/face/textured ROI benchmarks, profiling, I/O Binding, NUMA, and Top-Down Microarchitecture Analysis.
10. Methodology for baseline vs ROI-aware encoded stream comparison.
11. Engineering limitations, risks, and conclusion.

## Building the PDF

The document must be built with XeLaTeX because `main.tex` uses `fontspec` and the system fonts Times New Roman, Arial, and Courier New. Building with `pdflatex` is not supported.

Quick start:

```bash
chmod +x ./build.sh
./build.sh
```

After a successful build, the final PDF is placed in the repository root:

```text
main.pdf
```

Auxiliary LaTeX files are placed in `artefacts/`. This directory is ignored by Git.

## Dependencies

Required tools:

- `xelatex`;
- `latexmk`;
- TeX Live packages for standard LaTeX, Cyrillic support, tables, graphics, and `fontspec`;
- Times New Roman, Arial, and Courier New system fonts;
- `pdfinfo` from `poppler` is recommended for page-count validation in `build.sh`.

### macOS

```bash
brew install --cask mactex-no-gui
brew install poppler
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

Equivalent manual build command:

```bash
mkdir -p artefacts
latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts main.tex
mv artefacts/main.pdf main.pdf
```

On macOS, if locale issues occur:

```bash
env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts main.tex
```

On Linux, `C.UTF-8` is usually suitable:

```bash
env LANG=C.UTF-8 LC_ALL=C.UTF-8 latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts main.tex
```

## Publication Status

This repository is prepared as a public thesis repository:

- `main.tex` and `figures/` are sufficient to rebuild the document;
- `main.pdf` is included as the compiled result;
- local experimental data, editor settings, and LaTeX build artifacts are excluded from Git;
- experimental claims in the thesis are based on available summary data, training reports, benchmark tables, and profiling artifacts;
- the baseline vs ROI-aware video quality section is written as a methodology section without unsupported numerical claims.

## Authorship and Usage

The thesis text, figures, and compiled PDF are published as educational and research material. All rights to the text and formatting are reserved by the author.
