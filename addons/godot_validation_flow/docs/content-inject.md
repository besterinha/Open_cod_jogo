# Content inject cookbook (Odin-like)

## GDScript — `_vf_validate()` + `VFValidate`

```gdscript
@export var title: String
@export var target: NodePath
@export var icon_path: String
@export var level: int

func _vf_validate() -> PackedStringArray:
	return VFValidate.begin() \
		.required(title, "title") \
		.node_path(self, target, "target") \                 # exists under self
		.node_path(self, target, "target", "", "Node2D") \   # + must be Node2D
		.assets_only(icon_path, "icon_path") \
		.range_value(level, 1, 99, "level") \
		.regex(code, "^[a-z_]+$", "code") \
		.finish()
```

| Helper | Checks |
|--------|--------|
| `required` | Non-empty string / NodePath / object |
| `node_path(host, path, label, msg="", type="")` | Non-empty + resolves (+ optional `is_class`) |
| `assets_only` / `file_exists` / `res_path` | Paths |
| `min_value` / `max_value` / `range_value` | Numbers |
| `not_empty` / `min_length` / `max_length` | Arrays / strings |
| `regex` / `one_of` / `custom` | Patterns / allow-list / free text |

One-shot: `VFValidate.check_required(x, "x")` → `""` if healthy.

Headless tip: `const _VF := preload("res://addons/godot_validation_flow/core/vf_validate.gd")`.

## C# — attributes (preferred)

```csharp
[Export, VfRequired, VfScenePath]              // empty → one Required message (deduped)
public NodePath Target { get; set; }

[Export, VfScenePath("", "CharacterBody2D")] // must resolve + class
public NodePath Body { get; set; }

[Export, VfRange(1, 10)]
public int Level { get; set; }

[Export, VfAssetsOnly]   // prefer over stacking FileExists
public string Icon { get; set; }

[Export, VfNotEmpty]     // prefer over stacking MinLength(1)
public Array<string> Tags { get; set; }

[Export, VfValidateMethod(nameof(CheckTitle))]
public string Title { get; set; }
```

Bridge **dedupes** common stacks: Required+ScenePath empty, NotEmpty+MinLength, AssetsOnly+FileExists, Range vs Min/Max.

| Attribute | Role |
|-----------|------|
| `VfRequired` | Non-empty |
| `VfResPath` | res/user/uid prefix |
| `VfMin` / `VfMax` / `VfRange` | Numbers (validation only — not Inspector slider) |
| `VfAssetsOnly` / `VfFileExists` | Asset on disk |
| `VfNotEmpty` / `VfMinLength` / `VfMaxLength` | Collections / strings |
| `VfRegex` | Pattern |
| `VfScenePath(msg, expectedType)` | NodePath resolves (+ class) |
| `VfValidateMethod` | Custom method |

Helpers: `VfValidateHelpers.Begin()…Finish()` inside `IVfValidate` / `_VfValidate`.
