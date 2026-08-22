using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Text.RegularExpressions;
using Godot;

namespace ValidationFlow;

/// <summary>
/// Optional content-side hook (Odin-like inject). Prefer this in C# over snake_case.
/// GDScript equivalent: <c>_vf_validate() -&gt; PackedStringArray</c> + <see cref="VFValidate"/> helpers.
/// </summary>
public interface IVfValidate
{
	/// <summary>Return human-readable issues; empty = healthy.</summary>
	string[] VfValidate();
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfRequiredAttribute : Attribute
{
	public string Message { get; }

	public VfRequiredAttribute(string message = "")
	{
		Message = message ?? "";
	}
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfResPathAttribute : Attribute
{
	public string Message { get; }

	public VfResPathAttribute(string message = "")
	{
		Message = message ?? "";
	}
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfMinAttribute : Attribute
{
	public double Min { get; }
	public string Message { get; }

	public VfMinAttribute(double min, string message = "")
	{
		Min = min;
		Message = message ?? "";
	}
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfMaxAttribute : Attribute
{
	public double Max { get; }
	public string Message { get; }

	public VfMaxAttribute(double max, string message = "")
	{
		Max = max;
		Message = message ?? "";
	}
}

/// <summary>Inclusive numeric range (Odin MinValue+MaxValue / Range).</summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfRangeAttribute : Attribute
{
	public double Min { get; }
	public double Max { get; }
	public string Message { get; }

	public VfRangeAttribute(double min, double max, string message = "")
	{
		Min = min;
		Max = max;
		Message = message ?? "";
	}
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfAssetsOnlyAttribute : Attribute
{
	public string Message { get; }

	public VfAssetsOnlyAttribute(string message = "")
	{
		Message = message ?? "";
	}
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfNotEmptyAttribute : Attribute
{
	public string Message { get; }

	public VfNotEmptyAttribute(string message = "")
	{
		Message = message ?? "";
	}
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfMinLengthAttribute : Attribute
{
	public int Min { get; }
	public string Message { get; }

	public VfMinLengthAttribute(int min, string message = "")
	{
		Min = min;
		Message = message ?? "";
	}
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfMaxLengthAttribute : Attribute
{
	public int Max { get; }
	public string Message { get; }

	public VfMaxLengthAttribute(int max, string message = "")
	{
		Max = max;
		Message = message ?? "";
	}
}

/// <summary>String must match a .NET regex pattern.</summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfRegexAttribute : Attribute
{
	public string Pattern { get; }
	public string Message { get; }

	public VfRegexAttribute(string pattern, string message = "")
	{
		Pattern = pattern ?? "";
		Message = message ?? "";
	}
}

/// <summary>NodePath must resolve on the owning Node (scene-local). Optional class filter.</summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfScenePathAttribute : Attribute
{
	public string Message { get; }
	/// <summary>Godot class name, e.g. <c>Node2D</c> / <c>CharacterBody3D</c>.</summary>
	public string ExpectedType { get; }

	public VfScenePathAttribute(string message = "", string expectedType = "")
	{
		Message = message ?? "";
		ExpectedType = expectedType ?? "";
	}
}

/// <summary>String path must exist on disk / ResourceLoader.</summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field)]
public sealed class VfFileExistsAttribute : Attribute
{
	public string Message { get; }

	public VfFileExistsAttribute(string message = "")
	{
		Message = message ?? "";
	}
}

/// <summary>
/// Call a method on the object. Supported returns: bool (false=fail), string (non-empty=fail), string[].
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field, AllowMultiple = true)]
public sealed class VfValidateMethodAttribute : Attribute
{
	public string MethodName { get; }
	public string Message { get; }

	public VfValidateMethodAttribute(string methodName, string message = "")
	{
		MethodName = methodName ?? "";
		Message = message ?? "";
	}
}
