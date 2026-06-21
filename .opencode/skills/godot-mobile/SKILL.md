---
name: godot-mobile
description: Godot 4.5 mobile optimization for Android — GL Compatibility, touch input, safe areas, performance budgets
---

# Skill: Mobile (godot-mobile)

## When to Use
Use when configuring Godot for Android deployment, handling touch input,
managing safe areas for notches/nav bars, or optimizing for mobile
hardware budgets.

## Rendering Backend
- Project setting: `rendering/renderer/rendering_method = "gl_compatibility"`
- This is required for Android GLES 3.0 compatibility
- Disable MSAA in project settings (mobile GPU budget)
- Keep viewport size at native resolution (no scaling)

## Texture Compression
- Must use ETC2/ASTC: `textures/vram_compression/import_etc2_astc=true`
- Required for ARM64 Android devices
- All imported textures will be converted on import

## Touch Input
- Use `InputEventScreenTouch` for tap detection
- Use `InputEventScreenDrag` for drag/pan detection
- Min touch target: 48x48dp physical pixels
- Supply scaled area: `max(48, 48 * display_scale)`

## Safe Areas
- Use `DisplayServer.get_display_safe_area()` for notch/cutout insets
- On Android, get insets from the system window insets
- Adjust UI margins dynamically in `_ready()` or on resize

## Performance Budget
- Keep draw calls under 100 (mobile limit)
- Prefer `Sprite2D` over `Polygon2D` (GPU-friendly)
- Use texture atlases instead of individual textures
- Avoid real-time shadows, glow, and post-processing effects
- Use `set_process(false)` on off-screen nodes

## Build Target
- Min SDK: 24 (Android 7.0)
- Target SDK: 35 (Android 15)
- Architecture: arm64
