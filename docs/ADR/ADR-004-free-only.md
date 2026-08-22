# ADR-004: Somente Ferramentas Gratuitas (MIT/GPL/CC0)

**Data:** 22/08/2026 | **Status:** Aceito | **Restrição:** Usuário

## Contexto
Projeto deve usar apenas gratuito, sem asset pago, para manter automação IA viável e custo zero.

## Decisão
- Engine: Godot MIT, JDK Temurin GPL, Android SDK gratuito, GABE gratuito.
- Arte: Blender GPL, Krita/Libresprite (Aseprite pago descartado), Kenney/Poly Haven/AmbientCG CC0.
- MCPs: Coding-Solo/godot-mcp MIT, godot-docs MIT, context7 MIT. GoPeak MIT opcional. Godot MCP Pro pago descartado.
- Testes: GUT MIT, godot-validation-flow MIT.
- Harness: Godot3D-Harness MIT.

## Consequências
- Positivas: Custo zero, licenças permissivas, CI sem segredos pagos.
- Negativas: Sem suporte premium, alguns assets pagos de qualidade não usáveis, mas placeholders CC0 suprem MVP.

## Validação
Todos `LICENSE` verificados como MIT/GPL/CC0 antes de adicionar.
