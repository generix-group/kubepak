# 'cert-manager-issuers' Package

## Description

A package for Cert-Manager issuers, Kubernetes resources that represent certificate authorities (CAs) that are able to
generate signed certificates by honoring certificate signing requests.

## Values

| Name                                                                                     | Type   | Default                                                | Description                                                                                                  |
|------------------------------------------------------------------------------------------|--------|--------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| cert-manager-issuers.issuers.acme[`{i}`].name                                            | string |                                                        | ACME issuer name                                                                                             |
| cert-manager-issuers.issuers.acme[`{i}`].server                                          | string | https://acme-staging-v02.api.letsencrypt.org/directory | ACME server URL                                                                                              |
| cert-manager-issuers.issuers.acme[`{i}`].email                                           | string |                                                        | Email address to receive notifications                                                                       |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].provider                   | string |                                                        | DNS01 provider: `rfc2136` or `route53`                                                                       |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].azureDNS.subscriptionId    | string |                                                        | Azure Subscription Id                                                                                        |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].azureDNS.resourceGroupName | string |                                                        | resource group the DNS zone is located in                                                                    |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].azureQDNS.hostedZoneName   | string |                                                        | name of the DNS zone that should be used                                                                     |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].rfc2136.nameserver         | string |                                                        | RFC2136 nameserver                                                                                           |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].rfc2136.tsigKeyName        | string |                                                        | RFC2136 TSIG key name                                                                                        |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].rfc2136.tsigKeyAlgorithm   | string |                                                        | RFC2136 TSIG key algorithm                                                                                   |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].route53.awsRegion          | string |                                                        | AWS region                                                                                                   |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].route53.accessKeyId        | string |                                                        | AWS access key ID                                                                                            |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].route53.secretAccessKey    | string |                                                        | AWS secret access key                                                                                        |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].dnsZones                   | list   | []                                                     | DNS zones that can be solved by the solver                                                                   |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.http01.enabled                          | bool   |                                                        | Enable http01                                                                                                |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.http01.networkPlane                     | string |
| cert-manager-issuers.issuers.vault[`{i}`].name                                           | string |                                                        | Human readable name for this issuer                                                                          |
| cert-manager-issuers.issuers.vault[`{i}`].auth.type                                      | string |                                                        | Authentication type: appRole or kubernetes                                                                   |
| cert-manager-issuers.issuers.vault[`{i}`].auth.appRole.path                              | string |                                                        | Path where the App Role authentication backend is mounted in Vault                                           |
| cert-manager-issuers.issuers.vault[`{i}`].auth.appRole.roleId                            | string |                                                        | RoleID configured in the App Role authentication backend when setting up the authentication backend in Vault |
| cert-manager-issuers.issuers.vault[`{i}`].auth.kubernetes.mountPath                      | string |                                                        | Mount path to use when authenticating with Vault                                                             |
| cert-manager-issuers.issuers.vault[`{i}`].auth.kubernetes.role                           | string |                                                        | Vault Role to assume                                                                                         |
| cert-manager-issuers.issuers.vault[`{i}`].path                                           | string |                                                        | Mount path of the Vault PKI backend's sign endpoint                                                          |
| cert-manager-issuers.issuers.vault[`{i}`].server                                         | string |                                                        | Connection address for the Vault server                                                                      |

### ACME with AzureDNS

We have 2 possibilities to identify with Azure, using Service Principal and Workload Identity.
By default, what is present in the values are the common for both.

#### Using Service Principal

You need to add:

| Name                                                                                | Type   | Default | Description                                                                     |
|-------------------------------------------------------------------------------------|--------|---------|---------------------------------------------------------------------------------|
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].azureDNS.clientId     | string |         | The ClientID of the Azure Service Principal used to authenticate with Azure DNS |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].azureDNS.clientSecret | string |         | Azure Service Principal - Client Secret                                         |
| cert-manager-issuers.issuers.acme[`{i}`].solvers.dns01[`{j}`].azureDNS.tenantId     | string |         | The TenantID of the Azure Service Principal used to authenticate with Azure DNS |