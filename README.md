# Building a PDF from `main.tex`

The project is built with XeLaTeX because `main.tex` uses the `fontspec` package and the system fonts Times New Roman, Arial, and Courier New. Building with `pdflatex` will fail with the error `fontspec requires either XeTeX or LuaTeX`.

The finished document after building is located in the project root:

```bash
main.pdf
```

All auxiliary build files are placed in the folder:

```bash
artefacts/
```

## Quick Start

From the project root, run:

```bash
chmod +x ./build.sh
./build.sh
```

The script performs the following actions:

1. checks that `main.tex`, `latexmk`, and `xelatex` are available;
2. builds the document using `latexmk -xelatex`;
3. leaves the final `main.pdf` in the project root;
4. moves `.aux`, `.log`, `.out`, `.toc`, `.fls`, `.fdb_latexmk`, `.xdv`, `.synctex.gz`, and other auxiliary files to `artefacts/`;
5. checks that `main.pdf` exists, is not empty, and has a non-zero number of pages, if `pdfinfo` is installed.

## macOS

### Option 1: Full MacTeX

This is the simplest and most reliable option.

```bash
brew install --cask mactex-no-gui
brew install poppler
```

After installation, restart the terminal or add TeX Live to `PATH`:

```bash
export PATH="/Library/TeX/texbin:$PATH"
```

Check the tools:

```bash
which xelatex
which latexmk
which pdfinfo
```

If `pdfinfo` is not installed, the build will still work, but the script will only be able to check the file size and PDF header. Install `poppler` for full page-count verification.

### Option 2: BasicTeX

BasicTeX takes up less space but may require manual package installation:

```bash
brew install --cask basictex
brew install poppler
```

Add TeX Live to `PATH`:

```bash
export PATH="/Library/TeX/texbin:$PATH"
```

Update `tlmgr` and install the common packages:

```bash
sudo tlmgr update --self
sudo tlmgr install latexmk collection-latexrecommended collection-latexextra collection-fontsrecommended collection-langcyrillic
```

If an error like `File ... not found` appears during the build, install the missing package with:

```bash
sudo tlmgr install <package-name>
```

### Fonts on macOS

Arial and Courier New are usually available in the system. Times New Roman is often installed together with macOS or Microsoft Office. You can check font availability through Font Book.

If XeLaTeX reports that `Times New Roman` cannot be found, install Microsoft Office fonts or replace the fonts in the `main.tex` preamble with available system alternatives.

## Linux

### Ubuntu / Debian

Install TeX Live, XeLaTeX, latexmk, Russian language support, and the PDF verification utility:

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

For the system fonts Times New Roman, Arial, and Courier New, you need the Microsoft Core Fonts package. On Ubuntu, the `multiverse` repository may be required:

```bash
sudo add-apt-repository multiverse
sudo apt update
sudo apt install -y ttf-mscorefonts-installer
```

During installation, you need to accept the Microsoft fonts EULA.

Check that the fonts are visible to the system:

```bash
fc-match "Times New Roman"
fc-match "Arial"
fc-match "Courier New"
```

If the `ttf-mscorefonts-installer` package is unavailable, install the fonts manually or temporarily replace them in `main.tex` with available alternatives, such as Liberation or Nimbus. For the final thesis, it is better to use the required fonts if they are specified in the formatting guidelines.

### Fedora

Basic installation:

```bash
sudo dnf install -y \
  latexmk \
  texlive-xetex \
  texlive-collection-latexrecommended \
  texlive-collection-latexextra \
  texlive-collection-fontsrecommended \
  texlive-babel-russian \
  poppler-utils \
  fontconfig
```

Microsoft Core Fonts on Fedora are usually installed separately and are not available from the main repository. After installing the fonts, check:

```bash
fc-match "Times New Roman"
fc-match "Arial"
fc-match "Courier New"
```

## Manual Build Without the Script

Manual command equivalent to the main build process:

```bash
latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts main.tex
mv artefacts/main.pdf main.pdf
```

On macOS, if there are locale issues, use:

```bash
env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts main.tex
mv artefacts/main.pdf main.pdf
```

On Linux, `C.UTF-8` is usually suitable:

```bash
env LANG=C.UTF-8 LC_ALL=C.UTF-8 latexmk -xelatex -synctex=1 -interaction=nonstopmode -file-line-error -outdir=artefacts main.tex
mv artefacts/main.pdf main.pdf
```

## VS Code / LaTeX Workshop

The project contains `.vscode/settings.json`, where the selected recipe is:

```text
latexmk (xelatex)
```

If the extension still runs `pdflatex`, choose the command:

```text
LaTeX Workshop: Build with recipe
```

and select:

```text
latexmk (xelatex)
```

## Common Errors

### `fontspec requires either XeTeX or LuaTeX`

Cause: the build was started with `pdflatex`.

Solution: use `./build.sh`, `latexmk -xelatex`, or the `latexmk (xelatex)` recipe in LaTeX Workshop.

### `The font "Times New Roman" cannot be found`

Cause: Times New Roman is not installed in the system.

Solution: install Microsoft Core Fonts or check font availability using `fc-match` on Linux and Font Book on macOS.

### `latexmk` fails on `C.UTF-8` in macOS

Cause: macOS does not always support the `C.UTF-8` locale.

Solution: use `en_US.UTF-8`. The `build.sh` script does this automatically on macOS.

### The PDF was built, but `.aux`, `.log`, `.xdv` appeared in the root folder

Run:

```bash
./build.sh
```

The script will move auxiliary files to `artefacts/` and leave only `main.tex`, project source files, and the final `main.pdf` in the root folder.
