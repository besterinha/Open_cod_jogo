# ADR-001: Godot 4.7.2-stable Standard

**Data:** 22/08/2026 | **Status:** Aceito | **Decisor:** besterinha + pesquisa

## Contexto
Escolher engine para TRPG 2.5D Android plugável com automação IA. Candidato inicial Godot 4.4, mas pesquisa mostrou defasagem.

## Decisão
Usar **Godot 4.7.2-stable Standard (GDScript, Renderer Mobile)** — latest stable em 18/08/2026 (`github.com/godotengine/godot/releases/tag/4.7.2-stable`, 57 patches).

## Alternativas Consideradas
- Unity: asset store rico, mas build pesado, licença, Addressables verboso para plugável.
- Unreal: overkill 2.5D tático.
- Godot 4.4/4.4.1: estável mas sem GABE, sem 16KB pages (Android 15), sem VirtualJoystick, bug laggier #105313.

## Consequências
- **Positivas:** GABE estável (export APK/AAB até pelo celular), 16KB pages obrigatório Play Store, VirtualJoystick nativo, HDR, Jolt default, Mobile renderer otimizado, manutenção compatível 4.x.
- **Negativas:** Plugins antigos 4.4 podem precisar update, mas GUT 9.7.1 já suporta 4.7.2.
- **Tradeoff:** Quebra zero para conteúdo data-driven, ganho Android crítico.

## Validação
`godotengine.org/download/archive/4.7.2-stable` + `docs.godotengine.org 4.7 migration guide` confirmam compatibilidade.

## Referências
- https://github.com/godotengine/godot/releases/tag/4.7.2-stable
- https://godotengine.org/releases/4.7/
