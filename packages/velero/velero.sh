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

# @package-option attributes="final"
# @package-option attributes="shared"

# @package-option dependencies="argo-cd"

#-----------------------------------------------------------------------------
# Private Constants

readonly __VELERO_VERSION_CHART_VERSION="7.1.4"
readonly __VELERO_VERSION_CLI="1.14.0"

#-----------------------------------------------------------------------------
# Public Hooks

hook_initialize() {
    if ! command -v velero &> /dev/null; then
        echo "Velero-cli is not installed, trying to install."

        wget https://github.com/vmware-tanzu/velero/releases/download/v"${__VELERO_VERSION_CLI}"/velero-v"${__VELERO_VERSION_CLI}"-linux-amd64.tar.gz
        tar -xvf velero-v"${__VELERO_VERSION_CLI}"-linux-amd64.tar.gz
        sudo mv velero-v"${__VELERO_VERSION_CLI}"-linux-amd64/velero /usr/local/bin/
        chmod +x /usr/local/bin/velero

        if ! command -v velero &> /dev/null; then
          echo "Unable to install Velero-cli." && exit
        fi
        echo "Velero-cli installed."
    else
        echo "Velero-cli already installed."
    fi

    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.chartVersion" "${__VELERO_VERSION_CHART_VERSION}"

    k8s_namespace_create "${K8S_PACKAGE_NAMESPACE}"

    registry_credentials_add_namespace "${K8S_PACKAGE_NAMESPACE}"
}

hook_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart"

    argo_cd_application_wait "${K8S_PACKAGE_NAME}"
}

hook_upgrade() {
    hook_install
}

package_hook_execute "${@}"
