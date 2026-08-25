# WORKFLOW — Remontagem do Ambiente & Loop Operacional

**Versão:** 1.0 | **Data:** 2026-08-25 | **Alvo:** qualquer IA/humano reconstruindo este projeto em outra plataforma (ex: Replit)
**Pré-requisito:** ler `AGENTS.md` (constituição), `docs/TDD.md` (técnico), `docs/GDD.md` (jogo). Este doc NÃO duplica esses — cobre **ambiente + pipeline + rotina**.

---

## 1. Stack Travada (tudo gratuito/MIT)

| Ferramenta | Versão | Fonte |
|---|---|---|
| Godot Engine **Standard** (sem .NET) | 4.7.2-stable | godotengine.org/download/archive |
| GDScript + gdtoolkit (gdlint/gdformat) | 4.5.0 | `pip install gdtoolkit==4.5.0` |
| GUT (testes) | 9.7.1 branch godot_4_7 | **já vem no repo** (`addons/gut/`) |
| Renderer | Mobile, ETC2 | project.godot |
| JDK (só p/ APK local) | 17 (Temurin) | opcional — ver §6 |
| Android SDK (só p/ APK local) | Platform 35, Build-Tools 35.0.1 | opcional — ver §6 |
| Xvfb + libs X11 + mesa | qualquer atual | modo visual do self-test |

**Regra de ouro:** nada pago, nenhuma licença proprietária. Godot Standard = MIT.

---

## 2. Anatomia do Repositório

```
addons/    grid_toolkit + gut — toolkit agnóstico, NUNCA importa de systems/content
systems/   regras: caravan/, tactical/ (grid,turn,movement,combat,terrain,ai), ability/, common/, stats/
ui/        só LÊ de systems (tactical_hud, caravan_bar, radial_menu)
content/   cenas do jogo (maps/, selftest/) — usa systems
data/      DADOS PLUGÁVEIS (.tres): stats/, abilities/, events/, maps/ — território humano (§7)
gyms/      sandbox de dev, ignorado no build — protótipo vira padrão só depois de aprovado
tests/     contract/ unit/ integration/ smoke/ e2e/ regression/ (GUT)
ci/        guardas mecânicos (abaixo)
.githooks/ pre-commit + pre-push (git config core.hooksPath .githooks)
docs/      GDD TDD STYLE WORKFLOW ADR/
```

**Fluxo de dependência (CI bloqueia violação):** `content → systems → addons` e `ui → systems`. `gyms` não pode ser referenciado fora de `gyms/`.

### ci/ — para que serve cada script

| Script | Função | Onde roda |
|---|---|---|
| `validate.sh` | pipeline fatiado <60s/etapa: import+check-only → gdlint → gdformat → gut contract+unit+integration | local/Replit a qualquer momento |
| `check-file-coverage.sh` | AVISO: função/sinal público sem teste de integração | pre-commit |
| `check-apk-content.sh` | FALHA se recurso crítico (mapa/abilities/stats) sumir do APK | CI + pós-export |
| `export-selftest.sh` | exporta binário Linux e roda o jogo DENTRO dele validando conteúdo; com xvfb gera screenshot | pre-push + CI |
| `build.sh` | 7 gates verdes → exporta APK local (caminhos codespace default — sobrescreva `ANDROID_HOME`/`JAVA_HOME`) | opcional |

---

## 3. Setup Genérico (qualquer plataforma)

```bash
# 1. Godot 4.7.2 binary (Linux x86_64) — URL pode mudar; confira o archive oficial
mkdir -p ~/.local/bin
curl -L -o /tmp/godot.zip \
  "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip"
unzip /tmp/godot.zip -d /tmp/godot && cp /tmp/godot/Godot_v4.7.2-stable_linux.x86_64 ~/.local/bin/godot
chmod +x ~/.local/bin/godot && godot --version   # deve imprimir 4.7.2-stable

# 2. Lint/formatação
pip install gdtoolkit==4.5.0    # gdlint + gdformat no PATH

# 3. Hooks do repositório (gates locais)
git config core.hooksPath .githooks

# 4. Modo visual do self-test (opcional, recomendado)
apt install xvfb libxcursor1 libxinerama1 libxrandr2 libxi6 libxkbcommon0 \
            libgl1-mesa-dri libglx-mesa0     # em nix/Replit: ver §4

# 5. Primeira importação + smoke do ambiente
godot --headless --import                       # gera .godot/
bash ci/validate.sh                             # tudo verde = ambiente pronto
```

**Smoke do ambiente (5 verificações):** `godot --version` = 4.7.2 · `gdlint --version` ok · `git config core.hooksPath` = .githooks · `bash ci/validate.sh` verde · `bash ci/export-selftest.sh` PASS.

---

## 4. Portando para Replit

### Diferenças vs Codespace

| Aspecto | Codespace | Replit |
|---|---|---|
| Pacotes | `apt install` (sudo) | `replit.nix` (nixpkgs, sem sudo) |
| Portas/servir arquivos | `http.server` + URL do codespace | **webview nativa** — ainda mais simples |
| Git hooks | `core.hooksPath .githooks` | igual |
| Godot | binário no PATH | binário no PATH (nixpkgs costuma atrasar versão — use download oficial do §3) |
| APK export local | SDK instalado (~5GB) | **NÃO faça** — use CI (§6) |

### Arquivos prontos neste repo

- **`replit.nix`** — deps nix (python3, git, xorg/xvfb, mesa). Godot entra via setup §3.
- **`.replit`** — workflows nomeados: `validate`, `test`, `selftest`, `serve-apk`, `run`.
  Se o schema do Replit mudar, recrie os mesmos comandos na UI de Workflows — os **comandos** são o contrato, não o formato do arquivo.

### Ordem de montagem no Replit

1. Importar do GitHub (`besterinha/Open_cod_jogo`)
2. `chmod +x ci/*.sh` (git preserva, mas confirme)
3. Executar setup §3 passos 1–3 e 5 (passo 4: instalar xvfb via nix se quiser modo visual)
4. Rodar workflow `validate` → verde
5. Workflow `serve-apk` → abrir webview → baixar `debug.apk` gerado pelo CI (§6)

---

## 5. O Loop Operacional (coração do projeto)

### 5.1 Pirâmide de testes — 50/25/25 (ADR-007)

| Camada | % aprox | O que pega |
|---|---|---|
| unit | 50% | lógica pura `RefCounted`/`new()` sem cena (resolver, stats, floodfill, validator) |
| integration | 25% | cenas reais + **input real** (ScreenTouch via `cam.unproject` → `_handle_tap`) com assert no **consumidor downstream** (§7b TDD) |
| contract+smoke+e2e+regression | 25% | DataValidator nos `.tres`, todas cenas carregam, slice vertical, cada bug vira `test_regression_bug_<id>` permanente |

Piso guardião 40/20/35 em `tests/contract/test_piramide_contract.gd` (conta funcs — não dá para "pular").

### 5.2 Gates (ordem exata, bloqueiam)

**pre-commit:** Tab/LF → gdlint (BLOQ) → gdformat (BLOQ) → check-only (BLOQ) → file-coverage (AVISO) → **tripwire DirAccess sem `# export-safe`** (BLOQ) → gut contract+unit (BLOQ)

**pre-push:** guardião anti-force/delete em main → gut integration → smoke+e2e → **export-selftest** (BLOQ — o pacote se prova dentro do binário exportado)

**CI (GitHub Actions):** job `validate` = tudo acima de novo; job `export-android` = APK + apk-content + self-test de pacote + tripwire.

### 5.3 Regras Export-Safe (resumo de TDD §4e — a classe de bug que já nos mordeu)

- `res://` **não tem pastas navegáveis dentro do APK**: listagem `DirAccess` só como extra; lista explícita `BASE_ABILITY_PATHS`/`BASE_EVENT_PATHS` via `ResourceLoader.exists` é obrigatória
- `ext_resource` de Resource custom pode não bindar / **conversão binária pode zerar propriedades**: cadeia L1 (.tscn) → L2 (load .tres) → **L3 const embutida em código**; validar CONTEÚDO, não só `!=null`
- `editor/export/convert_text_resources_to_binary=false` (project.godot) — não desligar
- Toda falha touch gera **toast visível** (prints não existem no device); botão morto proibido
- Label diagnóstica da arena (`0.3.x | terreno:L? muros:N ...`) é a **primeira linha de todo reporte de bug de device**

### 5.4 Fluxo de feature

```
ideia → protótipo em gyms/<dev>/ (isolado)
      → validar contrato (DataValidator)
      → mover p/ data/ ou systems/ (dados: aprovação humana — §7)
      → testes unit + integration (50/25/25) + regression se bug
      → docs atualizados no MESMO PR se mudou systems/ui (A5)
      → gates verdes → commit convencional (feat:/fix:/docs:/chore:)
```

---

## 6. APK & Device

- **No Replit: não instale o SDK.** O APK nasce no GitHub Actions (job `export-android` a cada push) — baixe o **artifact** da run em github.com/…/actions.
- Alternativa local (máquina com SDK): `bash ci/build.sh` (só exporta com 7 gates verdes).
- **Servir pro celular:** `python3 -m http.server 8000 --directory build` → abrir URL no Redmi → baixar `debug.apk`. No Replit, o workflow `serve-apk` + webview faz isso sem tunnel.
- **Checklist de device sempre começa pela label diagnóstica** da arena; depois: botões com nomes/custos, muros bloqueiam, espinho dá dano, IA sequencial, Passar Vez travado na vez da IA, cura em aliado/si.

---

## 7. Conduta de IA (client-agnóstico)

- `data/**/*.tres` é **território humano**: agente PROPÕE, humano aprova (no opencode é permissão `ask`; em outro client, equivalente — nunca contornar via bash)
- `tests/**` e `opencode.json`/`.opencode/` também são `ask`
- Nunca burlar permissão de edição via shell
- Commits convencionais `feat:/fix:/docs:/chore:`; docs na mesma PR que o código (A5)
- `docs/TDD.md#schema-ia` define o JSON que IA usa para gerar conteúdo — validator rejeita fora do schema

## 8. Referências

`AGENTS.md` (constituição) · `docs/GDD.md` (jogo) · `docs/TDD.md` (técnico + §4e export-safe + §7b input real + schema-ia) · `docs/STYLE.md` (código) · `docs/ADR/` (decisões)
