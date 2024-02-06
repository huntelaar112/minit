#!/bin/bash
set -e

KEY_NAME="ssh_host_ed25519_key"

[[ ! -e /etc/ssh/${KEY_NAME} ]] && {
	echo "No SSH host key available. Generating one..."

	ssh-keygen -A
	cp /etc/ssh/${KEY_NAME}.pub /root/.ssh/
	cp /etc/ssh/${KEY_NAME}.pub /root/.ssh/
}

exec $(which enable_key)

#if [[ ! -e /etc/service/sshd/down && ! -e /etc/ssh/ssh_host_rsa_key ]] || [[ "$1" == "-f" ]]; then
#	echo "No SSH host key available. Generating one..."
#	export LC_ALL=C
#	export DEBIAN_FRONTEND=noninteractive
#	exec dpkg-reconfigure openssh-server
#fi
