using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using Godot;

namespace ValidationFlow;

/// <summary>
/// Fluent helpers for <see cref="IVfValidate"/> / hook methods (mirror of GDScript VFValidate).
/// </summary>
public sealed class VfValidateBatch
{
	readonly List<string> _issues = new();

	public VfValidateBatch Required(object value, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckRequired(value, label, message));
		return this;
	}

	public VfValidateBatch ResPath(string path, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckResPath(path, label, message));
		return this;
	}

	public VfValidateBatch AssetsOnly(string path, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckAssetsOnly(path, label, message));
		return this;
	}

	public VfValidateBatch FileExists(string path, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckFileExists(path, label, message));
		return this;
	}

	public VfValidateBatch ScenePath(
		Node host,
		NodePath path,
		string label,
		string message = "",
		string expectedType = "")
	{
		Push(VfValidateHelpers.CheckScenePath(host, path, label, message, expectedType));
		return this;
	}

	public VfValidateBatch Min(double value, double min, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckMin(value, min, label, message));
		return this;
	}

	public VfValidateBatch Max(double value, double max, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckMax(value, max, label, message));
		return this;
	}

	public VfValidateBatch Range(double value, double min, double max, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckRange(value, min, max, label, message));
		return this;
	}

	public VfValidateBatch NotEmpty(object value, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckNotEmpty(value, label, message));
		return this;
	}

	public VfValidateBatch Regex(string text, string pattern, string label, string message = "")
	{
		Push(VfValidateHelpers.CheckRegex(text, pattern, label, message));
		return this;
	}

	public VfValidateBatch Custom(string message)
	{
		Push(message);
		return this;
	}

	public string[] Finish() => _issues.ToArray();

	void Push(string message)
	{
		if (!string.IsNullOrWhiteSpace(message))
		{
			_issues.Add(message.Trim());
		}
	}
}

/// <summary>Static one-shot checks (empty string = healthy).</summary>
public static class VfValidateHelpers
{
	public static VfValidateBatch Begin() => new();

	public static string CheckRequired(object value, string label, string message = "")
	{
		if (IsMissing(value))
		{
			return string.IsNullOrWhiteSpace(message)
				? $"Required '{label}' is missing or empty"
				: message;
		}

		return "";
	}

	public static string CheckResPath(string path, string label, string message = "")
	{
		if (string.IsNullOrWhiteSpace(path))
		{
			return "";
		}

		if (path.StartsWith("res://", StringComparison.Ordinal)
			|| path.StartsWith("user://", StringComparison.Ordinal)
			|| path.StartsWith("uid://", StringComparison.Ordinal))
		{
			return "";
		}

		return string.IsNullOrWhiteSpace(message)
			? $"'{label}' should be res://, user://, or uid://"
			: message;
	}

	public static string CheckAssetsOnly(string path, string label, string message = "")
	{
		if (string.IsNullOrWhiteSpace(path))
		{
			return "";
		}

		if (ResourceLoader.Exists(path) || FileAccess.FileExists(path))
		{
			return "";
		}

		return string.IsNullOrWhiteSpace(message)
			? $"'{label}' must reference an existing asset"
			: message;
	}

	public static string CheckFileExists(string path, string label, string message = "")
	{
		if (string.IsNullOrWhiteSpace(path))
		{
			return "";
		}

		if (FileAccess.FileExists(path) || ResourceLoader.Exists(path))
		{
			return "";
		}

		return string.IsNullOrWhiteSpace(message)
			? $"'{label}' file does not exist"
			: message;
	}

	public static string CheckScenePath(
		Node host,
		NodePath path,
		string label,
		string message = "",
		string expectedType = "")
	{
		if (path.IsEmpty)
		{
			return string.IsNullOrWhiteSpace(message)
				? $"NodePath '{label}' is empty"
				: message;
		}

		if (host == null)
		{
			return $"'{label}': host node is null";
		}

		var node = host.GetNodeOrNull(path);
		if (node == null)
		{
			return string.IsNullOrWhiteSpace(message)
				? $"NodePath '{label}' does not resolve: {path}"
				: message;
		}

		if (!string.IsNullOrWhiteSpace(expectedType) && !node.IsClass(expectedType))
		{
			return string.IsNullOrWhiteSpace(message)
				? $"'{label}' must be {expectedType} (got {node.GetClass()})"
				: message;
		}

		return "";
	}

	public static string CheckMin(double value, double min, string label, string message = "")
	{
		if (value < min)
		{
			return string.IsNullOrWhiteSpace(message)
				? $"'{label}' must be >= {min} (got {value})"
				: message;
		}

		return "";
	}

	public static string CheckMax(double value, double max, string label, string message = "")
	{
		if (value > max)
		{
			return string.IsNullOrWhiteSpace(message)
				? $"'{label}' must be <= {max} (got {value})"
				: message;
		}

		return "";
	}

	public static string CheckRange(double value, double min, double max, string label, string message = "")
	{
		if (value < min || value > max)
		{
			return string.IsNullOrWhiteSpace(message)
				? $"'{label}' must be in [{min}, {max}] (got {value})"
				: message;
		}

		return "";
	}

	public static string CheckNotEmpty(object value, string label, string message = "")
	{
		if (IsEmptyCollection(value))
		{
			return string.IsNullOrWhiteSpace(message)
				? $"'{label}' must not be empty"
				: message;
		}

		return "";
	}

	public static string CheckRegex(string text, string pattern, string label, string message = "")
	{
		if (string.IsNullOrEmpty(text) || string.IsNullOrEmpty(pattern))
		{
			return "";
		}

		try
		{
			if (!Regex.IsMatch(text, pattern))
			{
				return string.IsNullOrWhiteSpace(message)
					? $"'{label}' does not match /{pattern}/"
					: message;
			}
		}
		catch (ArgumentException)
		{
			return $"Invalid regex for '{label}'";
		}

		return "";
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

		if (value is Godot.Collections.Array godotArr)
		{
			return godotArr.Count == 0;
		}

		if (value is System.Collections.ICollection col)
		{
			return col.Count == 0;
		}

		var countProp = value.GetType().GetProperty("Count");
		if (countProp != null && countProp.PropertyType == typeof(int))
		{
			try
			{
				return (int)countProp.GetValue(value)! == 0;
			}
			catch
			{
				return false;
			}
		}

		return false;
	}
}
