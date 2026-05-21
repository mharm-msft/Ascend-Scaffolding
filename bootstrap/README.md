# Management group bootstrap

One-time setup for first-time deployment in a fresh tenant.

Run this as a Global Admin or Management Group Contributor at tenant scope.

## Tenant-scope deployment

```bash
az deployment tenant create \
  --location eastus \
  --template-file bootstrap/management-groups.bicep
```

## Manual fallback (if tenant-scope ARM is blocked)

```bash
az account management-group create --name mg-saas-platform
az account management-group create --name mg-hub-eastus    --parent mg-saas-platform
az account management-group create --name mg-hub-westus    --parent mg-saas-platform
az account management-group create --name mg-hub-centralus --parent mg-saas-platform
```

## Place subscriptions under hub management groups

After creation, place each hub subscription under the appropriate per-hub management group:

```bash
az account management-group subscription add --name mg-hub-eastus --subscription <sub-id>
```

Repeat for `mg-hub-westus` and `mg-hub-centralus` as needed.
