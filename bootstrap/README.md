# Management-group bootstrap

One-time setup for a fresh tenant where these management groups do not yet exist:

- `mg-saas-platform`
- `mg-hub-eastus`
- `mg-hub-westus`
- `mg-hub-centralus`

Run this as a Global Admin or Management Group Contributor at tenant scope.

## Deploy with Bicep (tenant scope)

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

## Place subscriptions under each hub MG

```bash
az account management-group subscription add --name mg-hub-eastus --subscription <sub-id>
```
