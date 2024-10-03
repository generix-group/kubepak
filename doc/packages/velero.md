# 'velero' Package

## Description

A package for Velero. A tool to safely backup and restore, perform disaster recovery, and migrate Kubernetes cluster resources and persistent volumes.

## Values

| Name                                                              | Type   | Default              | Description                                                                                                    |
|-------------------------------------------------------------------|--------|----------------------|----------------------------------------------------------------------------------------------------------------|
| velero.image.repository                                           | string |                      | Image repository                                                                                               |
| velero.image.tag                                                  | string |                      | Image tag                                                                                                      |                                                                                                                                                                  |
| velero.containers[`{i}`].name                                     | string |                      | Container name to add to Velero's deployment. At least one is required at any time                             |
| velero.containers[`{i}`].image                                    | string |                      | Container image to add to Velero's deployment. At least one is required at any time                            |
| velero.resources.request.cpu                                      | string | 500m                 | CPU resource requests to specify for the Velero deployment.                                                    |
| velero.resources.request.memory                                   | string | 128Mi                | Memory resource requests to specify for the Velero deployment.                                                 |
| velero.resources.limits.cpu                                       | string | 1000m                | CPU resource limits to specify for the Velero deployment.                                                      |
| velero.resources.limits.memory                                    | string | 512Mi                | Memory resource limits to specify for the Velero deployment.                                                   |
| velero.schedules[`{i}`].name                                      | string |                      | Name of the schedule                                                                                           |
| velero.schedules[`{i}`].enabled                                   | bool   |                      | Is the schedule enabled                                                                                        |
| velero.schedules[`{i}`].schedule                                  | string |                      | Cron schedule expression that says when the backup should be made                                              |
| velero.schedules[`{i}`].labels                                    | object | {}                   | Object of extra labels to add to the schedules as *key: value*                                                 |
| velero.schedules[`{i}`].annotations                               | object | {}                   | Object of extra annotations to add to the schedules as *key: value*                                            |
| velero.schedules[`{i}`].paused                                    | bool   | false                | Is the schedules currently paused                                                                              |
| velero.schedules[`{i}`].ttl                                       | string |                      | Time to live of the backup (15m, 240h, 90d, ...)                                                               |
| velero.schedules[`{i}`].storageLocation                           | string |                      | Which configuration.backupStorageLocation should this schedule uses to store the backups.                      |
| velero.schedules[`{i}`].includedNamespaces                        | list   | []                   | Which namespace should be included in the backup. Default: everything                                          |
| velero.schedules[`{i}`].excludedNamespaces                        | list   | []                   | Which namespace should be blacklisted in the backup.                                                           |
| velero.configuration.backupStorageLocation[`{i}`].name            | string |                      | Name for this backupStorageLocation. ***There must always be one, and only one called "default"***             |
| velero.configuration.backupStorageLocation[`{i}`].provider        | string |                      | Provider for this configuration (Azure: velero.io/azure)                                                       |
| velero.configuration.backupStorageLocation[`{i}`].resourceGroup   | string |                      | Resource group of the storage account                                                                          |
| velero.configuration.backupStorageLocation[`{i}`].storageAccount  | string |                      | Storage account name                                                                                           |
| velero.configuration.backupStorageLocation[`{i}`].bucket          | string |                      | Container name inside the storage account                                                                      |
| velero.configuration.backupStorageLocation[`{i}`].prefix          | string | .Values.organization | The path inside a bucket. Path is (*StorageAccountName*/*Prefix*/backups/velero-*ScheduleName-yyyyMMddhhmmss*) |
| velero.configuration.backupStorageLocation[`{i}`].accessMode      | string | ReadWrite            | Defines the permissions for the backup storage. Value is either ReadOnly or ReadWrite.                         |
| velero.configuration.backupStorageLocation[`{i}`].subscriptionId  | string |                      | Azure subscription Id                                                                                          |
| velero.configuration.volumeSnapshotLocation[`{i}`].name           | string |                      | Name for this backupStorageLocation.                                                                           |
| velero.configuration.volumeSnapshotLocation[`{i}`].provider       | string |                      | Provider for this configuration (Azure: velero.io/azure)                                                       |
| velero.configuration.volumeSnapshotLocation[`{i}`].resourceGroup  | string |                      | Resource group of the storage account                                                                          |
| velero.configuration.volumeSnapshotLocation[`{i}`].subscriptionId | string |                      | Azure subscription Id                                                                                          |
| velero.configuration.volumeSnapshotLocation[`{i}`].incremental    | string |                      | Azure offers the option to take full or incremental snapshots of managed disks                                 |
| velero.configuration.volumeSnapshotLocation[`{i}`].tags           | string |                      | The tags added to the volume snapshots during the backup                                                       |
| velero.credentials.secretName                                     | string | velero-credentials   | Name of the secret used for the Velero Azure credentials                                                       |
| velero.credentials_b64                                            | string |                      | Azure credentials used by Velero as a b64                                                                      |