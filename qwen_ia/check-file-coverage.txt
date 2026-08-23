#!/bin/bash
# Gate: se systems/*.gd mudou, pelo menos um teste deve ter mudado também
# Fecha brecha crítica #1 sem ser excessivamente rígido para solo dev (arquivo→teste exato é muito estrito quando 1 teste cobre 4 systems)
set -e
BASE_REF=${1:-origin/main}
if ! git rev-parse --verify $BASE_REF >/dev/null 2>&1; then
  BASE_REF=HEAD~1
fi
CHANGED_SYS=$(git diff --name-only --diff-filter=AM $BASE_REF...HEAD 2>/dev/null | grep -E '^systems/.*\.gd$' || true)
CHANGED_TEST=$(git diff --name-only --diff-filter=AM $BASE_REF...HEAD 2>/dev/null | grep -E '^tests/.*\.gd$' || true)
if [ -n "$CHANGED_SYS" ]; then
  if [ -z "$CHANGED_TEST" ]; then
    echo "::error::systems/*.gd mudou mas nenhum teste em tests/ mudou — adicione teste unit+integration para a feature"
    echo "Arquivos mudados:"
    echo "$CHANGED_SYS"
    exit 1
  else
    echo "ok: systems/ mudou e testes também mudaram"
    echo "systems:"
    echo "$CHANGED_SYS" | head -n 10
    echo "tests:"
    echo "$CHANGED_TEST" | head -n 10
  fi
else
  echo "check-file-coverage: nenhum .gd em systems/ mudou, ok"
fi
# data/*.tres também precisa de contract
DATA_CHANGED=$(git diff --name-only --diff-filter=AM $BASE_REF...HEAD 2>/dev/null | grep -E '^data/.*\.tres$' || true)
if [ -n "$DATA_CHANGED" ] && [ -z "$CHANGED_TEST" ]; then
  echo "::error::data/*.tres mudou mas nenhum teste mudou — contrato deve validar"
  exit 1
fi
exit 0
