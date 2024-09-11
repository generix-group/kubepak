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

    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.accountname" "${ORGANIZATION}" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.azurename" "${ORGANIZATION}${PROJECT}" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.containername" "${ENVIRONMENT}" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.accountKind" "$(package_cache_values_file_read ".packages.azure-storage.blobs.accountKind")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.accessTier" "$(package_cache_values_file_read ".packages.azure-storage.blobs.accessTier")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.accountTier" "$(package_cache_values_file_read ".packages.azure-storage.blobs.accountTier")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.accountReplicationType" "$(package_cache_values_file_read ".packages.azure-storage.blobs.accountReplicationType")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.location" "$(package_cache_values_file_read ".packages.azure-storage.blobs.location")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.blobs.resourceGroupName" "$(package_cache_values_file_read ".packages.azure-storage.blobs.resourceGroupName")" true

    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.nfs.accountname" "${ORGANIZATION}-nfs" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.nfs.azurename" "${ORGANIZATION}${PROJECT}nfs" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.nfs.containername" "${ENVIRONMENT}-nfs" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.nfs.location" "$(package_cache_values_file_read ".packages.azure-storage.nfs.location")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.nfs.resourceGroupName" "$(package_cache_values_file_read ".packages.azure-storage.nfs.resourceGroupName")" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.nfs.networkRules.virtualNetworkSubnetIds" "$(package_cache_values_file_read ".packages.azure-storage.nfs.networkRules.virtualNetworkSubnetIds")" true

}

hook_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart"
}

hook_post_install() {
    kubectl wait --for=condition=Ready account --timeout=45m -l StorageAccountName="$(package_cache_values_file_read ".organization")"
    kubectl wait --for=condition=Ready account --timeout=45m -l StorageAccountName="$(package_cache_values_file_read ".organization")-nfs"
}

hook_upgrade() {
    hook_install
}

package_hook_execute "${@}"
