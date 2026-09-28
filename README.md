# HORUS NLP Dataset

This repository prepares the HORUS Bogotá Ingeniería bibliography dataset for natural language processing experiments on paper similarity and explicit scholarly connections.

## Repository structure

- `data/raw/`: original dataset.
- `data/cleaned/`: normalized data and quality reports.
- `notebooks/`: Google Colab notebook.
- `scripts/`: reproducible dataset preparation code.

## Generate the cleaned dataset

```bash
python scripts/build_clean_dataset.py
```

## Run in Google Colab

Open `notebooks/horus_paper_similarity_and_connections.ipynb` in Google Colab and execute the cells in order. The notebook clones this repository and uses the raw dataset stored in `data/raw/`.
