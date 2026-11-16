#!/usr/bin/env bash
# Procesa el corpus con graphify por lotes, esperando a que se reinicie la ventana de uso de Claude cuando se agota.
# Es reanudable: graphify guarda cada fragmento terminado en la caché de OUT y salta lo ya hecho.
#
#   ./run_stages.sh                  espera a FIRST_RESET (22:50) y empieza
#   START_NOW=1 ./run_stages.sh      empieza ya, usando lo que quede de la ventana actual
#   DRY_RUN=1 ./run_stages.sh        solo muestra el plan, sin llamar a graphify
#
# Para que el portátil no se suspenda mientras corre:
#   systemd-inhibit --what=sleep:idle ./run_stages.sh   (Linux)
#   caffeinate -is ./run_stages.sh                      (macOS)
#
# Estado en cualquier momento:  python3 status.py status "$SOURCE" "$ROOT" "$OUT"
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SOURCE="${SOURCE:-$HERE/corpus_full}"          # todos los .md; si tiene subcarpetas por tema se conservan
ROOT="${ROOT:-$HERE/work_corpus}"              # carpeta que va creciendo: es la que lee graphify
OUT="${OUT:-$HERE/out-full}"                   # salida (graphify-out/ con graph.json y la caché)
MODEL="${MODEL:-claude-sonnet-5-5}"
BUDGET="${BUDGET:-60000}"                      # --token-budget: con 150000 Sonnet omitió el 65 % de los archivos
BATCH="${BATCH:-1000}"                         # archivos nuevos por iteración
FIRST_RESET="${FIRST_RESET:-22:50}"            # primera vez que se reinicia la ventana
WINDOW_SECS="${WINDOW_SECS:-18000}"            # duración de la ventana (5 h)
MARGIN_SECS="${MARGIN_SECS:-120}"              # margen tras el reinicio calculado
PROBE_SECS="${PROBE_SECS:-900}"                # si el reinicio estimado ya pasó y sigue el límite, reintenta cada 15 min
MAX_WINDOWS="${MAX_WINDOWS:-10}"               # tope de esperas por límite, por seguridad
MAX_IDLE="${MAX_IDLE:-3}"                      # iteraciones seguidas sin avance y sin límite antes de parar
LOGDIR="${LOGDIR:-$HERE/logs}"
PROGRESS="${PROGRESS:-$HERE/progress.csv}"
NEUTRAL_DIR="${NEUTRAL_DIR:-$(mktemp -d)}"     # cwd de graphify: así `claude -p` no lee el CLAUDE.md/AGENTS.md del proyecto
LIMIT_RE='usage limit|limit reached|hit your limit|rate.?limit|resets? |quota|overloaded|is_error.?.? *true'

mkdir -p "$LOGDIR"
[ -f "$PROGRESS" ] || echo "hora,iteracion,archivos_en_root,cubiertos,tokens_in,tokens_out,salida,limite,nota" > "$PROGRESS"
say() { printf '[%s] %s\n' "$(date '+%d/%m %H:%M:%S')" "$*" | tee -a "$LOGDIR/run_stages.log"; }
# Fechas portables (Linux y macOS): `date -d` no existe en BSD/macOS
fmt_epoch() { python3 -c 'import sys,time;print(time.strftime(sys.argv[2],time.localtime(int(sys.argv[1]))))' "$1" "${2#+}"; }
next_at() {                                     # próximo epoch con hora HH:MM (hoy o mañana)
    python3 -c 'import sys,datetime as d;h,m=map(int,sys.argv[1].split(":"));n=d.datetime.now();t=n.replace(hour=h,minute=m,second=0,microsecond=0);t+=d.timedelta(days=t<=n);print(int(t.timestamp()))' "$1"; }

sleep_until() {                                 # duerme por tramos de 60 s: si el equipo se suspende, al volver revisa la hora real
    local target="$1"
    while [ "$(date +%s)" -lt "$target" ]; do
        [ -n "${DRY_RUN:-}" ] && { say "(dry-run) esperaría hasta $(fmt_epoch "$target" '+%d/%m %H:%M:%S')"; return; }
        sleep $(( target - $(date +%s) < 60 ? target - $(date +%s) + 1 : 60 ))
    done
}

command -v graphify >/dev/null || { say "graphify no está instalado (uv tool install \"graphifyy[anthropic]\")"; exit 2; }
[ -d "$SOURCE" ] || { say "No existe SOURCE=$SOURCE"; exit 2; }

say "Inicio | modelo=$MODEL budget=$BUDGET lote=$BATCH | SOURCE=$SOURCE ROOT=$ROOT OUT=$OUT"

if [ -z "${START_NOW:-}" ]; then
    target=$(next_at "$FIRST_RESET")
    target=$(( target + MARGIN_SECS ))
    say "Esperando el primer reinicio de la ventana: $(fmt_epoch "$target" '+%d/%m %H:%M')"
    sleep_until "$target"
fi
window_start=$(date +%s)
if [ -n "${START_NOW:-}" ]; then                 # la ventana en curso termina en FIRST_RESET, no 5 h después de ahora
    first=$(next_at "$FIRST_RESET")
    window_start=$(( first - WINDOW_SECS ))
    say "Empiezo ya: la ventana actual termina a las $(fmt_epoch "$first" '+%d/%m %H:%M')."
fi
waits=0; idle=0; iteration=0; attempt=0; last_covered=-1; retry=""

while true; do
    attempt=$((attempt + 1))
    if [ -z "$retry" ]; then                    # tras un límite se repite el mismo lote sin agregar archivos
        iteration=$((iteration + 1))
        added=$(python3 "$HERE/status.py" add "$SOURCE" "$ROOT" "$BATCH")
    else
        added=0
    fi
    retry=""
    log="$LOGDIR/iter_$(printf '%03d' "$iteration")_intento_$(printf '%02d' "$attempt").log"
    say "Iteración $iteration (intento $attempt): +$added archivos nuevos en ROOT"

    if [ -n "${DRY_RUN:-}" ]; then say "(dry-run) graphify extract $ROOT --backend claude-cli --token-budget $BUDGET --out $OUT"; break; fi

    ( cd "$NEUTRAL_DIR" && GRAPHIFY_BACKEND=claude-cli GRAPHIFY_CLAUDE_CLI_MODEL="$MODEL" \
        graphify extract "$ROOT" --backend claude-cli --token-budget "$BUDGET" --out "$OUT" ) > "$log" 2>&1
    code=$?

    read -r tin tout < <(grep -h 'tokens:' "$log" | tail -1 | sed -E 's/.*tokens: ([0-9,]+) in \/ ([0-9,]+) out.*/\1 \2/; s/,//g')
    status_json=$(python3 "$HERE/status.py" status "$SOURCE" "$ROOT" "$OUT")
    total=$(echo "$status_json" | python3 -c 'import sys,json;print(json.load(sys.stdin)["total"])')
    in_root=$(echo "$status_json" | python3 -c 'import sys,json;print(json.load(sys.stdin)["en_root"])')
    covered=$(echo "$status_json" | python3 -c 'import sys,json;print(json.load(sys.stdin)["cubiertos"])')
    limit_hit=no; grep -qiE "$LIMIT_RE" "$log" && limit_hit=yes
    echo "$(date '+%F %T'),$iteration,$in_root,$covered,${tin:-},${tout:-},$code,$limit_hit," >> "$PROGRESS"
    say "  salida=$code | en ROOT=$in_root cubiertos=$covered de $total | tokens ${tin:-?} in / ${tout:-?} out | límite=$limit_hit"

    if [ "$limit_hit" = yes ]; then
        waits=$((waits + 1))
        [ "$waits" -gt "$MAX_WINDOWS" ] && { say "Demasiadas esperas por límite ($MAX_WINDOWS): paro."; exit 1; }
        target=$(python3 "$HERE/status.py" reset "$(grep -iE 'resets?' "$log" | tail -1)")
        [ -z "$target" ] && target=$(( window_start + WINDOW_SECS + MARGIN_SECS ))
        [ "$target" -le "$(date +%s)" ] && target=$(( $(date +%s) + PROBE_SECS ))
        say "Límite de uso. Reintento a las $(fmt_epoch "$target" '+%d/%m %H:%M')."
        sleep_until "$target"
        window_start=$(date +%s)
        retry=1
        continue
    fi

    if [ "$code" -ne 0 ]; then
        idle=$((idle + 1)); say "  Error sin límite (ver $log). Intento $idle de $MAX_IDLE."
        [ "$idle" -ge "$MAX_IDLE" ] && { say "Paro: errores repetidos."; exit 1; }
        retry=1; sleep 60; continue
    fi

    if [ "$in_root" -ge "$total" ] && [ "$covered" -ge "$in_root" ]; then say "Terminado: $covered de $total archivos cubiertos."; exit 0; fi
    if [ "$covered" -le "$last_covered" ]; then
        idle=$((idle + 1)); say "  Sin avance ($idle de $MAX_IDLE)."
        [ "$idle" -ge "$MAX_IDLE" ] && { say "Paro: sin avance. Quedan $((in_root - covered)) archivos sin nodo en ROOT y $((total - in_root)) por agregar."; exit 1; }
    else
        idle=0
    fi
    last_covered=$covered
done
