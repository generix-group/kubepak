#!/usr/bin/env bash

#
#  This file is part of Kubepak.
#
#  Kubepak is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  Kubepak is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with Kubepak.  If not, see <https://www.gnu.org/licenses/>.
#

set -eo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../../support/scripts/package.sh"

#-----------------------------------------------------------------------------
# Package Options

# @package-option dependencies="argo-cd"
# @package-option dependencies="crossplane"
# @package-option dependencies="crossplane-azure-provider"

#-----------------------------------------------------------------------------
# Private Constants

#-----------------------------------------------------------------------------
# Public Hooks

hook_initialize() {
    k8s_namespace_create "${K8S_PACKAGE_NAMESPACE}"

    registry_credentials_add_namespace "${K8S_PACKAGE_NAMESPACE}"

    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.aksClusterName" "$(package_cache_values_file_read ".packages.azure-managed-identity.aksClusterName")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.location" "$(package_cache_values_file_read ".packages.azure-managed-identity.location")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.resourceGroupName" "$(package_cache_values_file_read ".packages.azure-managed-identity.resourceGroupName")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.roleDefinitionName" "$(package_cache_values_file_read ".packages.azure-managed-identity.roleDefinitionName")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.scope" "$(package_cache_values_file_read ".packages.azure-managed-identity.scope")" true
}

hook_pre_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart-0"

    kubectl wait --for=condition=Ready UserAssignedIdentity/${PACKAGE_NAME}-${ENVIRONMENT} --timeout=1m
    local __principal_id=$(kubectl get UserAssignedIdentity/${PACKAGE_NAME}-${ENVIRONMENT} -o jsonpath='{.status.atProvider.principalId}')
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.principalId" "${__principal_id}" true

    local __application_namespace=$(echo ${K8S_PACKAGE_NAMESPACE} | sed 's/-identity$//')
    local __sa_name=$(echo $__application_namespace | awk -F'-' '{print $(NF-1) "-" $NF}')
    local __rg=$(package_cache_values_file_read ".packages.${PACKAGE_IPATH}.resourceGroupName")
    local __aksClusterName=$(package_cache_values_file_read ".packages.${PACKAGE_IPATH}.aksClusterName")
    local __issuer=$(az aks show --name $__aksClusterName --resource-group $__rg --query "oidcIssuerProfile.issuerUrl" --output tsv)

    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.applicationNs" "${__application_namespace}" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.sa" "${__sa_name}" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.issuer" "${__issuer}" true
}

hook_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart-1"
}

hook_post_install() {
    kubectl wait --for=condition=Ready RoleAssignment/${PACKAGE_NAME}-${ENVIRONMENT} --timeout=1m
    kubectl wait --for=condition=Ready FederatedIdentityCredential/${PACKAGE_NAME}-${ENVIRONMENT} --timeout=1m
}

package_hook_execute "${@}"
