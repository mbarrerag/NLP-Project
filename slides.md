---
title: Similitudes y conexiones entre papers
subtitle: Proyecto de Procesamiento de Lenguaje Natural · HORUS Bogotá
course: Procesamiento de Lenguaje Natural · Universidad Nacional de Colombia
authors: Angel David Piñeros Sierra · Miller Estiven Barrera González · Juan David Rodríguez Gómez · Fabio Esteban Murcia Martínez
date: Octubre de 2026
---

<!-- layout: cover -->
# Similitudes y conexiones entre papers

```mermaid
flowchart LR
  A["25.000 registros<br/>de HORUS"]:::g --> B["20.051 artículos<br/>en inglés"]:::o --> C["TF-IDF y Doc2Vec<br/>dos representaciones"]:::b --> D["K-Means<br/>5 áreas temáticas"]:::k
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
  classDef k fill:#FFD9A0,stroke:#232F3E,stroke-width:2px,color:#16191F
```

Notas: Presentamos cómo pasamos de un export bibliográfico de 25.000 registros a un corpus limpio en inglés, y de ahí a dos representaciones vectoriales que permiten medir similitud y agrupar artículos.

---

<!-- section: Introducción -->
<!-- item: El proyecto en una mirada -->
# El pipeline del proyecto: esta entrega prepara el texto que alimentan RAG y KAG
## En naranja, lo que cubre esta entrega; en blanco, la fase siguiente

```mermaid
flowchart LR
  subgraph IZQ["Preparación del texto"]
    direction TB
    H[("<b>Horus Dataset</b>")]:::o
    X["Data Exploration<br/>(opcional)"]:::o
    P["PDFs → PDF.md<br/>curated data"]:::g
    A["<b>#Abstract.md</b><br/><b>#Abstract.csv</b>"]:::o
    H -.-> X
    H -- "raw data" --> P -- "formatted data" --> A
    H --> A
  end
  subgraph RAG["RAG"]
    direction LR
    E["<b>Ingesta</b><br/>Embeddings Model<br/>Hugging Face"]:::g --> V[("Vector DB<br/>pgvector · Pinecone<br/>Milvus")]:::g
    V --> S["<b>Retrieval</b><br/>query → similitud<br/>coseno"]:::g --> L1["LLM"]:::k
  end
  subgraph KAG["KAG"]
    direction LR
    G["<b>Ingesta</b><br/>Graphify<br/>→ graph.json"]:::g -.-> D[("Graph DB<br/>Neo4j · TigerGraph")]:::g
    G --> B["<b>Search</b><br/>query → BFS · DFS"]:::g --> L2["LLM"]:::k
  end
  IZQ -- "chunks · tokenización" --> RAG
  IZQ --> KAG
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,stroke-width:2px,color:#232F3E
  classDef k fill:#E6F2FF,stroke:#0073BB,color:#232F3E
  style IZQ fill:#FFFBF5,stroke:#FF9900,stroke-dasharray:6 4
  style RAG fill:#FAFAFA,stroke:#545B64
  style KAG fill:#FAFAFA,stroke:#545B64
```

Notas: Este es el pipeline completo del equipo. Esta entrega cubre el dataset de HORUS, su exploración, los abstracts limpios y su tokenización; TF-IDF, Doc2Vec y K-Means (sección 3) son las representaciones base con las que entendemos el corpus antes de pasar a embeddings. RAG y KAG son la fase siguiente.

---

<!-- layout: agenda -->
<!-- section: Introducción -->
<!-- item: Agenda -->
# Agenda: los puntos de la entrega
## Cada punto del enunciado con la diapositiva donde se responde

Notas: La presentación sigue el orden del enunciado. Al final están los hallazgos, los entregables y un anexo para preguntas.

---

<!-- section: 1 · Entendimiento del negocio -->
<!-- item: 1.1 · Objetivo del negocio y del proyecto -->
# Objetivo: que la producción académica se pueda conectar por su contenido
## Del problema al objetivo del proyecto

```mermaid
flowchart LR
  P["<b>Situación</b><br/>25.000 productos académicos<br/>registrados en HORUS,<br/>sin relaciones explícitas"]:::g
  N["<b>Objetivo del negocio</b><br/>encontrar trabajos relacionados<br/>y temas comunes sin<br/>leerlos uno por uno"]:::o
  T["<b>Objetivo del proyecto</b><br/>representar cada texto como vector,<br/>medir similitud entre artículos<br/>y agruparlos por tema"]:::b
  P --> N --> T
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
```

> **Pregunta de investigación:** ¿cómo se comparan la recuperación con embeddings (RAG) y con grafos de conocimiento (KAG) para encontrar y explicar relaciones entre artículos?

Notas: El negocio es la universidad y sus investigadores: hoy la producción está registrada pero no conectada. Esta entrega construye la base: el corpus limpio y sus representaciones.

---

<!-- section: 1 · Entendimiento del negocio -->
<!-- item: 1.2 · Descripción del conjunto de textos seleccionado -->
# 25.000 registros bibliográficos; para NLP usamos el título y el abstract
## Qué trae cada registro y de qué fuente viene

::: kpi
25.000 | registros
13 | columnas por registro
jul. 2021 – dic. 2025 | fechas de publicación
11 | fuentes bibliográficas
:::

```mermaid
flowchart LR
  R(["<b>Registro HORUS</b>"]):::k
  R --> T["<b>Texto para NLP</b><br/>título · abstract"]:::o
  R --> B["<b>Bibliográficos</b><br/>revista · coautores<br/>DOI · ISSN · citaciones"]:::b
  R --> C["<b>Contexto</b><br/>idioma · fecha · tipo<br/>fuente · enlace"]:::g
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
  classDef k fill:#FFD9A0,stroke:#232F3E,stroke-width:2px,color:#16191F
```

```mermaid
xychart-beta horizontal
  title "Registros por fuente"
  x-axis ["SARA", "Scopus", "Repositorio UNAL", "Hermes", "Web of Science", "Otras 6"]
  y-axis "registros" 0 --> 10000
  bar [9158, 7695, 4624, 1496, 1003, 1024]
```

Notas: Los metadatos sirven para describir el corpus y, más adelante, para el grafo (coautores, revista). El texto que se modela es título más abstract.

---

<!-- section: 1 · Entendimiento del negocio -->
<!-- item: 1.3 · Proceso de carga u obtención de textos -->
# La mitad estaba en español: el texto se tradujo al inglés antes de entrar al pipeline
## Cómo llegan los textos al notebook

::: kpi
49 % | en inglés en el original
48 % | en español
3 % | otros idiomas o sin dato
:::

```mermaid
sequenceDiagram
  participant H as HORUS
  participant E as Equipo
  participant G as GitHub
  participant C as Colab
  H->>E: Excel · 25.000 × 13
  E->>E: Traducción automática
  E->>G: Original + versión en inglés
  C->>G: git clone
  C->>C: read_excel → DataFrame
```

> **Riesgo:** la calidad de la traducción no se ha medido. Hay evidencia de errores (anexo A2).

Notas: Sin un solo idioma, TF-IDF no puede comparar un artículo en español con uno en inglés: por eso se tradujo. Es la decisión con más riesgo del pipeline; en el anexo A2 están los problemas que encontramos.

---

<!-- section: 2 · Entendimiento y preparación del conjunto de texto -->
<!-- item: 2.1 · Análisis exploratorio del conjunto de textos -->
# El faltante real de abstracts es 17 %, no 6 %
## Nulos por columna (izquierda) y abstracts que parecen llenos pero no lo están (derecha)

```mermaid
xychart-beta horizontal
  title "Valores nulos por columna (%)"
  x-axis ["ISBN", "DOI", "ISSN", "Enlace", "Revista", "Citaciones", "Descripción", "Idioma"]
  y-axis "% de 25.000 registros" 0 --> 100
  bar [93.3, 55.4, 54.3, 42.8, 27.0, 6.0, 5.9, 0.7]
```

```mermaid
flowchart LR
  A["<b>24.257</b><br/>registros<br/>únicos"]:::g --> B["'Not reported' · 2.385"]:::o
  A --> C["'--' · 358"]:::o
  A --> O["otros marcadores · 31"]:::o
  A --> V["vacíos · 1.294"]:::g
  B & C & O & V --> S["<b>Sin abstract</b><br/><b>real</b><br/>4.068<br/>16,8 %"]:::k
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef k fill:#FFD9A0,stroke:#232F3E,stroke-width:2px,color:#16191F
```

Notas: El conteo de nulos dice que falta el 6 % de las descripciones. Pero 2 de cada 3 abstracts "vacíos" tienen texto de relleno como 'Not reported' o '--'. Además, el 85 % de los registros de Web of Science no trae abstract. Título, coautores, fecha, tipo y fuente están completos.

---

<!-- section: 2 · Entendimiento y preparación del conjunto de texto -->
<!-- item: 2.2 · Análisis descriptivo -->
# Casi la mitad son artículos de revista, con abstracts de unas 190 palabras
## Composición y longitud de los 20.051 artículos del corpus final

```mermaid
xychart-beta horizontal
  title "Tipo de documento"
  x-axis ["Artículo de revista", "Tesis de maestría", "Ponencia", "Capítulo de libro", "Proyecto", "Artículo de conferencia", "Libro", "Tesis de doctorado", "Revisión", "Otros"]
  y-axis "artículos" 0 --> 10000
  bar [9256, 3813, 2245, 1182, 1120, 681, 555, 522, 361, 316]
```

```mermaid
xychart-beta
  title "Palabras por abstract (mediana 192)"
  x-axis "palabras, desde" ["0", "50", "100", "150", "200", "250", "300", "350", "400", "500+"]
  y-axis "artículos" 0 --> 6000
  bar [639, 1410, 3252, 5714, 4047, 2325, 1344, 591, 432, 297]
```

Notas: Tesis, ponencias y capítulos tienen estilos y longitudes distintos a los artículos de revista; eso se nota luego en la similitud. Todas las tesis vienen del Repositorio UNAL. La mitad de los abstracts tiene entre 146 y 249 palabras.

---

<!-- section: 2 · Entendimiento y preparación del conjunto de texto -->
<!-- item: 2.3 · Visualización de los textos -->
# El vocabulario más común es genérico: ningún término está en más de un tercio del corpus
## Términos más frecuentes tras el preprocesamiento, y un texto antes y después

```mermaid
xychart-beta horizontal
  title "% de artículos que contienen el término"
  x-axis ["analysis", "high", "research", "process", "model", "system", "evaluate", "identify", "development", "data", "approach", "time"]
  y-axis "% de artículos" 0 --> 35
  bar [32.4, 27.8, 25.9, 25.9, 23.3, 20.7, 20.6, 19.4, 19.2, 18.1, 17.9, 17.8]
```

```mermaid
flowchart TB
  A["<b>Antes</b><br/><i>Recent advances in solvent<br/>development for carbon capture.<br/>The practices of carbon capture,<br/>storage, and utilization…</i>"]:::g
  A --> B["<b>Después</b><br/>recent · advance · solvent<br/>development · carbon · capture<br/>practice · storage · utilization …"]:::o
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
```

Notas: Por eso TF-IDF, que penaliza lo común, es el punto de partida natural. 'colombia' y 'colombian' aparecían entre los primeros (todo el corpus es de la UNAL) y se añadieron a las stopwords de dominio.

---

<!-- section: 2 · Entendimiento y preparación del conjunto de texto -->
<!-- item: 2.4 · Preprocesamiento en NLP (pipeline seguido) -->
# De 25.000 registros quedan 20.051 artículos únicos, con abstract y en inglés
## Depuración del corpus: cada registro eliminado queda en un CSV con su motivo

```mermaid
flowchart TB
  subgraph R1["Registros duplicados"]
    direction LR
    A["<b>25.000</b><br/>export"]:::g --> B["Duplicados<br/>exactos<br/><b>−90</b>"]:::o --> C["Normalización<br/>DOI · fechas<br/>tipos · fuentes"]:::b --> D["Mismo DOI o<br/>título + año<br/><b>−653</b>"]:::o --> E["<b>24.257</b><br/>únicos"]:::g
  end
  subgraph R2["Filtro: ¿abstract real y en inglés? (idioma del documento completo)"]
    direction LR
    F["Sin abstract<br/>real<br/><b>−4.068</b>"]:::o ~~~ H["Título sin<br/>traducir<br/><b>−120</b>"]:::o ~~~ I["No está<br/>en inglés<br/><b>−18</b>"]:::o ~~~ G["<b>20.051</b><br/>artículos"]:::k
  end
  R1 --> R2
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
  classDef k fill:#FFD9A0,stroke:#232F3E,stroke-width:2px,color:#16191F
  style R1 fill:#FAFAFA,stroke:#AAB7B8
  style R2 fill:#FAFAFA,stroke:#FF9900
```

Notas: Se conserva el 80 % del export. El duplicado por DOI es el más común porque un artículo se indexa en varias bases (sobre todo Scopus y SARA); se conserva el registro con abstract. El idioma se decide con título más abstract, no solo con el título (anexo A3). El Excel original no se modifica.

---

<!-- section: 2 · Entendimiento y preparación del conjunto de texto -->
<!-- item: 2.4 · Preprocesamiento en NLP (pipeline seguido) -->
# Cada texto pasa por cuatro pasos hasta quedar como tokens lematizados
## Mediana por documento: 192 palabras de entrada → 105 tokens

```mermaid
flowchart TB
  A["Título + abstract<br/>(mayúsculas originales)"]:::g
  B["<b>1 · Limpieza de plantilla</b><br/>'text taken from the source'<br/>copyright · encabezados"]:::o
  C["<b>2 · Tokenización</b><br/>spaCy en_core_web_sm"]:::b
  D["<b>3 · Stopwords</b><br/>spaCy + plantilla académica<br/>números · abreviaturas"]:::o
  E["<b>4 · Lematización</b><br/>trained → train<br/>computing → compute (no 'comput')"]:::b
  F["<b>Tokens</b><br/>entrada de TF-IDF<br/>y de Doc2Vec"]:::k
  subgraph F1[" "]
    direction LR
    A --> B --> C
  end
  subgraph F2[" "]
    direction LR
    D --> E --> F
  end
  F1 --> F2
  style F1 fill:none,stroke:none
  style F2 fill:none,stroke:none
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
  classDef k fill:#FFD9A0,stroke:#232F3E,stroke-width:2px,color:#16191F
```

Notas: Lematización y no stemming: el stemming deja raíces ilegibles (comput) y los términos de TF-IDF y los nodos del grafo deben poder leerse. La limpieza de plantilla importa: '(text taken from the source)' estaba en unos 1.300 registros del Repositorio UNAL y habría hecho parecer similares a todos esos documentos.

---

<!-- section: 3 · Transformación del texto para extracción de características -->
<!-- item: 3.1 · Estrategia de extracción de características -->
# Dos representaciones del mismo texto, sometidas al mismo procedimiento
## Mismos tokens de entrada; a cada una se le calculan vecinos y se le aplica K-Means para comparar

```mermaid
flowchart LR
  T["<b>Tokens</b><br/>20.051 artículos"]:::k
  T --> TF["<b>TF-IDF</b><br/>pesos por término"]:::o
  T --> DV["<b>Doc2Vec</b><br/>vector aprendido"]:::b
  TF --> V1["Vecinos por coseno<br/>hasta 10, similitud ≥ 0,10"]:::g
  DV --> V2["Vecinos por coseno<br/>10 por artículo"]:::g
  TF --> SV["SVD a<br/>100 dimensiones"]:::g --> K1["<b>K-Means + UMAP</b><br/>K = 5 · hecho"]:::o
  DV --> K2["<b>K-Means + UMAP</b><br/>siguiente paso"]:::b
  K1 --> CMP["<b>Comparativa</b><br/>clusters y mapas UMAP<br/>TF-IDF vs Doc2Vec"]:::k
  K2 -.-> CMP
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
  classDef k fill:#FFD9A0,stroke:#232F3E,stroke-width:2px,color:#16191F
```

Notas: No elegimos una representación a priori: las dos pasan por el mismo procedimiento y se comparan con los mismos criterios. TF-IDF se reduce con SVD antes de K-Means porque es dispersa y de 25.071 columnas; Doc2Vec ya tiene 100 dimensiones. K-Means y UMAP sobre Doc2Vec son el siguiente paso, para la comparativa.

---

<!-- section: 3 · Transformación del texto para extracción de características -->
<!-- item: 3.2 · Representaciones: cómo se ven las matrices -->
# TF-IDF da una matriz enorme y casi vacía; Doc2Vec, una pequeña y llena
## Los mismos 12 artículos (3 por tema) en las dos matrices · color intenso = peso alto · en Doc2Vec, azul = valor negativo

![Muestra de la matriz TF-IDF y de la matriz de Doc2Vec para los mismos 12 artículos](assets/matrices.png)

Notas: En TF-IDF cada columna es un término del vocabulario (25.071) y casi todas las celdas son cero: en promedio un artículo usa unos 70 términos distintos, el 0,28 % de las columnas. En Doc2Vec cada columna es una dimensión aprendida (100) y todas las celdas tienen valor: no se pueden leer como palabras.

---

<!-- section: 3 · Transformación del texto para extracción de características -->
<!-- item: 3.3 · TF-IDF -->
# TF-IDF conecta artículos por vocabulario técnico compartido, y puede explicar cada conexión
## Los 4 vecinos más cercanos de un artículo; en cada flecha, la similitud y los términos que más aportan

```mermaid
{{NEIGHBORS_TFIDF}}
```

> Las similitudes son bajas en valor absoluto (≈ 0,2): lo que importa es el orden de los vecinos, no el número.

Notas: Artículo HORUS_000037. Los cuatro vecinos tratan de control de bacterias que atacan cultivos, y los términos que los unen son nombres de especies y del método (carotovorum, pectobacterium, solanacearum, bacillus). Es lo que TF-IDF hace bien: unir por vocabulario técnico poco frecuente. El quinto vecino (0,18) ya es de biopelículas orales: las conexiones más débiles se apoyan en palabras más generales. Su límite: no ve sinónimos; para TF-IDF, 'crop' y 'cultivation' no tienen relación.

---

<!-- section: 3 · Transformación del texto para extracción de características -->
<!-- item: 3.4 · Doc2Vec -->
# Doc2Vec aprende relaciones entre palabras que TF-IDF no ve
## Palabras más cercanas a cuatro términos del corpus, según el modelo (similitud coseno)

```mermaid
flowchart LR
  crop["<b>crop</b>"]:::o --- c["cultivation 0,76 · pest 0,71<br/>agricultural 0,69 · preharvest 0,68"]:::g
  concrete["<b>concrete</b>"]:::b --- k["shotcrete 0,75 · mortar 0,73<br/>durability 0,70"]:::g
  energy["<b>energy</b>"]:::o --- e["renewable 0,75 · electricity 0,70<br/>generation 0,69"]:::g
  learning["<b>learning</b>"]:::b --- l["machine 0,80 · teaching 0,70<br/>pytorch 0,69"]:::g
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
```

> **Límite:** sus 100 dimensiones no son palabras; para explicar por qué conecta dos artículos hay que volver a TF-IDF.

Notas: Variante PV-DBOW con vectores de palabra. Los términos raros (siglas o erratas de 3-4 artículos) generan vecinos ruidosos. Los parámetros están en el anexo A1.

---

<!-- layout: figure -->
<!-- section: 3 · Transformación del texto para extracción de características -->
<!-- item: 3.5 · Agrupamiento con K-Means -->
# K-Means sobre TF-IDF encuentra cinco áreas amplias, con fronteras difusas
## Artículos proyectados en 2D con UMAP y coloreados por cluster (K = 5)

![Artículos proyectados con UMAP sobre TF-IDF reducido a 100 dimensiones, coloreados por cluster de K-Means](assets/umap_tfidf.png)

::: leyenda
#0173B2 | Ciencias sociales y educación · 6.382
#DE8F05 | Modelado y simulación · 4.600
#029E73 | Química y materiales · 3.843
#D55E00 | Salud y clínica · 2.851
#CC78BC | Biodiversidad y ecología · 2.375
:::

::: kpi
0,05 | silueta: clusters poco separados
0,80 | ARI entre corridas: K = 5 es estable, no necesariamente bueno
:::

Notas: K de 2 a 10 con 100 corridas por K; K = 5 fue el más estable entre 3 y 10 y dio temas interpretables. Pero la silueta de 0,05 dice que los grupos están poco separados: son temas amplios con fronteras difusas, no categorías cerradas. t-SNE muestra las mismas regiones. Siguiente paso: el mismo mapa y K-Means sobre Doc2Vec, para compararlos.

---

<!-- layout: cards -->
<!-- section: Cierre -->
<!-- item: Hallazgos -->
# Lo que sabemos hasta ahora

::: cards
El corpus pedía más limpieza de la que se veía | 17 % sin abstract real, 743 duplicados y la mitad en español: quedan 20.051 de 25.000 registros.
Las dos representaciones se complementan | TF-IDF explica cada conexión pero no ve sinónimos; Doc2Vec capta relaciones de significado pero no las explica.
Hay estructura temática, pero poco separada | Cinco áreas amplias con silueta de 0,05. Siguiente: compararlas con K-Means y UMAP sobre Doc2Vec.
:::

Notas: Tres ideas para llevarse. La tercera es también la principal limitación: sin etiquetas de qué artículos son similares, ninguna representación se puede declarar mejor.

---

<!-- section: Cierre -->
<!-- item: Entregables y próximos pasos -->
# Entregables y lo que sigue
## Siguiente paso: comparar UMAP y K-Means de TF-IDF contra los de Doc2Vec

::: cards
Notebook de trabajo | NPL_Proyecto.ipynb en Google Colab: de la carga a K-Means, reproducible desde el repositorio.
Datasets | Excel original y traducido (25.000 registros); corpus limpio, tokens, matrices, vecinos, clusters y registros descartados con su motivo.
Documento | Artículo en formato científico con el método y los resultados.
:::

```mermaid
flowchart LR
  A["K-Means y UMAP<br/>sobre Doc2Vec"]:::b --> B["<b>Comparativa</b><br/>UMAP y K-Means<br/>TF-IDF vs Doc2Vec"]:::k --> C["RAG y KAG"]:::o --> D["Evaluación con<br/>pares anotados"]:::b
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
  classDef b fill:#E6F2FF,stroke:#0073BB,color:#232F3E
  classDef k fill:#FFD9A0,stroke:#232F3E,stroke-width:2px,color:#16191F
```

Notas: Todo está en el repositorio mbarrerag/NLP-Project; las salidas del notebook se regeneran ejecutándolo. Siguiente paso: K-Means y UMAP sobre Doc2Vec con los mismos parámetros que TF-IDF (K = 5, mismos vecinos y semilla de UMAP) y comparar: tabla cruzada de clusters, ARI/NMI entre las dos particiones y los dos mapas lado a lado. La silueta no se compara directo entre espacios distintos y UMAP deforma distancias globales: el mapa sirve para ver, no para medir. El reto abierto es la evaluación: no existen etiquetas de qué artículos son similares, así que hay que construirlas.

---

<!-- layout: closing -->
<!-- section: Cierre -->
<!-- item: Preguntas -->
# ¿Preguntas?

Notas: En el anexo hay respaldo para las preguntas más probables: parámetros (A1), traducción (A2) e idioma (A3).

---

<!-- layout: table -->
<!-- section: Anexo -->
<!-- item: A1 · Parámetros y decisiones -->
# Parámetros de las representaciones y por qué se eligieron

| | TF-IDF | Doc2Vec | K-Means |
|---|---|---|---|
| Configuración | unigramas · min_df 3 · max_df 0,8 · sublinear_tf | PV-DBOW (dm 0, dbow_words 1) · 100 dimensiones · window 5 · min_count 3 · 40 épocas | K de 2 a 10 · 100 corridas por K · SVD a 100 dimensiones para TF-IDF |
| Por qué | los bigramas multiplican el vocabulario ×6 y el vecino más cercano se mantiene en el 95 % de los casos | PV-DBOW funciona mejor en textos cortos; vectores de palabra para inspeccionar el modelo | K = 5: el más estable entre 3 y 10 (ARI 0,80) y con temas interpretables |
| Resultado | 25.071 términos · densidad 0,28 % · 200.041 pares con similitud ≥ 0,10 | 32.947 palabras · 200.510 pares (no se filtra ninguno) | silueta 0,051 · Davies-Bouldin 3,94 |

Notas: Diferencia entre 200.041 y 200.510 pares: TF-IDF descarta los vecinos con similitud menor a 0,10 (469 pares); en Doc2Vec ninguno queda por debajo. 105 tokens por documento cuenta repeticiones; 70 términos por artículo cuenta términos distintos dentro del vocabulario de TF-IDF.

---

<!-- layout: cards -->
<!-- section: Anexo -->
<!-- item: A2 · Calidad de la traducción -->
# La traducción automática dejó errores que el pipeline detecta, pero no corrige
## Evidencia encontrada en la versión en inglés del dataset

::: cards
120 títulos sin traducir | Abstract en inglés y título en español: se eliminan en el filtro de idioma.
35 registros con marcas internas | Restos como '__KEEP0_' donde la traducción perdió contenido (≤, URLs, cursivas). Se limpian, pero el texto perdido no vuelve.
Títulos en MAYÚSCULAS mal traducidos | Ej.: 'AEROSOLES GONE BY VEEGETATION SCHEDULE' (original: aerosoles generados por quemas de vegetación).
:::

> **Pendiente:** documentar la herramienta de traducción y revisar a mano una muestra.

Notas: La traducción unifica el idioma, que es lo que TF-IDF necesita, pero introduce ruido. No hemos medido su calidad; la evidencia es cualitativa.

---

<!-- section: Anexo -->
<!-- item: A3 · Decisiones del preprocesamiento -->
# El idioma se decide con todo el documento, no solo con el título
## Y se lematiza en vez de hacer stemming

```mermaid
flowchart LR
  Q["¿Qué artículos<br/>están en inglés?"]:::g --> T["<b>Por el título</b><br/>falla con títulos cortos,<br/>en MAYÚSCULAS o científicos<br/>≈ 650 eliminados por error"]:::g
  Q --> D["<b>Por el documento (elegido)</b><br/>título + abstract<br/>langid: en, es, pt, fr, it, de"]:::o
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
```

```mermaid
flowchart LR
  W["computing<br/>computed<br/>computer"]:::g --> S["<b>Stemming</b><br/>comput · comput · comput"]:::g
  W --> L["<b>Lematización (elegida)</b><br/>compute · compute · computer"]:::o
  classDef g fill:#FFFFFF,stroke:#AAB7B8,color:#232F3E
  classDef o fill:#FFF2E6,stroke:#FF9900,color:#232F3E
```

Notas: Ejemplos reales de langid sobre títulos: 'STAPHYLOCOCCUS AUREUS IN PEDIATRIA' sale italiano y 'Observation of the B0 → D̄*0K+π- decays' sale latín. Con título y abstract juntos, 20.711 de 20.741 documentos con abstract salen en inglés.
