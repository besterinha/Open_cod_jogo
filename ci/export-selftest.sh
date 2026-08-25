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
RUNNER=()
if command -v xvfb-run >/dev/null 2>&1; then
  # display virtual: habilita screenshot/verificação visual sem monitor
  RUNNER=(xvfb-run -a -s "-screen 0 1280x720x24")
  echo "selftest: modo visual (xvfb)"
else
  RUNNER=()
  echo "selftest: modo headless (sem screenshot)"
fi
set +e
timeout 60 "${RUNNER[@]}" "$OUT" -- --selftest
CODE=$?
set -e
# copia screenshot (best-effort) para inspeção/artifact
SHOT=$(find "$HOME/.local/share/godot" -name "selftest.png" -newer "$OUT" 2>/dev/null | head -n 1)
if [ -n "$SHOT" ]; then
  cp "$SHOT" build/selftest/screenshot.png && echo "selftest: screenshot copiada p/ build/selftest/screenshot.png"
fi
if [ "$CODE" != "0" ]; then
  echo "selftest: FALHOU no pacote (exit $CODE) — recurso crítico não sobreviveu ao PCK"
  exit 1
fi
echo "selftest: PASS — pacote auto-verificado"
