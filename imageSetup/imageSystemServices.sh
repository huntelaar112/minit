#!/bin/bash
set -e
source $(which buildconfig)
set -x

buildDir="/build/"

## Install init process.
#cp /imageBuild/minit /sbin/
mkdir -p /etc/minit
mkdir -p /etc/minit_prestart
#mkdir -p /etc/my_init.pre_shutdown.d
#mkdir -p /etc/my_init.post_shutdown.d
mkdir -p /etc/container_environment
chmod 700 /etc/container_environment

touch /etc/container_environment.sh
touch /etc/container_environment.json


groupadd -g 8377 docker_env
chown :docker_env /etc/container_environment.sh /etc/container_environment.json
chmod 640 /etc/container_environment.sh /etc/container_environment.json
ln -s /etc/container_environment.sh /etc/profile.d/

## Install runit.
#$minimal_apt_get_install runit

## Install a syslog daemon and logrotate.
[ "$DISABLE_SYSLOG" -eq 0 ] && ${buildDir}/services/syslog-ng/syslog-ng.sh || true

## Install the SSH server.
[ "$DISABLE_SSH" -eq 0 ] && ${buildDir}/services/sshd/sshd.sh || true

## Install cron daemon.
[ "$DISABLE_CRON" -eq 0 ] && ${buildDir}/services/cron/cron.sh || true

## after this script
# /etc/minit
# /etc/prodfile.d (env file)
# install syslog, ssh server, cron
# install runit
#!/bin/bash
## Often used tools.
#$minimal_apt_get_install curl less vim-tiny psmisc gpg-agent dirmngr nano htop iputils-ping jq
apt-get install -y curl less vim-tiny psmisc gpg-agent dirmngr nano htop iputils-ping jq kmod 

ln -s /usr/bin/vim.tiny /usr/bin/vim
## This tool runs a command as another user and sets $HOME.
#cp /bd_build/bin/setuser /sbin/setuser
## This tool allows installation of apt packages with automatic cache cleanup.
cp ${buildDir}/imageSetup/install-clean /bin/install_clean