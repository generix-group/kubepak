# 'azure-storage-backups' Package

## Description

A package for Azure Storage, centered around backups.

## Values

| Name                                                        | Type   | Default      | Description                                                                                                                                                    |
|-------------------------------------------------------------|--------|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| azure-storage-backups.accountKind                           | string |              | Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Defaults to StorageV2.                       |
| azure-storage-backups.accessTier                            | string |              | Defines the access tier. Valid options are Hot and Cool.                                                                                                       |
| azure-storage-backups.accountTier                           | string |              | Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. |
| azure-storage-backups.accountReplicationType                | string |              | Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS.                                      |
| azure-storage-backups.identity.identityIds                  | string |              | Identity ids                                                                                                                                                   |
| azure-storage-backups.identity.type                         | string |              | Identity type                                                                                                                                                  |
| azure-storage-backups.location                              | string |              | Location (ex. East US)                                                                                                                                         |
| azure-storage-backups.resourceGroupName                     | string |              | The Azure resource group name                                                                                                                                  |
| azure-storage-backups.writeConnectionSecretToRef.tags.key   | string |              | Tags key on the secret created by Crossplane for the Storage Account                                                                                           |
| azure-storage-backups.writeConnectionSecretToRef.tags.value | string |              | Tags value on the secret created by Crossplane for the Storage Account                                                                                         |
| azure-storage-backups.lockLevel                             | string | CanNotDelete | The lock level of the Storage Account. Possible values are: CanNotDelete and ReadOnly                                                                          |
| azure-storage-backups.subscriptionId                        | string |              | The Azure subscriptionId                                                                                                                                       |
| azure-storage-backups.containers[`{i}`].name                | string |              | List of each container names that needs to be created                                                                                                          |
