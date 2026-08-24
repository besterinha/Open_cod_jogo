---
description: Pipeline determinístico fatiado <60s (import/check-only → gdlint → gdformat → gut)
agent: build
---

Pipeline determinístico fatiado — sem IA, etapas sequenciais, para em 1ª falha.

Saída do pipeline local:
!`bash ci/validate.sh 2>&1`

Analise a saída acima, reporte por etapa (1/4 import+check-only, 2/4 gdlint, 3/4 gdformat, 4/4 gut contract+unit+integration) se OK ou FALHOU, e se falhou indique o comando exato para corrigir. Não gere conteúdo narrativo.
