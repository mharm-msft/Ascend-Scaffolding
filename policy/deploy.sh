#!/usr/bin/env bash
# Deploy the AVNM SaaS spoke governance policy foundation.
#
# Prereqs:
#   - az CLI logged in with rights at the root MG
#   - jq installed
#   - The root MG and per-hub MGs already exist
#
# Usage:
#   ./deploy.sh <subscriptionId>

set -euo pipefail

ROOT_MG="${ROOT_MG:-mg-saas-platform}"
SUB_ID="${1:-}"

if [[ -z "$SUB_ID" ]]; then
  echo "Subscription ID required as first argument (for per-hub NG assignments)." >&2
  exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "==> 1/4 Creating policy definitions at MG $ROOT_MG"
for f in definitions/*.json; do
  name=$(basename "$f" .json)
  az policy definition create \
    --name "$name" \
    --management-group "$ROOT_MG" \
    --rules "$(jq -c '.properties.policyRule' "$f")" \
    --params "$(jq -c '.properties.parameters' "$f")" \
    --mode "$(jq -r '.properties.mode' "$f")" \
    --display-name "$(jq -r '.properties.displayName' "$f")" \
    --description "$(jq -r '.properties.description' "$f")" \
    --metadata "$(jq -c '.properties.metadata' "$f")"
done

echo "==> 2/4 Creating initiative"
az policy set-definition create \
  --name "avnm-saas-spoke-governance" \
  --management-group "$ROOT_MG" \
  --definitions "$(jq -c '.properties.policyDefinitions' initiatives/avnm-saas-spoke-governance.json)" \
  --params "$(jq -c '.properties.parameters' initiatives/avnm-saas-spoke-governance.json)" \
  --definition-groups "$(jq -c '.properties.policyDefinitionGroups' initiatives/avnm-saas-spoke-governance.json)" \
  --display-name "AVNM SaaS Spoke Governance" \
  --description "Bundles tag governance and tag inheritance for the AVNM SaaS topology."

echo "==> 3/4 Assigning initiative at root MG"
az deployment mg create \
  --management-group-id "$ROOT_MG" \
  --location eastus \
  --template-file assignments/root-mg-assignment.json \
  --parameters rootMgName="$ROOT_MG"

echo "==> 4/4 Per-hub NG assignments (run AFTER child AVNMs are deployed)"
echo "     Example commands:"
echo "     az deployment mg create --management-group-id mg-hub-eastus    --location eastus    --template-file assignments/hub-east-assignment.json    --parameters subscriptionId=$SUB_ID"
echo "     az deployment mg create --management-group-id mg-hub-westus    --location westus3   --template-file assignments/hub-west-assignment.json    --parameters subscriptionId=$SUB_ID"
echo "     az deployment mg create --management-group-id mg-hub-centralus --location centralus --template-file assignments/hub-central-assignment.json --parameters subscriptionId=$SUB_ID"

echo "Done."
