#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROOT_ASSIGNMENT = ROOT / "policy/assignments/root-mg-assignment.json"
HUB_ASSIGNMENTS = [
    ROOT / "policy/assignments/hub-east-assignment.json",
    ROOT / "policy/assignments/hub-west-assignment.json",
    ROOT / "policy/assignments/hub-central-assignment.json",
]
EXPECTED_NGS = {"prod-spokes", "nonprod-spokes", "dr-spokes"}


def read_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def root_allowed_tag_values(path: Path) -> set[str]:
    data = read_json(path)
    for resource in data.get("resources", []):
        allowed = (
            resource.get("properties", {})
            .get("parameters", {})
            .get("allowedTagValues", {})
            .get("value")
        )
        if isinstance(allowed, list):
            return {str(value) for value in allowed}
    raise ValueError(
        f"Could not find resources[].properties.parameters.allowedTagValues.value in {path}"
    )


def hub_mappings(path: Path) -> tuple[set[str], set[str]]:
    data = read_json(path)
    mappings = (
        data.get("parameters", {})
        .get("ngMappings", {})
        .get("defaultValue")
    )
    if not isinstance(mappings, list):
        raise ValueError(f"Could not find parameters.ngMappings.defaultValue in {path}")

    tag_values: set[str] = set()
    ng_names: set[str] = set()

    for entry in mappings:
        if not isinstance(entry, dict) or "ng" not in entry or "tagValue" not in entry:
            raise ValueError(f"Invalid ngMappings entry in {path}: {entry!r}")
        ng_names.add(str(entry["ng"]))
        tag_values.add(str(entry["tagValue"]))

    return tag_values, ng_names


def main() -> int:
    try:
        allowed_tag_values = root_allowed_tag_values(ROOT_ASSIGNMENT)
        hub_tag_values: set[str] = set()
        hub_ng_names: set[str] = set()

        for assignment in HUB_ASSIGNMENTS:
            tag_values, ng_names = hub_mappings(assignment)
            hub_tag_values.update(tag_values)
            hub_ng_names.update(ng_names)
    except (OSError, json.JSONDecodeError, ValueError) as err:
        print(f"ERROR: {err}")
        return 1

    unexpected_ngs = sorted(hub_ng_names - EXPECTED_NGS)
    if unexpected_ngs:
        print(
            "ERROR: unexpected ngMappings[].ng value(s): "
            f"{', '.join(unexpected_ngs)}. "
            f"Expected only: {', '.join(sorted(EXPECTED_NGS))}"
        )
        return 1

    symmetric_diff = sorted(allowed_tag_values ^ hub_tag_values)
    if symmetric_diff:
        print(
            "ERROR: root allowedTagValues and hub ngMappings tagValue sets differ. "
            f"Symmetric difference ({len(symmetric_diff)}): {', '.join(symmetric_diff)}"
        )
        return 1

    print(f"OK: {len(allowed_tag_values)} tag values consistent across root + 3 hubs")
    return 0


if __name__ == "__main__":
    sys.exit(main())
