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
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.name" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.name" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.location" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.location" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.resourceGroupName" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.resourceGroupName" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.createMode" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.createMode" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.administratorLogin" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.administratorLogin" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.skuName" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.skuName" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.subscription" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.subscription" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.version" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.version" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.availabilityZone" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.availabilityZone" "")" true
        package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.writeConnectionSecretToRef.name" "${K8S_PACKAGE_NAME}-flexible-server-connection" true
        if [[ "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.storageMb" "false")" != false ]]; then
            package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.storageMb" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.storageMb" "32768")" true
        fi

        if [[ "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.highAvailability.mode" "false")" != false ]]; then
            package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.highAvailability[0].mode" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.highAvailability.mode" "")" true
        fi

        if [[ "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.highAvailability.standbyAvailabilityZone" "false")" != false ]]; then
            package_cache_values_file_write ".packages.${PACKAGE_IPATH}.flexible-server-postgresql.highAvailability[0].standbyAvailabilityZone" "$(package_cache_values_file_read ".packages.vault.database.flexible-server-postgresql.highAvailability.standbyAvailabilityZone" "")" true
        fi
    else
        log_error "Missing value in CONTEXT: must either be 'vault-azure-database' or 'vault-local-database'"
    fi
}

hook_post_install() {
    if [[ ,${CONTEXT}, =~ azure ]]; then
      if [[ "$(kubectl -n "${K8S_PACKAGE_NAMESPACE}" get secrets "${K8S_PACKAGE_NAME}"-flexible-server-connection -o jsonpath='{.data.username}')" == "" ]]; then
          sleep 2
      fi

      __db_username_untouched="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-flexible-server-connection" "username")"
      __db_username="${__db_username_untouched//\@${K8S_PACKAGE_NAME}/}"
      __db_secret="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-flexible-server-connection" "password")"
      __db_host="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-flexible-server-connection" "endpoint")"
      __db_port="$(k8s_read_secret_from_key "${K8S_PACKAGE_NAMESPACE}" "${K8S_PACKAGE_NAME}-flexible-server-connection" "port")"

      package_cache_values_file_write ".packages.${PACKAGE_IPATH}.metadata" '{
        "host": "'"${__db_host}"'",
        "port": '"${__db_port}"',
        "root": {
          "username": "'"${__db_username}"'",
          "password": "'"${__db_secret}"'"
        },
        "tls_ca_filepath": "'"$(yaml_read "${CACHE_CWD}/values.yaml" ".azure_db_ca")"'"
      }' true

      local __psql_connection_string
      __psql_connection_string="postgresql://${__db_username}:${__db_secret}@${__db_host}:${__db_port}/postgres?sslmode=require"
      until [[ $(psql -tXA "${__psql_connection_string}" -c "SELECT 1") = "1" ]]; do
        sleep 10
      done
    fi
}

package_hook_execute "${@}"