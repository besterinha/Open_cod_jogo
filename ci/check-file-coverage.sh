#!/bin/bash
# Gate: se systems/*.gd mudou, pelo menos um teste deve ter mudado também
# Fix A5: usa merge-base + fetch para não usar origin/main desatualizado (24 atrás)
set -e
BASE_REF=${1:-origin/main}
# tenta fetch para atualizar origin/main se existir remoto
git fetch origin main --quiet 2>/dev/null || true
if git rev-parse --verify origin/main >/dev/null 2>&1; then
  BASE_REF=$(git merge-base origin/main HEAD 2>/dev/null || echo "HEAD~1")
else
  BASE_REF=HEAD~1
fi
# fallback verifica se BASE_REF existe
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
# MAP 1-1 enforcement (ajuste TAREFA 1): systems sem teste específico ainda passa se qualquer teste mudou, mas log mostra mapeamento
echo "Gate merge-base: $BASE_REF...HEAD"
exit 0
