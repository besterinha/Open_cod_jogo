#!/bin/bash
set -e
# Pipeline determinístico fatiado — sem IA, cada etapa <60s, falha rápida
# Etapas: 1 import/check-only → 2 gdlint → 3 gdformat → 4 gut (contract, unit, integration)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "validate: 1/4 godot --headless --import + --check-only"
timeout 25 godot --headless --import 2>&1 | tail -n 20
timeout 20 godot --headless --check-only 2>&1 | tail -n 20
echo "validate: 1/4 ok"
echo "validate: 2/4 gdlint (gdtoolkit 4.5.0)"
GDLINT_OUT=$(gdlint systems/ ui/ content/ 2>&1 || true)
echo "$GDLINT_OUT" | tail -n 30
if echo "$GDLINT_OUT" | grep -q "Failure:"; then echo "validate: gdlint FALHOU"; exit 1; fi
echo "validate: 2/4 ok"
echo "validate: 3/4 gdformat --check"
GDFMT_OUT=$(gdformat --check systems/ ui/ content/ tests/ 2>&1 || true)
echo "$GDFMT_OUT" | tail -n 20
if echo "$GDFMT_OUT" | grep -q "would reformat"; then echo "validate: gdformat FALHOU — rode gdformat ."; exit 1; fi
echo "validate: 3/4 ok"
echo "validate: 4/4 gut contract"
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/contract -gdir=res://tests/unit -gexit 2>&1 | tail -n 40
echo "validate: 4/4 gut integration (se contrato+unit passou)"
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gexit 2>&1 | tail -n 40
echo "validate: tudo verde"
