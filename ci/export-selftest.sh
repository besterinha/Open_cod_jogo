#!/bin/bash
# Self-test do PACOTE EXPORTADO (TDD §4e): exporta binário Linux com o PCK embutido
# e roda a cena SelfTest dentro dele — prova que terreno/habilidades/HUD sobrevivem
# ao empacotamento, sem precisar de device.
set -e
OUT="build/selftest/game.x86_64"
mkdir -p build/selftest
echo "selftest: exportando binário Linux..."
godot --headless --export-release "Linux" "$OUT" > /tmp/opencode/export_linux.log 2>&1 || {
  echo "selftest: export falhou:"; tail -n 20 /tmp/opencode/export_linux.log; exit 1
}
chmod +x "$OUT"
echo "selftest: rodando dentro do pacote..."
set +e
timeout 60 "$OUT" --headless -- --selftest
CODE=$?
set -e
if [ "$CODE" != "0" ]; then
  echo "selftest: FALHOU no pacote (exit $CODE) — recurso crítico não sobreviveu ao PCK"
  exit 1
fi
echo "selftest: PASS — pacote auto-verificado"
