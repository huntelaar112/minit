#!/bin/bash

set -e
BUILDDIR="/build"

cp ${BUILDDIR}/build-zabbix/script_conf/userparameter_nvidia-smi.conf /etc/zabbix/zabbix_agentd.d

#for monitor nginx healcheck endpoint
cp ${BUILDDIR}/build-zabbix/script_conf/nginxHealthCheck.conf /etc/zabbix/zabbix_agentd.d

#for monitor nginx requets (>20s, return 200, total requets) per minutes
cp ${BUILDDIR}/build-zabbix/script_conf/nginx_requetsPerMin.conf /etc/zabbix/zabbix_agentd.d

# script discovery
cp ${BUILDDIR}/build-zabbix/script_conf/get_gpus_info.sh /etc/zabbix/scripts
cp ${BUILDDIR}/build-zabbix/script_conf/healcheck_nginx /etc/zabbix/scripts

