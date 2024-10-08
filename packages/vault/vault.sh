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
# @package-option dependencies="emissary-ingress" [ ",${CONTEXT}," =~ ",single-ingress-controller," ]
# @package-option dependencies="ingress-management" [ ",${CONTEXT}," =~ ",multiple-ingress-controllers," ]

# @package-option envs="VAULT_ADDR="http://127.0.0.1:\${VAULT_PORT}""

# @package-option port-forwards="${PACKAGE_NAME}:VAULT_PORT:8200"

#-----------------------------------------------------------------------------
# Private Constants

readonly __VAULT_CHART_VERSION="0.28.1"

readonly __VAULT_DEFAULT_TLS_CA_DST_FILE_PATH="/ssl/certs/ca-certificates.crt"

#-----------------------------------------------------------------------------
# Public Hooks

hook_initialize() {
    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.chartVersion" "${__VAULT_CHART_VERSION}"

    k8s_namespace_create "${K8S_PACKAGE_NAMESPACE}"

    registry_credentials_add_namespace "${K8S_PACKAGE_NAMESPACE}"
}

hook_pre_install() {
    local __tls_ca_src_file_path
    __tls_ca_src_file_path="$(package_cache_values_file_read ".packages.${PACKAGE_IPATH}.tls.ca.srcFilePath")"

    if [[ -n "${__tls_ca_src_file_path}" ]]; then
        local __tls_ca_dst_file_path
        __tls_ca_dst_file_path="$(package_cache_values_file_read ".packages.${PACKAGE_IPATH}.tls.ca.dstFilePath" "${__VAULT_DEFAULT_TLS_CA_DST_FILE_PATH}")"

        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.tls.ca.dstFilePath" "${__tls_ca_dst_file_path}"

        k8s_configmap_create_from_file "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-ca-certificates" "$(basename "${__tls_ca_dst_file_path}")" "${__tls_ca_src_file_path}"
    fi
}

hook_install() {
    package_helm_install "${K8S_PACKAGE_NAME}" "${K8S_PACKAGE_NAMESPACE}" "${PACKAGE_DIR}/files/helm-chart"

    local __attempt=0
    until [[ $(kubectl get pods "${K8S_PACKAGE_NAME}-0" -n "${K8S_PACKAGE_NAMESPACE}" --no-headers -o custom-columns=":status.phase" 2>/dev/null) == "Running" ]]; do
        if [[ ${__attempt} -eq 30 ]]; then
            echo "Max attempts reached"
            exit 1
        fi

        printf '.'
        __attempt=$((__attempt + 1))
        sleep 2
    done
    printf '\n'
}

hook_upgrade() {
    hook_install
}

hook_post_install() {
    local __attempt=0
    until vault status >/dev/null 2>&1; do
        # shellcheck disable=SC2181
        if [[ $? -eq 0 || $? -eq 2 ]]; then
            break
        fi

        if [[ ${__attempt} -eq 30 ]]; then
            echo "Max attempts reached"
            exit 1
        fi

        printf '.'
        __attempt=$((__attempt + 1))
        sleep 2
    done
    printf '\n'

    if [[ "$(vault status --format=json | jq -r '.initialized')" == "true" ]]; then
        return
    fi

    local __init_output
    if [[ $(package_cache_values_file_count ".packages.${PACKAGE_IPATH}.seal") -eq 0 ]]; then
        __init_output="$(vault operator init -key-shares=1 -key-threshold=1)"
    else
        __init_output="$(vault operator init -recovery-shares=1 -recovery-threshold=1)"
    fi

    echo "================================================================================"
    echo "${__init_output}"
    echo "================================================================================"

    if [[ $(package_cache_values_file_count ".packages.${PACKAGE_IPATH}.seal") -eq 0 ]]; then
        local __unseal_key
        __unseal_key="$(grep -Po 'Unseal Key [0-9]+: \K.*' <<<"${__init_output}")"

        vault operator unseal "${__unseal_key}" >/dev/null 2>&1

        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.unsealKey" "${__unseal_key}" true
    else
        local __recovery_key
        __recovery_key="$(grep -Po 'Recovery Key [0-9]+: \K.*' <<<"${__init_output}")"

        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.recoveryKey" "${__recovery_key}" true
    fi

    local __vault_token
    __vault_token="$(grep -Po 'Initial Root Token: \K.*' <<<"${__init_output}")"

    vault login "${__vault_token}" >/dev/null 2>&1

    package_cache_values_file_write ".packages.${PACKAGE_IPATH}.rootToken" "${__vault_token}" true

    if ! vault secrets list -format json | jq -e '.["secret/"]' >/dev/null; then
        vault secrets enable -path=secret -version=2 kv
    fi

    if ! vault auth list -format json | jq -e '.["approle/"]' >/dev/null; then
        vault auth enable approle
    fi

    if ! vault auth list -format json | jq -e '.["kubernetes/"]' >/dev/null; then
        vault auth enable kubernetes
    fi

    k8s_secret_create_sa_token "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-k8s-auth" "${K8S_PACKAGE_NAME}"

    vault write auth/kubernetes/config \
        issuer="https://kubernetes.default.svc.cluster.local" \
        kubernetes_host="$(package_cache_values_file_read ".kubernetes.server")" \
        kubernetes_ca_cert="$(kubectl get secret -n "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-k8s-auth" -o jsonpath="{.data['ca\.crt']}" | base64 --decode)" \
        token_reviewer_jwt="$(kubectl get secret -n "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-k8s-auth" -o jsonpath="{.data.token}" | base64 --decode)"

    local __kubernetes_accessor
    __kubernetes_accessor="$(vault auth list -format=json | jq -r '.["kubernetes/"].accessor')"

    vault policy write "kubernetes-accessor-secret-read" - <<EOF
path "secret/data/{{identity.entity.aliases.${__kubernetes_accessor}.metadata.service_account_namespace}}/*" {
  capabilities = ["read"]
}
path "secret/metadata/{{identity.entity.aliases.${__kubernetes_accessor}.metadata.service_account_namespace}}/*" {
  capabilities = ["read", "list"]
}
EOF

    vault policy write "kubernetes-accessor-secret-write" - <<EOF
path "secret/data/{{identity.entity.aliases.${__kubernetes_accessor}.metadata.service_account_name}}/*" {
  capabilities = ["create", "update", "patch", "read", "delete"]
}
path "secret/metadata/{{identity.entity.aliases.${__kubernetes_accessor}.metadata.service_account_name}}/*" {
  capabilities = ["read", "list"]
}
EOF
}

package_hook_execute "${@}"
