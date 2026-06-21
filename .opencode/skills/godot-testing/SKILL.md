---
name: godot-testing
description: gdUnit4 testing patterns for Godot 4.5 — GDScript test structure, assertions, test doubles, and CLI execution
---

# Skill: Testing (godot-testing)

## When to Use
Use when writing or running gdUnit4 tests, validating scene integrity,
checking script references resolve, or verifying UID uniqueness.

## Test Runner (CLI)
```
godot --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a res://tests --ignoreHeadlessMode -c
```

## Test File Conventions
- Place tests in `res://tests/` directory
- Test scripts named `test_<system>.gd`
- Each test extends `GdUnitTestSuite`
- One test file per system under test

## Test Structure
```gdscript
extends GdUnitTestSuite

# Test an individual function
func test_grid_coordinate_conversion() -> void:
    var grid := GridSystem.new()
    var world: Vector2 = grid.grid_to_world(Vector2i(2, 2))
    assert_vector2(world).is_equal(Vector2(64.0, 128.0))
```

## Assertions Reference
- `assert_bool(value)`, `assert_int(value)`, `assert_float(value)`
- `assert_str(value)`, `assert_vector2(value)`, `assert_vector3(value)`
- `assert_array(value)`, `assert_dict(value)`, `assert_object(value)`
- `assert_not_yet_implemented()` for planned tests

## Scene Validation (via MCP)
- Use `godot_get_scene_tree` to inspect `tscn` structure
- Verify node paths, script attachments, signal connections
- Check UID uniqueness:
  ```
  rg -o 'uid://[a-z0-9]+' res:// --include '*.tscn' \
    --include '*.uid' | sort | uniq -d
  ```

## Test Doubles
- Use `auto_free()` for temporary nodes that need cleanup
- Stub method returns with `when(obj).method(args).then_return(val)`
- Verify interactions with `verify(obj).method(args)`
