# 'cert-manager' Package

## Description

A package for Cert-Manager, a Kubernetes addon to automate the management and issuance of TLS certificates from various
issuing sources.

## Values

| Name                                         | Type   | Default | Description                                                     |
|----------------------------------------------|--------|---------|-----------------------------------------------------------------|
| cert-manager.image.repository                | string |         | Image repository                                                |
| cert-manager.image.tag                       | string |         | Image tag                                                       |
| cert-manager.azure-workload-identity.enabled | bool   | false   | Enable Azure Workload Identity label to Pod and Service Account |
