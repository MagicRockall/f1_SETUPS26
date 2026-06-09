#!/usr/bin/env bash
#
# extract_frames.sh — extrae frames de un video para reconstruir su UI.
#
# Saca dos conjuntos de frames y los unifica en la carpeta de salida:
#   1) un frame cada N segundos (cobertura uniforme del recorrido)
#   2) frames en cambios de escena (scroll, navegación, transiciones)
#
# Uso:
#   bash extract_frames.sh <video> [carpeta_salida] [intervalo_seg] [umbral_escena]
#
# Ejemplos:
#   bash extract_frames.sh demo.mp4
#   bash extract_frames.sh demo.mov frames/ 2 0.3

set -euo pipefail

VIDEO="${1:-}"
OUTDIR="${2:-frames}"
INTERVAL="${3:-2}"        # segundos entre frames del muestreo uniforme
SCENE="${4:-0.4}"         # 0..1, menor = más sensible a cambios

if [ -z "$VIDEO" ]; then
  echo "uso: bash extract_frames.sh <video> [carpeta_salida] [intervalo_seg] [umbral_escena]" >&2
  exit 2
fi
if [ ! -f "$VIDEO" ]; then
  echo "error: no existe el archivo '$VIDEO'" >&2
  exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "error: ffmpeg no está instalado." >&2
  echo "  macOS:  brew install ffmpeg" >&2
  echo "  Ubuntu: sudo apt install ffmpeg" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

echo ">> Muestreo uniforme: 1 frame cada ${INTERVAL}s"
ffmpeg -hide_banner -loglevel error -i "$VIDEO" \
  -vf "fps=1/${INTERVAL}" \
  -frame_pts 1 "$OUTDIR/uniform_%04d.png"

echo ">> Cambios de escena (umbral ${SCENE})"
ffmpeg -hide_banner -loglevel error -i "$VIDEO" \
  -vf "select='gt(scene,${SCENE})'" -vsync vfr \
  "$OUTDIR/scene_%04d.png" 2>/dev/null || true

COUNT=$(find "$OUTDIR" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')
echo ">> Listo: ${COUNT} frames en '${OUTDIR}/'"
echo "   (uniform_*.png = recorrido; scene_*.png = estados distintos de la UI)"
if [ "$COUNT" -gt 40 ]; then
  echo "   Nota: salieron muchos frames; quédate con los que muestren estados visualmente distintos."
fi
