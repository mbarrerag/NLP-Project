# Piloto con graphify

Archivos de entrada para el piloto del KAG. Los genera la sección **"Preparación del piloto con graphify"** del
notebook, que los escribe en `notebooks/output/graphify/`. Esta carpeta es la **copia congelada**: el modelo
Doc2Vec se entrena con varios hilos y no es exactamente reproducible, así que reentrenarlo cambia la muestra.
Para comparar resultados de graphify se usa siempre esta copia.

| Archivo | Contenido |
|---|---|
| `corpus/HORUS_xxxxxx.md` | 297 artículos, uno por archivo. Metadatos en el encabezado YAML, título y abstract limpio. No lleva vecinos ni cluster. |
| `sample.csv` | `paper_id`, semilla de la que viene (bola de nieve sobre el grafo de Doc2Vec), origen de la semilla y cluster de Doc2Vec |
| `test_pairs.csv` | 21 pares de prueba: 11 `same_area` (camino de 1-2 saltos en nuestro grafo) y 10 `cross_area` (7 sin camino en la muestra) |
| `d2v_sample_graph.json` | Nuestro grafo de Doc2Vec restringido a la muestra (`node_link_data` de networkx), para comparar con el `graph.json` de graphify |

Tamaño del texto: ≈116 000 tokens. El costo estimado del piloto es de céntimos con Haiku 5.5 y de unos pocos
dólares con Sonnet 5.5, más el prompt de graphify.

## Cómo correrlo

Resultados del piloto, consumo y decisiones: `docs/decisiones_entrega2.md` (sección 5).

- Instalación: `uv tool install "graphifyy[anthropic]"`.
- Con la suscripción se usa el backend `claude-cli`: `GRAPHIFY_BACKEND=claude-cli
  GRAPHIFY_CLAUDE_CLI_MODEL=claude-sonnet-5-5 graphify extract <carpeta> --backend claude-cli --token-budget 60000
  --out <salida>`. Sin `GRAPHIFY_CLAUDE_CLI_MODEL` corre con Opus. Con `--token-budget` grande Sonnet omite
  archivos: usar 60000.
- Para el corpus completo: `run_stages.sh` (por lotes, espera el reinicio de la ventana de uso y reanuda con la
  caché de graphify) y `status.py` (avance). Ver el encabezado de `run_stages.sh`.
- Se versionan `graph.json` y los reportes; la caché (`graphify-out/cache/`) está en `.gitignore`.
