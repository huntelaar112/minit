#!/bin/bash
set -e
source $(which buildconfig)
set -x

SYSLOG_NG_BUILD_PATH=${buildDirServices}/syslog-ng

## Install a syslog daemon.
apt install -y syslog-ng-core syslog-ng
cp "$SYSLOG_NG_BUILD_PATH"/syslog-ng.minit /etc/minit/03_syslog-ng.minit
#cp "$SYSLOG_NG_BUILD_PATH"/syslog-ng.shutdown /etc/minit.post_shutdown/10_syslog-ng.shutdown
mkdir -p /var/lib/syslog-ng
cp "$SYSLOG_NG_BUILD_PATH"/syslog_ng_etc_default /etc/default/syslog-ng
touch /var/log/syslog
chmod u=rw,g=r,o= /var/log/syslog
cp "$SYSLOG_NG_BUILD_PATH"/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

## Install logrotate.
apt install -y logrotate
cp "$SYSLOG_NG_BUILD_PATH"/logrotate.conf /etc/logrotate.conf
cp "$SYSLOG_NG_BUILD_PATH"/logrotate_syslogng /etc/logrotate.d/syslog-ng
