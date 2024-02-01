#!/bin/bash
set -e
source /imageBuild/buildconfig
set -x

SSHD_BUILD_PATH=/imageBuild/services/sshd

## Install the SSH server.
$minimal_apt_get_install openssh-server
mkdir /var/run/sshd
mkdir /etc/service/sshd
touch /etc/service/sshd/down
cp $SSHD_BUILD_PATH/sshd.minit /etc/minit
cp $SSHD_BUILD_PATH/sshd_config /etc/ssh/sshd_config
cp $SSHD_BUILD_PATH/00_regen_ssh_host_keys.sh /etc/init/

## Install default SSH key for root and app.
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown root:root /root/.ssh
cp $SSHD_BUILD_PATH/keys/insecure_key.pub /etc/insecure_key.pub
cp $SSHD_BUILD_PATH/keys/insecure_key /etc/insecure_key
chmod 644 /etc/insecure_key*
chown root:root /etc/insecure_key*
cp $SSHD_BUILD_PATH/enable_insecure_key /usr/sbin/