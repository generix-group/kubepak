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

source "support/scripts/package.sh"

#-----------------------------------------------------------------------------
# Package Options

# @package-option attributes="final"
# @package-option attributes="shared"

# @package-option base-packages="postgresql" [ ,${CONTEXT}, =~ ,vault-local-database, ]
# @package-option base-packages="flexible-server-postgresql" [ ,${CONTEXT}, =~ ,vault-azure-database, ]

#-----------------------------------------------------------------------------
# Public Hooks

hook_initialize() {
    if [[ ,${CONTEXT}, =~ ,vault-local-database, ]]; then
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.metadata.host" "${K8S_PACKAGE_NAME}.${K8S_PACKAGE_NAMESPACE}.svc.cluster.local." true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.metadata.port" "5432" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.metadata.root.username" "postgres" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.metadata.root.password" "$(package_cache_values_file_read ".packages.${PACKAGE_IPATH}.postgresql.auth.postgresPassword" "postgres")" true
    elif [[ ,${CONTEXT}, =~ ,vault-azure-database, ]]; then
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.name" "${K8S_PACKAGE_NAME}" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.location" "East US" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.resourceGroupName" "poc-crossplane" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.createMode" "Default" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.skuName" "GP_Standard_D2ads_v5" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.subscription" "aa3ae2aa-9e5b-4e2b-b8e4-b7b42262cbb4" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.version" "8.0.21" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.availabilityZone" "1" true
    fi
}

hook_post_install() {
    if [[ ,${CONTEXT}, =~ azure ]]; then
      __db_username="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "crossplane-db-credentials" "username")"
      __db_secret="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-db-secret" "credentials")"
      __db_host="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "crossplane-db-credentials" "endpoint")"
      __db_port="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "crossplane-db-credentials" "port")"

      package_cache_values_file_write ".packages.${PACKAGE_IPATH}.metadata" '{
        "host": "'"${__db_host}"'",
        "port": '"${__db_port}"',
        "root": {
          "username": "'"${__db_username}"'",
          "password": "'"${__db_secret}"'"
        },
        "tls_ca_filepath": "'"$(yaml_read "${CACHE_CWD}/values.yaml" ".azure_db_ca")"'"
      }'

      local __psql_connection_string
      __psql_connection_string="postgresql://${__db_username}:${__db_secret}@${__db_host}:${__db_port}/postgres"
      until [[ $(psql -tXA "${__psql_connection_string}" -c "SELECT 1") = "1" ]]; do
        sleep 10
      done
    fi
}

package_hook_execute "${@}"