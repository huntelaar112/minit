#!/bin/bash

set -e
source $(which buildconfig)
set -x

cp "${buildDir}"/build-zabbix/script_conf/docker-entrypoint-zabbixoriginal.sh /bin && chmod +x /bin/docker-entrypoint-zabbixoriginal.sh


## if mountPoint is empty, cp config
mountPoint="/mnt/containerdata/zabbix-agent/etc_zabbix"
[[ -z $(ls -A $mountPoint) ]] && {
    cp "${buildDir}"/build-zabbix/script_conf/userparameter_nvidia-smi.conf /etc/zabbix/zabbix_agentd.d

    #for monitor nginx healcheck endpoint
    cp "${buildDir}"/build-zabbix/script_conf/nginxHealthCheck.conf /etc/zabbix/zabbix_agentd.d

    #for monitor nginx requets (>20s, return 200, total requets) per minutes
    cp "${buildDir}"/build-zabbix/script_conf/nginx_requetsPerMin.conf /etc/zabbix/zabbix_agentd.d

    # script discovery
    mkdir -p /etc/zabbix/scripts
    cp "${buildDir}"/build-zabbix/script_conf/get_gpus_info.sh /etc/zabbix/scripts
    cp "${buildDir}"/build-zabbix/script_conf/healcheck_nginx /etc/zabbix/scripts
}
