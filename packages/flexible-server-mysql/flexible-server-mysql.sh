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
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/../../support/scripts/k8s.sh"

#-----------------------------------------------------------------------------
# Package Options

# @package-option dependencies="argo-cd"
# @package-option dependencies="crossplane-azure-provider"


#-----------------------------------------------------------------------------
# Public Hooks

hook_initialize() {
    k8s_namespace_create "${K8S_PACKAGE_NAMESPACE}"

    registry_credentials_add_namespace "${K8S_PACKAGE_NAMESPACE}"
}

hook_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart-0"
}

hook_post_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart-1"

    # echo "Creating the Database server on Azure, you're going to wait for a looooooooooong time... Here, go have fun: https://neal.fun/"
    echo "Creating the Database server on Azure..."
    kubectl wait --for=condition=Ready flexibleserver --timeout=45m -l FlexibleServerName="$(package_cache_values_file_read ".packages.${PACKAGE_IPATH}.name")"
}

hook_upgrade() {
    hook_install
}

hook_post_upgrade() {
    hook_post_install
}

package_hook_execute "${@}"
