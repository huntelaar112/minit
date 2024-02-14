#!/bin/bash
set -e
source $(which buildconfig)
set -x

SSHD_BUILD_PATH="${buildDirServices}/sshd"

## Install the SSH server.
$minimal_apt_get_install openssh-server
mkdir -p /var/run/sshd
mkdir -p /etc/service/sshd
touch /etc/service/sshd/down
mkdir -p /etc/ssh

cp "${SSHD_BUILD_PATH}"/sshd.minit "${etcServiceDir}"
#cp "${SSHD_BUILD_PATH}"/sshd_config /etc/ssh/sshd_config
cp "${SSHD_BUILD_PATH}"/00_genSshKeys.sh "${etcServicePreStartDir}"

## Install default SSH key for root and app.
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown root:root /root/.ssh

#chown root:root "${SSHD_BUILD_PATH}"/keys/"${KEY_NAME}"*
#chmod 644 "${SSHD_BUILD_PATH}"/keys/"${KEY_NAME}".pub
#chmod 600 "${SSHD_BUILD_PATH}"/keys/"${KEY_NAME}"

#cp "${SSHD_BUILD_PATH}"/keys/"${KEY_NAME}".pub /root/.ssh/
#cp "${SSHD_BUILD_PATH}"/keys/"${KEY_NAME}" /root/.ssh/

# enable ssh to container by key
chmod +x "${SSHD_BUILD_PATH}"/enable_key 
cp "${SSHD_BUILD_PATH}"/enable_key /bin

## enable ssh key
bash -c "enable_key"


