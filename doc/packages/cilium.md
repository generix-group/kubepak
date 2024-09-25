# 'cilium' Package

## Description

A package for Cilium. A networking, observability, and security solution with an eBPF-based dataplane.

## Values

| Name                                         | Type | Default | Description                                                                                                                                                               |
|----------------------------------------------|------|---------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cilium.cluster.id                            | int  | 0       | Unique ID of the cluster. Must be unique across all connected clusters and in the range of 1 to 255. Only required for Cluster Mesh, may be 0 if Cluster Mesh is not used |
| cilium.clustermesh.useAPIServer              | bool | false   | Deploy clustermesh-apiserver for clustermesh                                                                                                                              |
| cilium.hubble.redact.enabled                 | bool | false   | Enables redacting sensitive information present in Layer 7 flows                                                                                                          |
| cilium.hubble.redact.httpUrlQuery            | bool | false   | Enables redacting URL query (GET) parameters                                                                                                                              |
| cilium.hubble.redact.httpUserInfo            | bool | false   | Enables redacting user info, e.g., password when basic auth is used.                                                                                                      |
| cilium.hubble.redact.headers.allow           | list | []      | List of HTTP headers to allow: headers not matching will be redacted. Note: `allow` and `deny` lists cannot be used both at the same time, only one can be present        |
| cilium.hubble.redact.headers.deny            | list | []      | List of HTTP headers to deny: matching headers will be redacted. Note: `allow` and `deny` lists cannot be used both at the same time, only one can be present             |
| cilium.ipam.operator.clusterPoolIPv4MaskSize | int  | 24      | IPv4 CIDR mask size to delegate to individual nodes for IPAM                                                                                                              |

### Auto-discovered using kubectl
Done during `hook_initialize`

| Name                   | Type   | Description                                                                                                             |
|------------------------|--------|-------------------------------------------------------------------------------------------------------------------------|
| cilium.cluster.name    | string | Name of the cluster and must be unique                                                                                  |
| cilium.k8sService.host | string | Kubernetes service host - use “auto” for automatic lookup from the cluster-info ConfigMap (kubeadm-based clusters only) |
| cilium.k8sService.port | int    | Kubernetes service port                                                                                                 |
