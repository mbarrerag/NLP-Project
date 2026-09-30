# AGENTS.md

Guía para agentes (y personas) que trabajen en este repositorio.

## De qué trata el proyecto

Proyecto académico de NLP (Universidad Nacional de Colombia): **"Similitudes y Conexiones entre Papers"**.
El objetivo es preparar la bibliografía de **HORUS Bogotá – Facultad de Ingeniería** para experimentos de:

1. **Similitud entre papers** (p. ej. TF-IDF sobre título + abstract; `SIMILARITY_METHOD = 'tfidf'`).
2. **Conexiones explícitas** entre papers (relaciones tipo grafo, pensadas para RAG/KAG).

Estado actual: la limpieza/normalización y el etiquetado por reglas están implementados. El cálculo de
similitudes y relaciones **todavía es un placeholder** (se exportan DataFrames vacíos).

Autores: Angel David Pineros Sierra, Miller Estiven Barrera Gonzalez, Juan David Rodriguez Gomez,
Fabio Esteban Murcia Martínez.

## Estructura real del repositorio

```
HORUS_Bogota_Ingenieria.xlsx          # Dataset original (hoja "Lista de Productos")
HORUS_Bogota_Ingenieria_Ingles.xlsx   # Versión en inglés (~25 000 registros, mismas 13 columnas)
notebooks/NPL_Proyecto.ipynb          # Todo el pipeline (pensado para Google Colab)
README.md
```

No hay `scripts/`, `data/raw/`, `data/cleaned/`, `requirements.txt` ni tests.

### Columnas de entrada (ambos Excel)

`Título original`, `Descripción original`, `Revista / Conferencia`, `Coautores`, `Doi`, `ISBN`, `ISSN`,
`Citaciones`, `Idioma`, `Fecha` (formato `dd/mm/aaaa`), `Tipo`, `Fuente`, `Enlace`.

## Pipeline del notebook (`notebooks/NPL_Proyecto.ipynb`)

| Celda | Qué hace |
|---|---|
| 2–5 | Clona el repo, localiza el Excel y lo carga con `pd.read_excel` |
| 8 | Conteo de nulos |
| 10 | Elimina duplicados exactos por (`Título original`, `Descripción original`, `Fecha`) |
| 12 | Limpieza: asigna `paper_id` (`HORUS_000001`…), normaliza título, abstract (quita HTML), DOI, ISSN, idioma (ISO 639-1), tipo de documento, fuente, fecha, citaciones, autores; construye `text_for_nlp` = título + abstract en minúsculas |
| 14 | `TAXONOMY` controlada (research_area, topics, methods, data_types, metrics) y extracción de etiquetas por coincidencia de frases, guardando evidencia (`RULE_BASED_TAXONOMY`, `AUTO_EXTRACTED`) |
| 16 | Placeholder de `relations_df` y `similarities` |
| 17 | Traduce tipos de documento al inglés y exporta resultados a `output/` |
| 18 | Detecta idioma real de títulos/descripciones con `langid` → `output/text_language_summary.csv` |

Salidas en `output/` (no versionado): `papers_clean.csv`, `taxonomy.json`, `paper_entities.json`,
`paper_relations.json`, `label_traceability.csv`, `similarity_candidates.csv`, métricas de calidad y
`text_language_summary.csv`.

Dependencias: `pandas`, `numpy`, `openpyxl` (para leer `.xlsx`), `langid`, `IPython`.

## Inconsistencias conocidas (revisar antes de ejecutar)

- **Ruta/nombre del dataset**: el notebook busca `HORUS_Bogota_Ingenieria_English_Dataset.xlsx` en
  `data/raw/`, `NLP-Dataset/data/raw/` o `NLP-Dataset/`, pero el archivo se renombró a
  `HORUS_Bogota_Ingenieria_Ingles.xlsx` y está en la raíz → la celda 4 lanza `FileNotFoundError`.
- **Repositorio clonado**: el notebook clona `mbarrerag/NLP-Dataset`, mientras que el remoto de este
  repo es `mbarrerag/NLP-Project`.
- **README desactualizado**: menciona `data/raw/`, `data/cleaned/`, `scripts/build_clean_dataset.py` y
  `notebooks/horus_paper_similarity_and_connections.ipynb`, que no existen.
- Numeración de secciones del notebook salta de "1." a "4."; la detección de idioma (celda 18) corre
  después de la exportación, así que sus columnas no llegan a `papers_clean.csv`.

## Convenciones

- Idioma: markdown y comentarios del notebook en **español**; nombres de columnas nuevas y valores
  normalizados en **inglés / MAYÚSCULAS_CON_GUION_BAJO** (`JOURNAL_ARTICLE`, `WEB_OF_SCIENCE`, `MISSING_ABSTRACT`).
- Se conservan las columnas originales y se añaden columnas normalizadas; **nunca se inventa contenido**
  (abstracts vacíos se marcan como `MISSING_ABSTRACT`).
- Las etiquetas son automáticas y trazables (siempre con `evidence_text`); no son etiquetas validadas por humanos.
- CSV exportados con `encoding="utf-8-sig"`; JSON con `ensure_ascii=False`.
- Los `.xlsx` pesan 16–20 MB: no los modifiques ni dupliques sin necesidad.

## Cómo ejecutar

En Google Colab: abrir `notebooks/NPL_Proyecto.ipynb` y ejecutar las celdas en orden
(primero corregir la ruta del dataset, ver arriba). Localmente:

```bash
pip install pandas numpy openpyxl langid jupyter
```

```bash
jupyter notebook notebooks/NPL_Proyecto.ipynb
```

## Próximos pasos esperados

- Implementar similitud (TF-IDF + coseno, o embeddings) y poblar `similarities`.
- Generar relaciones explícitas (DOI compartido, coautores, etiquetas comunes, revista) en `relations_df`.
- Sincronizar README y rutas del notebook con la estructura real.
