#!/bin/bash
# Guarda de conteúdo do pacote: falha se recurso crítico não estiver dentro do APK/PCK.
# Raiz da classe "sumiu no device" (T1/T2): mapa/habilidades ausentes no export.
set -e
APK="${1:-build/debug.apk}"
if [ ! -f "$APK" ]; then
  echo "apk-content: $APK não encontrado — rode o export antes"; exit 1
fi
CRITICAL=(
  "assets/data/maps/tactical_arena.tres"
  "assets/data/stats/attributes.tres"
  "assets/data/abilities/strike.tres"
  "assets/data/abilities/heal.tres"
  "assets/data/abilities/fireball.tres"
  "assets/data/abilities/conejato.tres"
  "assets/data/abilities/anelado.tres"
)
MISSING=0
for f in "${CRITICAL[@]}"; do
  if ! unzip -l "$APK" | grep -q "$f"; then
    echo "apk-content: FALTANDO no pacote: $f"; MISSING=1
  fi
done
if [ "$MISSING" = "1" ]; then exit 1; fi
echo "apk-content: todos os $((${#CRITICAL[@]})) recursos críticos presentes em $APK"
