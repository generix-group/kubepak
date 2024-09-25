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

# @package-option attributes="shared"

# @package-option dependencies="argo-cd"

#-----------------------------------------------------------------------------
# Private Constants

readonly __CILIUM_CHART_VERSION="1.15.7"

#-----------------------------------------------------------------------------
# Public Hooks

hook_initialize() {
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.chartVersion" "${__CILIUM_CHART_VERSION}"

    local __cluster_name
    __cluster_name=$(kubectl config current-context)

    local __controlplane_url
    # Substitution is needed due to the colorized output from kubectl: \x1B\[[0-9;]*m matches ANSI escape sequences.
    __controlplane_full_url=$(kubectl cluster-info | awk -F/ '/Kubernetes control plane/ { gsub(/\x1B\[[0-9;]*m/, "", $NF); printf "%s", $NF }')

    local __controlplane_host
    __controlplane_host="${__controlplane_full_url%%:*}"

    local __controlplane_port
    __controlplane_port="${__controlplane_full_url##*:}"

    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.cluster.name" "${__cluster_name}" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.k8sService.host" "${__controlplane_host}" true
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.k8sService.port" "${__controlplane_port}" true

    k8s_namespace_create "${K8S_PACKAGE_NAMESPACE}"

    registry_credentials_add_namespace "${K8S_PACKAGE_NAMESPACE}"
}

hook_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart"

    #sleep to be sure configmap data is up-to-date before restart
    sleep 15 && k8s_rollout_restart "${K8S_PACKAGE_NAMESPACE}" "deployment/cilium-operator"

    argo_cd_application_wait "${K8S_PACKAGE_NAME}"
}

hook_upgrade() {
    hook_install
}

hook_post_install() {
  kubectl apply -f "${PACKAGE_DIR}/files/policies/cluster-wide-dns.yaml"
}

package_hook_execute "${@}"
