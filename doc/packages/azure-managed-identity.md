# 'azure-managed-identity' Package

## Description

A package for azure-managed-identity, to support AKS workload identity with user managed ids.

## Values

| Name                                            | Type   | Default | Description                  |
| ----------------------------------------------- | ------ | ------- | ---------------------------- |
| azure-managed-identity.image.aksClusterName     | string |         | AKS cluster name             |
| azure-managed-identity.image.location           | string |         | AKS cluster location         |
| azure-managed-identity.image.resourceGroupName  | string |         | AKS RG name                  |
| azure-managed-identity.image.roleDefinitionName | string |         | Azure Built-in role name     |
| azure-managed-identity.image.scope              | string |         | Azure ressource scope string |
