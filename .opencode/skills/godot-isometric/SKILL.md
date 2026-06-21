---
name: godot-isometric
description: Isometric grid math for Godot 4.5 — coordinate conversion, _draw() rendering, z-index sorting, 4-dir movement
---

# Skill: Isometric Grid (godot-isometric)

## When to Use
Use when implementing isometric tile grids, coordinate conversion between
grid and screen space, rendering tiles with `_draw()`, or sorting entities
by depth for a Banner Saga-style view.

## Tile Constants
- Tile size: 32x16 pixels (2:1 diamond aspect ratio)
- Grid orientation: pointy-top (diamond shaped)
- Grid coordinate system: axial (col, row) where col+row determines depth

## Coordinate Conversion
- Grid to World:
  `world_x = (grid_x - grid_y) * tile_width * 0.5`
  `world_y = (grid_x + grid_y) * tile_height * 0.5`
- World to Grid (snap to nearest tile):
  `grid_x = floor((world_x / (tile_width * 0.5) + world_y / (tile_height * 0.5)) / 2)`
  `grid_y = floor((world_y / (tile_height * 0.5) - world_x / (tile_width * 0.5)) / 2)`

## Rendering (_draw)
- Use `draw_polygon()` for diamond tile shapes
- Tile vertices relative to center:
  `PackedVector2Array([Vector2(0, -h), Vector2(w, 0), Vector2(0, h), Vector2(-w, 0)])`
- Color tiles by state (walkable, highlighted, occupied)

## Z-Index Sorting
- Sort entities by `grid_x + grid_y` (ascending)
- Lower sum = drawn first (further back)
- Apply via `z_index` property or `canvas_item.set_z_index()`

## 4-Dir Movement
- Neighbors: (0, -1), (0, 1), (-1, 0), (1, 0)
- Manhattan distance: `abs(dx) + abs(dy)` — NOT Euclidean
- Movement cost per step: 1 (uniform grid)
