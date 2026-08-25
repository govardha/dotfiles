#!/usr/bin/env python3
"""
Build consolidated settings.json for each profile by merging:
  1. common-settings.src.json (shared by all)
  2. base-settings.src.json (base hooks, inherited by all)
  3. {profile}-settings.src.json (profile-specific additions)
  4. approved commands (from YAML)

Source files: *-settings.src.json
Output files: *-settings.json (consolidated)

Usage:
  python3 build-settings.py
"""

import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Install with: pip3 install pyyaml", file=sys.stderr)
    sys.exit(1)

SETTINGS_DIR = Path(__file__).parent / "settings"
CLAUDE_DIR = Path(__file__).parent

PROFILES = {
    "base": {"settings": "base-settings", "profile": "base"},
    "sysops": {"settings": "sysops-settings", "profile": "sysops"},
    "infra-ops": {"settings": "infra-ops-settings", "profile": "infra-ops"},
    "k8s-devops": {"settings": "k8s-devops-settings", "profile": "k8s-devops"},
    "aws-devops": {"settings": "aws-devops-settings", "profile": "aws-devops"},
    "java-dev": {"settings": "base-settings", "profile": "base"},
}


def load_approved_commands(profile_name):
    """Load common + profile-specific approved commands from YAML files."""
    approved = []

    common_file = SETTINGS_DIR / "approved-commands.yaml"
    if common_file.exists():
        with open(common_file) as f:
            common_data = yaml.safe_load(f) or {}
            approved.extend(common_data.get("approved_commands", []))

    profile_file = SETTINGS_DIR / f"approved-commands-{profile_name}.yaml"
    if profile_file.exists():
        with open(profile_file) as f:
            profile_data = yaml.safe_load(f) or {}
            approved.extend(profile_data.get("approved_commands", []))

    return approved


def merge_settings(common, profile, approved_commands):
    """Merge common settings with profile-specific settings and approved commands."""
    result = {
        "hooks": {
            "UserPromptSubmit": [],
            "PreToolUse": [],
            "PostToolUse": [],
            "SessionStart": [],
        }
    }

    # Merge UserPromptSubmit
    result["hooks"]["UserPromptSubmit"] = (
        common.get("hooks", {}).get("UserPromptSubmit", [])
        + profile.get("hooks", {}).get("UserPromptSubmit", [])
    )

    # Merge PreToolUse with deduplication by matcher
    common_pre = common.get("hooks", {}).get("PreToolUse", [])
    profile_pre = profile.get("hooks", {}).get("PreToolUse", [])
    pre_by_matcher = {}

    for hook in common_pre + profile_pre:
        matcher = hook.get("matcher", "")
        if matcher not in pre_by_matcher:
            pre_by_matcher[matcher] = {"matcher": matcher, "hooks": []}
        pre_by_matcher[matcher]["hooks"].extend(hook.get("hooks", []))

    result["hooks"]["PreToolUse"] = list(pre_by_matcher.values())

    # Merge PostToolUse
    result["hooks"]["PostToolUse"] = (
        common.get("hooks", {}).get("PostToolUse", [])
        + profile.get("hooks", {}).get("PostToolUse", [])
    )

    # Merge SessionStart
    result["hooks"]["SessionStart"] = (
        common.get("hooks", {}).get("SessionStart", [])
        + profile.get("hooks", {}).get("SessionStart", [])
    )

    # Copy other settings (e.g., autoCompactThreshold)
    for key in common:
        if key != "hooks":
            result[key] = profile.get(key, common.get(key))
    for key in profile:
        if key != "hooks":
            result[key] = profile.get(key, result.get(key))

    # Add permissions.allowlist from approved commands
    if approved_commands:
        result["permissions"] = {
            "allowlist": approved_commands,
        }

    return result


def main():
    if not SETTINGS_DIR.exists():
        print(f"Error: {SETTINGS_DIR} not found", file=sys.stderr)
        return 1

    common_file = SETTINGS_DIR / "common-settings.src.json"
    if not common_file.exists():
        print(f"Error: {common_file} not found", file=sys.stderr)
        return 1

    with open(common_file) as f:
        common = json.load(f)

    base_src = SETTINGS_DIR / "base-settings.src.json"
    base_hooks = {}
    if base_src.exists():
        with open(base_src) as f:
            base_hooks = json.load(f)

    for profile_name, profile_config in PROFILES.items():
        profile_settings = profile_config["settings"]
        profile_key = profile_config["profile"]

        profile_src = SETTINGS_DIR / f"{profile_settings}.src.json"
        if not profile_src.exists():
            print(f"Warning: {profile_src} not found, skipping {profile_name}", file=sys.stderr)
            continue

        with open(profile_src) as f:
            profile = json.load(f)

        # Merge base-settings hooks into every profile (additive)
        if base_hooks:
            profile = merge_settings(base_hooks, profile, [])

        approved = load_approved_commands(profile_key)
        merged = merge_settings(common, profile, approved)

        output_path = SETTINGS_DIR / f"{profile_settings}.json"
        with open(output_path, "w") as f:
            json.dump(merged, f, indent=2)
            f.write("\n")

        print(f"✓ Built {profile_name}: {output_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
