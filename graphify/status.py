#!/usr/bin/env python3
"""Utilidades para run_stages.sh: avance de la extracción, siguiente lote y hora de reinicio de la ventana.

  status.py status SOURCE ROOT OUT      JSON con total (SOURCE), en_root (ROOT) y cubiertos (papers con nodo en graph.json)
  status.py add SOURCE ROOT N           copia a ROOT los N siguientes .md de SOURCE (orden de ruta; conserva subcarpetas)
  status.py reset "texto del error"     epoch en que se reinicia la ventana si el texto lo dice ("resets 3am"); vacío si no
"""
import json
import re
import shutil
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path


def md_files(directory):
    return sorted(p.relative_to(directory) for p in Path(directory).rglob('*.md'))


def covered_files(root, out):
    """Archivos de ROOT con al menos un nodo en el graph.json de OUT."""
    graph = Path(out) / 'graphify-out' / 'graph.json'
    if not graph.is_file():
        return set()
    try:
        nodes = json.loads(graph.read_text(encoding='utf-8'))['nodes']
    except (OSError, ValueError, KeyError):
        return set()
    names = {p.name for p in md_files(root)}
    # source_file puede traer la subcarpeta (tema_a/HORUS_x.md): se compara solo el nombre del archivo
    return {Path(n['source_file']).name for n in nodes
            if n.get('file_type') == 'paper' and Path(n.get('source_file') or '').name in names}


def cmd_status(source, root, out):
    in_root = md_files(root) if Path(root).is_dir() else []
    print(json.dumps({'total': len(md_files(source)), 'en_root': len(in_root),
                      'cubiertos': len(covered_files(root, out)) if in_root else 0}))


def cmd_add(source, root, n):
    Path(root).mkdir(parents=True, exist_ok=True)
    present = set(md_files(root))
    added = 0
    for rel in md_files(source):
        if added == int(n):
            break
        if rel in present:
            continue
        (Path(root) / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(Path(source) / rel, Path(root) / rel)
        added += 1
    print(added)


def cmd_reset(text):
    match = re.search(r'resets?\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*([ap]\.?m\.?)?', text, re.I)
    if not match:
        return
    hour, minute, meridiem = int(match.group(1)), int(match.group(2) or 0), (match.group(3) or '').lower()
    if meridiem.startswith('p') and hour < 12:
        hour += 12
    if meridiem.startswith('a') and hour == 12:
        hour = 0
    if hour > 23 or minute > 59:
        return
    now = datetime.now()
    target = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
    if target <= now:
        target += timedelta(days=1)
    print(int(time.mktime(target.timetuple())))


if __name__ == '__main__':
    command, args = sys.argv[1], sys.argv[2:]
    {'status': cmd_status, 'add': cmd_add, 'reset': cmd_reset}[command](*args)
