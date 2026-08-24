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
# Gate AVISO (1 sprint, não bloqueante) — func/sinal público novo sem integration (emissor→consumidor)
# Usa STAGED se existir (pre-commit), senão HEAD~1 (CI per-commit) para não pegar histórico 24 atrás
if git diff --cached --name-only --diff-filter=AM 2>/dev/null | grep -qE '^systems/.*\.gd$'; then
  AVISO_BASE="--cached"
  CHANGED_INTEGRATION=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null | grep -E '^tests/integration/.*\.gd$' || true)
  DIFF_SYS=$(git diff --cached -U0 -- systems/ 2>/dev/null || true)
else
  CHANGED_INTEGRATION=$(git diff --name-only --diff-filter=AM HEAD~1...HEAD 2>/dev/null | grep -E '^tests/integration/.*\.gd$' || true)
  DIFF_SYS=$(git diff -U0 HEAD~1...HEAD -- systems/ 2>/dev/null || true)
fi
NEW_PUB_FUNCS=$(echo "$DIFF_SYS" | grep -E "^\+\s*func\s+[^_]" | grep -v "func _" || true)
NEW_SIGNALS=$(echo "$DIFF_SYS" | grep -E "^\+\s*signal\s+" || true)
# filtra isenção por comentário "# integration: exempt" na mesma linha adicionada
if [ -n "$NEW_PUB_FUNCS" ]; then
  FILTERED_FUNCS=$(echo "$NEW_PUB_FUNCS" | grep -v "integration: exempt" || true)
  REMOVED_FUNCS=$(echo "$DIFF_SYS" | grep -E "^\-\s*func\s+[^_]" || true)
  if [ -z "$FILTERED_FUNCS" ]; then ADDED_CNT=0; else ADDED_CNT=$(echo "$FILTERED_FUNCS" | grep -c . || echo 0); fi
  if [ -z "$REMOVED_FUNCS" ]; then REMOVED_CNT=0; else REMOVED_CNT=$(echo "$REMOVED_FUNCS" | grep -c . || echo 0); fi
  CHANGED_FILES_CNT=$(git diff --name-only $BASE_REF...HEAD -- systems/ 2>/dev/null | wc -l | tr -d ' ')
  IS_RENAME_PURO=false
  if [ "$ADDED_CNT" -eq "$REMOVED_CNT" ] && [ "$ADDED_CNT" -eq 1 ] && [ "$CHANGED_FILES_CNT" -eq 1 ]; then
    IS_RENAME_PURO=true
    echo -e "\033[33m::warning:: Rename puro detectado (1 remoção + 1 adição no mesmo arquivo) — não conta como nova superfície, calibrado\033[0m"
    echo "$REMOVED_FUNCS" | head -n 5
    echo "$FILTERED_FUNCS" | head -n 5
  elif [ -n "$REMOVED_FUNCS" ] && [ -n "$FILTERED_FUNCS" ]; then
    echo -e "\033[33m::warning:: Possível rename (remoção+adição) — calibrar antes de BLOQUEANTE\033[0m"
    echo "$REMOVED_FUNCS" | head -n 5
    echo "$FILTERED_FUNCS" | head -n 5
  fi
  if [ "$IS_RENAME_PURO" = true ]; then
    echo "Gate AVISO func pública: rename puro, sem aviso integration"
  elif [ -n "$FILTERED_FUNCS" ] && [ -z "$CHANGED_INTEGRATION" ]; then
    echo -e "\033[33m::warning:: Nova superfície pública em systems/ sem teste integration (AVISO 1 sprint, não bloqueia)\033[0m"
    echo "$FILTERED_FUNCS" | head -n 10
    echo -e "\033[33mDica: adicione tests/integration/test_*_input_real.gd com watch_signals(consumidor) ou comente '# integration: exempt — motivo' na linha (só para getter puro)\033[0m"
  elif [ -n "$FILTERED_FUNCS" ]; then
    echo "Gate AVISO func pública: ok, integration também mudou"
  fi
fi
if [ -n "$NEW_SIGNALS" ] && [ -z "$CHANGED_INTEGRATION" ]; then
  echo -e "\033[33m::warning:: Novo signal em systems/ sem teste integration (AVISO, sinal sempre precisa consumidor)\033[0m"
  echo "$NEW_SIGNALS" | head -n 10
fi
exit 0
