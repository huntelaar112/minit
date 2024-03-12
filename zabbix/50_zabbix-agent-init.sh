#!/bin/bash

set -e
source $(which buildconfig)
set -x

cp "${buildDir}"/zabbix/script_conf/docker-entrypoint-zabbixoriginal.sh /bin && chmod +x /bin/docker-entrypoint-zabbixoriginal.sh

## if mountPoint is empty, cp config
mountPoint="/mnt/containerdata/zabbix-agent/etc_zabbix"
agentd=${mountPoint}/zabbix_agentd.d
scripts=${mountPoint}/scripts

rm -rf /etc/zabbix/zabbix_agentd.d /etc/zabbix/scripts
mkdir -p ${agentd} ${scripts}
ln -sn ${agentd} /etc/zabbix/zabbix_agentd.d
ln -sn ${scripts} /etc/zabbix/scripts

[[ -z $(ls -A $agentd) && -z $(ls -A $scripts) ]] && {
    mkdir -p /etc/zabbix/zabbix_agentd.d
    cp "${buildDir}"/zabbix/script_conf/userparameter_nvidia-smi.conf /etc/zabbix/zabbix_agentd.d

    #for monitor nginx healcheck endpoint
    cp "${buildDir}"/zabbix/script_conf/nginxHealthCheck.conf /etc/zabbix/zabbix_agentd.d

    #for monitor nginx requets (>20s, return 200, total requets) per minutes
    cp "${buildDir}"/zabbix/script_conf/nginx_requetsPerMin.conf /etc/zabbix/zabbix_agentd.d

    # script discovery
    chmod +x "${buildDir}"/zabbix/script_conf/get_gpus_info.sh "${buildDir}"/zabbix/script_conf/healcheck_nginx
    mkdir -p /etc/zabbix/scripts
    cp "${buildDir}"/zabbix/script_conf/get_gpus_info.sh /etc/zabbix/scripts
    cp "${buildDir}"/zabbix/script_conf/healcheck_nginx /etc/zabbix/scripts
} || {
    # if folder data have config file.
    echo "Using existed zabbix data."
    #rm -rf /etc/zabbix
    #ln -s /mnt/containerdata/zabbix-agent/etc_zabbix /etc/zabbix
}
