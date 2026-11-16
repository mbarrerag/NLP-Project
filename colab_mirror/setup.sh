#!/usr/bin/env bash
# Crea un entorno espejo del runtime de Colab y lo registra como kernel de Jupyter
# ("Python 3.13 (Colab mirror)"), para correr notebooks/NPL_Proyecto.ipynb en local con las mismas versiones.
# Requiere uv (https://docs.astral.sh/uv/). Para actualizar las versiones de Colab, volver a descargar
# colab-constraints.txt desde https://github.com/googlecolab/backend-info (pip-freeze.txt, solo líneas "paquete==versión").
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ENV_DIR="${ENV_DIR:-$HOME/.venvs/nlp-colab-mirror}"

uv venv --python 3.13 "$ENV_DIR"
VIRTUAL_ENV="$ENV_DIR" uv pip install -r "$HERE/requirements.txt" -c "$HERE/colab-constraints.txt"
VIRTUAL_ENV="$ENV_DIR" uv pip install pip \
  "en_core_web_sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
"$ENV_DIR/bin/python" -m ipykernel install --user --name nlp-colab-mirror --display-name "Python 3.13 (Colab mirror)"
