@tool
class_name VFProjectValidationConfig
extends Resource

## Project-level validation policy — **data only**. No rule scripts.
## Edit in Inspector, or assign under Project Settings → godot_validation_flow/config.
## Create New Resource → search "ProjectValidation" / "VFProjectValidationConfig".

@export_group("Profile (scan scope)")
## What to scan — Odin-like profile. Create via VFValidationProfile resource.
@export var active_profile: VFValidationProfile

@export_group("Built-in rules")
@export var missing_dependencies: bool = true
@export var broken_uid: bool = true
@export var duplicate_uid: bool = true
@export var uid_mismatch: bool = true
@export var export_integrity: bool = true
@export var export_coverage: bool = true
@export var orphan_assets: bool = true
@export var duplicate_basename: bool = true
@export var autoload_paths: bool = true
@export var empty_node_paths: bool = true
@export var configuration_warnings: bool = true
@export var script_hooks: bool = true

@export_group("Filename substring")
@export var filename_substring_enabled: bool = true
@export var filename_substring_text: String = "broken_"
@export var filename_substring_extensions: PackedStringArray = PackedStringArray(["tscn"])
@export_enum("Info", "Warning", "Error") var filename_substring_severity: int = 0

@export_group("Script hooks (content inject)")
## Nodes may implement `_vf_validate()` (GDScript) or `_VfValidate` / IVfValidate (C#).
@export_enum("Info", "Warning", "Error") var script_hooks_severity: int = 1
## Scan C# Odin-like attrs: Required/Min/Max/Range/AssetsOnly/NotEmpty/MinLength/MaxLength/Regex/ScenePath/FileExists/ValidateMethod.
@export var csharp_attributes: bool = true

@export_group("Workflow gates (Odin-like)")
## EditorPlugin._build — return false blocks Play.
@export var block_play_on_issues: bool = false
## 0=Any issue, 1=Warning+, 2=Error only
@export_enum("Any issue", "Warning+", "Error only") var play_gate_severity: int = 1
## Fail/noise export when issues meet threshold (export plugin).
@export var block_export_on_issues: bool = false
@export_enum("Any issue", "Warning+", "Error only") var export_gate_severity: int = 1
## Write JSON after Validate / CLI (CI artifact).
@export var write_json_report: bool = true
@export var json_report_path: String = "res://.godot/validation_report.json"
## Also write a human-readable HTML sibling report (same folder, .html).
@export var write_html_report: bool = true
