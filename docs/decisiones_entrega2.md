# Entrega 2 – Decisiones: medidas de texto, grafo y graphify

Responsable: Juan David Rodríguez Gómez. Rama de trabajo: `feat/graph-query`, que sale de `feat/doc2vec`,
la rama más adelantada.

Alcance: medir la similitud con la query por **texto** (coseno) y por **grafo**, y preparar el **piloto con
graphify**.

## 1. Decisiones tomadas

| # | Tema | Decisión |
|---|---|---|
| D1 | Qué es una query | **Ambas formas:** texto libre o un `paper_id` existente. El texto libre pasa por el mismo preprocesamiento que el corpus (`prepare_text` + spaCy). |
| D2 | Grafos | **Un grafo por representación** (TF-IDF y Doc2Vec), para comparar sin mezclar. |
| D3 | Representación prioritaria | **Doc2Vec.** Si algo cuesta tiempo o tokens, se corre primero con Doc2Vec. TF-IDF se usa para comparar y para explicar los resultados con los términos compartidos. |
| D4 | Medidas | Se calculan y evalúan **las tres: coseno, BFS (saltos) y PPR (Personalized PageRank)**. |
| D5 | Comparación en el informe | **Combinación lineal** `final = α·pct(coseno) + (1−α)·pct(PPR)` sobre percentiles, mostrada con **casos de prueba**. |
| D6 | Flujo de graphify | `csv → .md → graphify → git → prueba que devuelve el path`. |
| D7 | Cuenta y modelo de graphify | Con la cuenta de Juan David y un **modelo más barato que Opus**. Haiku 5.5 o Sonnet 5.5 se elige **después del piloto**, comparando costo y calidad. |
| D8 | Rerank / embeddings de Hugging Face | **No bloquean.** `search()` deja preparado un `method='hf'` y un `reranker=None` para conectarlos cuando estén. |

## 2. Valores por defecto adoptados (ajustables)

No se discutieron uno por uno. Se usan estos valores y se revisan con la evaluación.

| Parámetro | Valor | Motivo |
|---|---|---|
| Semillas (top-k del coseno que pasan al grafo) | **5** | Con 10 semillas, los 10 primeros de las tres medidas son las mismas semillas y el grafo no aporta nada (ver sección 4) |
| Aristas | Top-10 vecinos, sin dirección, se queda el peso mayor | La similitud es simétrica |
| Umbral de arista | TF-IDF ≥ 0.10 (el que ya existía); Doc2Vec sin umbral extra | Doc2Vec ya va de 0.44 a 0.99; un umbral desconectaría el grafo |
| Casi-duplicados (≥ 0.9) | Se marcan en la arista (`near_duplicate`) y se avisa en los resultados | No se borra información |
| PPR | `damping = 0.85`, semillas con peso proporcional al coseno | Valor estándar |
| BFS | Profundidad máxima 2, empates resueltos por coseno | Con 3 saltos el alcance es casi todo el corpus |
| α | 0.5 hasta que haya folds | Neutral |
| Explicación de cada resultado | Términos TF-IDF compartidos con la query + camino desde la semilla más cercana | Necesaria para el KAG |
| Piloto graphify | ~300 papers, **un `.md` por paper**, sin enlaces a vecinos ni cluster en el texto | Comparación justa y nodos mapeables a `paper_id` |
| Muestra del piloto | **Vecindarios (ego-redes)** de semillas repartidas por cluster de Doc2Vec, más los casos de prueba | Una muestra al azar casi no tendría aristas entre sí (ver nota) |
| Prueba del path | Pasa si existe un camino y tiene como máximo N saltos entre papers; los nodos de concepto se muestran como explicación | Automatizable; lo cualitativo va en el informe |
| Formato de la prueba | Celda del notebook que lee `graph.json` | El proyecto no tiene `tests/` |

**Nota sobre la muestra.** Cada paper tiene solo 10 vecinos entre 20 051. Si se toman 300 papers al azar, el
grafo de Doc2Vec restringido a esa muestra queda prácticamente sin aristas, y no hay caminos que comparar con
graphify. Por eso la muestra se arma con vecindarios completos.

## 3. Pendiente por decidir

| # | Pendiente | Quién | Cuándo |
|---|---|---|---|
| P1 | Modelo de graphify (Haiku 5.5 o Sonnet 5.5) y backend (`--backend claude` con API key, o `claude-cli` con `GRAPHIFY_CLAUDE_CLI_MODEL`) | Juan David | Después del piloto |
| P2 | Validar los casos de prueba propuestos (queries y pares) | Equipo | Antes de correr graphify |
| P3 | Facultad o área por paper (verdad para la evaluación) | Ítem 2 | Antes de ajustar α |
| P4 | Folds de la validación cruzada | Ítem 2 | Antes de ajustar α |
| P5 | Modelo de embeddings y reranker de Hugging Face, entregados con los mismos `paper_id` (`.npy` alineado con `tfidf_paper_ids.csv`, nombre del modelo, texto de entrada, si van normalizados) | Compañero del clustering | Cuando esté |
| P6 | Fusionar `feat/doc2vec` (y esta rama) a `main` | Equipo | — |

## 4. Implementado y primeros resultados

Implementado en las celdas del notebook marcadas con la etiqueta `graph-query`, después de UMAP y t-SNE.
Las cifras son de una ejecución local.

- **Grafos:** Doc2Vec tiene 156 550 aristas (grado medio 15.6, máximo 247) y TF-IDF 141 530 (grado medio
  14.1, máximo 84). Los dos son una sola componente conexa. `relations_df` queda en
  `output/paper_relations.csv`.
- **`search(query, method)`** calcula coseno, BFS, PPR y el combinado para todo el corpus en ≈0.4 s.
  **`rank_results()`** ordena por cualquiera de las cuatro y explica cada resultado: términos compartidos,
  camino desde la semilla y casi duplicados. Tiene preparado el `reranker`.
- **Reproducibilidad:** la misma query da los mismos resultados en cualquier ejecución, siempre que se use el
  mismo modelo Doc2Vec. Hubo que fijar el hash que usa `infer_vector` y el orden de recorrido de networkx.
- **Número de semillas:** top-10 en común con el coseno, para Doc2Vec:

  | Semillas | PPR | BFS |
  |---|---|---|
  | 3 | ≈53 % | ≈74 % |
  | 5 | 64 % | 86 % |
  | 10 | 99 % | 100 % |

  Con 10 semillas el grafo no aporta nada nuevo.
- **Qué aporta el grafo (ejemplo):** en "machine learning … plant diseases in crops", PPR sube artículos
  pertinentes que por coseno estaban en las posiciones 18–30 (detección de antracnosis en mango, cultivos
  bajo estrés) y baja un resultado fuera de tema ("network anomaly detection"). Es un buen caso para el
  informe.
- **α**, top-10 en común con cada medida pura (Doc2Vec, 9 casos):

  | α | Con coseno | Con PPR |
  |---|---|---|
  | 0 | 64 % | 100 % |
  | 0.5 | 72 % | 82 % |
  | 1 | 100 % | 64 % |

- **Calidad de los datos:** varios títulos salen mal traducidos ("RENAL AGUDA", "HYPERTENSION AND ARRITMIES").
  Doc2Vec los encuentra por el abstract, pero en el informe se ven mal.
- **Piloto graphify:** está listo en `graphify/` (ver su README).
  - 297 artículos en 11 bolas de nieve: 6 queries de prueba, 3 artículos de ejemplo y 2 semillas al azar de
    clusters sin cubrir.
  - 798 aristas de Doc2Vec dentro de la muestra.
  - 21 pares de prueba.
  - ≈116 000 tokens de texto.

## 5. Costo estimado de graphify (corpus completo, 20 051 papers)

Estimación propia con los precios de la API, a validar con el consumo real del piloto (×≈67):

| Modelo | Estimado |
|---|---|
| Haiku 5.5 | ≈ 6–16 USD |
| Sonnet 5.5 | ≈ 125–320 USD |
| Opus 5.5 (descartado) | ≈ 250–640 USD |

Antes de la corrida completa: fijar el formato de los `.md` (graphify `--update` solo reprocesa los que
cambian) y poner un límite de gasto en la consola.
