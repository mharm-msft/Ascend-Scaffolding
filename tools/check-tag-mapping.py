#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CHILD_NGS = ['prod-spokes', 'nonprod-spokes', 'dr-spokes']


def load_json(path: Path) -> dict:
    with path.open('r', encoding='utf-8') as f:
        return json.load(f)


def parse_child_network_groups(path: Path) -> list[str]:
    content = path.read_text(encoding='utf-8')
    match = re.search(r"param\s+childNetworkGroups\s+array\s*=\s*\[(.*?)\]", content, flags=re.DOTALL)
    if not match:
        print(
            "WARN: could not parse childNetworkGroups default from bicep/main.bicep; using fallback list",
            file=sys.stderr,
        )
        return DEFAULT_CHILD_NGS

    block = match.group(1)
    groups = [single or double for single, double in re.findall(r"'([^']+)'|\"([^\"]+)\"", block)]
    if not groups:
        print(
            "WARN: parsed empty childNetworkGroups default from bicep/main.bicep; using fallback list",
            file=sys.stderr,
        )
        return DEFAULT_CHILD_NGS

    return groups


def main() -> int:
    root_assignment_path = REPO_ROOT / 'policy/assignments/root-mg-assignment.json'
    hub_assignment_paths = [
        REPO_ROOT / 'policy/assignments/hub-east-assignment.json',
        REPO_ROOT / 'policy/assignments/hub-west-assignment.json',
        REPO_ROOT / 'policy/assignments/hub-central-assignment.json',
    ]

    root_assignment = load_json(root_assignment_path)
    root_values = set(root_assignment['resources'][0]['properties']['parameters']['allowedTagValues']['value'])

    expected_ngs = set(parse_child_network_groups(REPO_ROOT / 'bicep/main.bicep'))

    hub_tag_values: set[str] = set()
    invalid_ngs: list[str] = []

    for hub_path in hub_assignment_paths:
        hub_assignment = load_json(hub_path)
        mappings = hub_assignment['parameters']['ngMappings']['defaultValue']
        for mapping in mappings:
            hub_tag_values.add(mapping['tagValue'])
            if mapping['ng'] not in expected_ngs:
                invalid_ngs.append(f"{hub_path.name}: '{mapping['ng']}'")

    if root_values != hub_tag_values:
        symmetric_diff = sorted(root_values.symmetric_difference(hub_tag_values))
        print('ERROR: tag value sets do not match between root allowedTagValues and hub ngMappings.')
        print('Symmetric difference:', ', '.join(symmetric_diff) if symmetric_diff else '(none)')
        print('Root values:', ', '.join(sorted(root_values)))
        print('Hub values: ', ', '.join(sorted(hub_tag_values)))
        return 1

    if invalid_ngs:
        print('ERROR: Found ngMappings.ng values not present in expected child network groups:')
        for item in invalid_ngs:
            print(f' - {item}')
        print('Expected NG values:', ', '.join(sorted(expected_ngs)))
        return 1

    print(f'OK: {len(root_values)} tag values consistent across root + 3 hubs')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
