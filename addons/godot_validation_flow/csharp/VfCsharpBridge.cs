using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Text.RegularExpressions;
using Godot;

namespace ValidationFlow;

/// <summary>
/// C# facade called from GDScript rules. Host plugin stays GDScript (csharp-opt-in).
/// </summary>
[GlobalClass]
public partial class VfCsharpBridge : RefCounted
{
	static readonly string[] HookMethodNames =
	{
		"_vf_validate",
		"_VfValidate",
		"VfValidate",
		"vf_validate",
	};

	public string[] CollectNodeIssues(Node node, bool includeHooks, bool includeAttributes)
	{
		var messages = new List<string>();
		if (node == null)
		{
			return Array.Empty<string>();
		}

		if (includeHooks)
		{
			CollectHooks(node, messages);
		}

		if (includeAttributes)
		{
			CollectAttributes(node, messages);
		}

		return messages.ToArray();
	}

	void CollectHooks(GodotObject obj, List<string> messages)
	{
		if (obj is IVfValidate validate)
		{
			AppendAll(messages, validate.VfValidate());
			return;
		}

		foreach (var name in HookMethodNames)
		{
			if (!obj.HasMethod(name))
			{
				continue;
			}

			Variant result = obj.Call(name);
			AppendVariant(messages, result);
			return;
		}
	}

	void CollectAttributes(GodotObject obj, List<string> messages)
	{
		var type = obj.GetType();
		const BindingFlags flags = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;

		foreach (var prop in type.GetProperties(flags))
		{
			if (!HasExport(prop))
			{
				continue;
			}

			object value;
			try
			{
				value = prop.GetValue(obj);
			}
			catch
			{
				continue;
			}

			ValidateMember(obj, prop.Name, prop, value, messages);
		}

		foreach (var field in type.GetFields(flags))
		{
			if (!HasExport(field))
			{
				continue;
			}

			object value;
			try
			{
				value = field.GetValue(obj);
			}
			catch
			{
				continue;
			}

			ValidateMember(obj, field.Name, field, value, messages);
		}
	}

	static bool HasExport(MemberInfo member)
	{
		return member.GetCustomAttribute<ExportAttribute>() != null;
	}

	static void ValidateMember(
		GodotObject obj,
		string name,
		MemberInfo member,
		object value,
		List<string> messages)
	{
		var before = messages.Count;
		var requiredFired = false;
		var notEmptyFired = false;
		var assetsFired = false;
		var rangeFired = false;

		var required = member.GetCustomAttribute<VfRequiredAttribute>();
		if (required != null && IsMissing(value))
		{
			AddMsg(messages, string.IsNullOrWhiteSpace(required.Message)
				? $"Required export '{name}' is missing or empty"
				: required.Message);
			requiredFired = true;
		}

		var resPath = member.GetCustomAttribute<VfResPathAttribute>();
		if (resPath != null && value is string path && !string.IsNullOrWhiteSpace(path))
		{
			if (!(path.StartsWith("res://", StringComparison.Ordinal)
				|| path.StartsWith("user://", StringComparison.Ordinal)
				|| path.StartsWith("uid://", StringComparison.Ordinal)))
			{
				AddMsg(messages, string.IsNullOrWhiteSpace(resPath.Message)
					? $"Export '{name}' should be a res://, user://, or uid:// path"
					: resPath.Message);
			}
		}

		var rangeAttr = member.GetCustomAttribute<VfRangeAttribute>();
		if (rangeAttr != null && TryGetNumber(value, out var nRange)
			&& (nRange < rangeAttr.Min || nRange > rangeAttr.Max))
		{
			AddMsg(messages, string.IsNullOrWhiteSpace(rangeAttr.Message)
				? $"Export '{name}' must be in [{rangeAttr.Min}, {rangeAttr.Max}] (got {nRange})"
				: rangeAttr.Message);
			rangeFired = true;
		}

		// Skip Min/Max when Range already covered the same field.
		if (!rangeFired)
		{
			var minAttr = member.GetCustomAttribute<VfMinAttribute>();
			if (minAttr != null && TryGetNumber(value, out var nMin) && nMin < minAttr.Min)
			{
				AddMsg(messages, string.IsNullOrWhiteSpace(minAttr.Message)
					? $"Export '{name}' must be >= {minAttr.Min} (got {nMin})"
					: minAttr.Message);
			}

			var maxAttr = member.GetCustomAttribute<VfMaxAttribute>();
			if (maxAttr != null && TryGetNumber(value, out var nMax) && nMax > maxAttr.Max)
			{
				AddMsg(messages, string.IsNullOrWhiteSpace(maxAttr.Message)
					? $"Export '{name}' must be <= {maxAttr.Max} (got {nMax})"
					: maxAttr.Message);
			}
		}

		var notEmpty = member.GetCustomAttribute<VfNotEmptyAttribute>();
		if (notEmpty != null && IsEmptyCollection(value))
		{
			AddMsg(messages, string.IsNullOrWhiteSpace(notEmpty.Message)
				? $"Export '{name}' must not be empty"
				: notEmpty.Message);
			notEmptyFired = true;
		}

		var minLen = member.GetCustomAttribute<VfMinLengthAttribute>();
		if (minLen != null && !notEmptyFired)
		{
			var len = LengthOf(value);
			if (len >= 0 && len < minLen.Min)
			{
				AddMsg(messages, string.IsNullOrWhiteSpace(minLen.Message)
					? $"Export '{name}' length must be >= {minLen.Min} (got {len})"
					: minLen.Message);
			}
		}

		var maxLen = member.GetCustomAttribute<VfMaxLengthAttribute>();
		if (maxLen != null)
		{
			var len = LengthOf(value);
			if (len >= 0 && len > maxLen.Max)
			{
				AddMsg(messages, string.IsNullOrWhiteSpace(maxLen.Message)
					? $"Export '{name}' length must be <= {maxLen.Max} (got {len})"
					: maxLen.Message);
			}
		}

		var regexAttr = member.GetCustomAttribute<VfRegexAttribute>();
		if (regexAttr != null && value is string text && !string.IsNullOrEmpty(text)
			&& !string.IsNullOrEmpty(regexAttr.Pattern))
		{
			try
			{
				if (!Regex.IsMatch(text, regexAttr.Pattern))
				{
					AddMsg(messages, string.IsNullOrWhiteSpace(regexAttr.Message)
						? $"Export '{name}' does not match /{regexAttr.Pattern}/"
						: regexAttr.Message);
				}
			}
			catch (ArgumentException)
			{
				AddMsg(messages, $"Invalid regex on export '{name}'");
			}
		}

		var scenePath = member.GetCustomAttribute<VfScenePathAttribute>();
		if (scenePath != null && obj is Node host && value is NodePath np)
		{
			if (np.IsEmpty)
			{
				// Required already said "missing" — don't double-fire empty path.
				if (!requiredFired)
				{
					AddMsg(messages, string.IsNullOrWhiteSpace(scenePath.Message)
						? $"Export '{name}' NodePath is empty"
						: scenePath.Message);
				}
			}
			else
			{
				var node = host.GetNodeOrNull(np);
				if (node == null)
				{
					AddMsg(messages, string.IsNullOrWhiteSpace(scenePath.Message)
						? $"Export '{name}' NodePath does not resolve: {np}"
						: scenePath.Message);
				}
				else if (!string.IsNullOrWhiteSpace(scenePath.ExpectedType)
					&& !node.IsClass(scenePath.ExpectedType))
				{
					AddMsg(messages, string.IsNullOrWhiteSpace(scenePath.Message)
						? $"Export '{name}' must be {scenePath.ExpectedType} (got {node.GetClass()})"
						: scenePath.Message);
				}
			}
		}

		var assetsOnly = member.GetCustomAttribute<VfAssetsOnlyAttribute>();
		if (assetsOnly != null && !IsMissing(value) && !AssetExists(value))
		{
			AddMsg(messages, string.IsNullOrWhiteSpace(assetsOnly.Message)
				? $"Export '{name}' must reference an existing asset"
				: assetsOnly.Message);
			assetsFired = true;
		}

		var fileExists = member.GetCustomAttribute<VfFileExistsAttribute>();
		if (fileExists != null && !assetsFired
			&& value is string filePath && !string.IsNullOrWhiteSpace(filePath))
		{
			if (!(FileAccess.FileExists(filePath) || ResourceLoader.Exists(filePath)))
			{
				AddMsg(messages, string.IsNullOrWhiteSpace(fileExists.Message)
					? $"Export '{name}' file does not exist"
					: fileExists.Message);
			}
		}

		foreach (var methodAttr in member.GetCustomAttributes<VfValidateMethodAttribute>())
		{
			RunValidateMethod(obj, name, methodAttr, messages);
		}

		_ = before; // keep for future per-member metrics
	}

	static void AddMsg(List<string> messages, string msg)
	{
		if (string.IsNullOrWhiteSpace(msg))
		{
			return;
		}

		foreach (var existing in messages)
		{
			if (string.Equals(existing, msg, StringComparison.Ordinal))
			{
				return;
			}
		}

		messages.Add(msg);
	}

	static void RunValidateMethod(
		GodotObject obj,
		string memberName,
		VfValidateMethodAttribute attr,
		List<string> messages)
	{
		if (string.IsNullOrWhiteSpace(attr.MethodName) || !obj.HasMethod(attr.MethodName))
		{
			messages.Add($"VfValidateMethod '{attr.MethodName}' missing for '{memberName}'");
			return;
		}

		Variant result = obj.Call(attr.MethodName);
		switch (result.VariantType)
		{
			case Variant.Type.Bool:
				if (!result.AsBool())
				{
					messages.Add(string.IsNullOrWhiteSpace(attr.Message)
						? $"Export '{memberName}' failed {attr.MethodName}()"
						: attr.Message);
				}

				return;
			case Variant.Type.String:
			{
				var text = result.AsString();
				if (!string.IsNullOrWhiteSpace(text))
				{
					messages.Add(text);
				}

				return;
			}
			case Variant.Type.PackedStringArray:
				AppendAll(messages, result.AsStringArray());
				return;
			default:
				return;
		}
	}

	static bool TryGetNumber(object value, out double number)
	{
		number = 0;
		switch (value)
		{
			case int i:
				number = i;
				return true;
			case long l:
				number = l;
				return true;
			case float f:
				number = f;
				return true;
			case double d:
				number = d;
				return true;
			default:
				return false;
		}
	}

	static int LengthOf(object value)
	{
		switch (value)
		{
			case null:
				return 0;
			case string s:
				return s.Length;
			case Godot.Collections.Array ga:
				return ga.Count;
			case ICollection col:
				return col.Count;
			default:
			{
				var countProp = value.GetType().GetProperty("Count");
				if (countProp != null && countProp.PropertyType == typeof(int))
				{
					try
					{
						return (int)countProp.GetValue(value)!;
					}
					catch
					{
						return -1;
					}
				}

				return -1;
			}
		}
	}

	static bool IsEmptyCollection(object value)
	{
		if (value == null)
		{
			return true;
		}

		if (value is string s)
		{
			return string.IsNullOrWhiteSpace(s);
		}

		var len = LengthOf(value);
		return len == 0;
	}

	static bool AssetExists(object value)
	{
		switch (value)
		{
			case null:
				return false;
			case Resource res:
				var path = res.ResourcePath;
				return !string.IsNullOrWhiteSpace(path) && ResourceLoader.Exists(path);
			case string pathStr when !string.IsNullOrWhiteSpace(pathStr):
				return ResourceLoader.Exists(pathStr);
			case NodePath np when !np.IsEmpty:
				return true;
			case GodotObject go:
				return GodotObject.IsInstanceValid(go);
			default:
				return true;
		}
	}

	static bool IsMissing(object value)
	{
		if (value == null)
		{
			return true;
		}

		if (value is string s)
		{
			return string.IsNullOrWhiteSpace(s);
		}

		if (value is NodePath np)
		{
			return np.IsEmpty;
		}

		if (value is StringName sn)
		{
			return sn.IsEmpty;
		}

		if (value is GodotObject go)
		{
			return !GodotObject.IsInstanceValid(go);
		}

		return false;
	}

	static void AppendVariant(List<string> messages, Variant result)
	{
		switch (result.VariantType)
		{
			case Variant.Type.Nil:
				return;
			case Variant.Type.String:
				AppendAll(messages, new[] { result.AsString() });
				return;
			case Variant.Type.PackedStringArray:
				AppendAll(messages, result.AsStringArray());
				return;
			case Variant.Type.Array:
			{
				var arr = result.AsGodotArray();
				foreach (var item in arr)
				{
					var text = item.AsString();
					if (!string.IsNullOrWhiteSpace(text))
					{
						messages.Add(text);
					}
				}

				return;
			}
			default:
				return;
		}
	}

	static void AppendAll(List<string> messages, IEnumerable<string> items)
	{
		if (items == null)
		{
			return;
		}

		foreach (var item in items)
		{
			if (!string.IsNullOrWhiteSpace(item))
			{
				messages.Add(item);
			}
		}
	}
}
