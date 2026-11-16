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

## Continuar la extracción del corpus completo desde otra cuenta

`corpus_full/` (20 051 `.md`) y `out-full/graphify-out/` (`graph.json`, `manifest.json` y la caché por archivo) llevan
el avance de la corrida con Sonnet 5.5 y `--token-budget 60000`. Los primeros 6 000 archivos (orden de nombre) ya
están procesados; la caché evita pagarlos de nuevo. El avance exacto está en `progress.csv`.

1. Tener instalado y con sesión iniciada `claude` (la suscripción de quien corre) y `uv tool install "graphifyy[anthropic]"`.
2. Reconstruir la carpeta de trabajo con los mismos 6 000 archivos y comprobar el estado:
   ```bash
   cd graphify
   python3 status.py add corpus_full work_corpus 6000
   python3 status.py status corpus_full work_corpus out-full
   ```
3. Correr, con la hora a la que se reinicia su ventana de uso (o `START_NOW=1` para empezar de inmediato):
   ```bash
   systemd-inhibit --what=sleep:handle-lid-switch ./run_stages.sh
   ```
4. Al terminar, versionar `out-full/graphify-out/` y `progress.csv`.

Solo una persona a la vez debe correr sobre `out-full/`: `graph.json` y `manifest.json` no se pueden fusionar a mano.
